#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${NIX_FLAKE_AUDIT_DISABLE:-}" ]]; then
  exit 0
fi

interval_seconds="${NIX_FLAKE_AUDIT_INTERVAL_SECONDS:-86400}"
cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/nix-flake-audit"
mkdir -p "$cache_root"

find_flake_root() {
  local dir
  dir="$(pwd -P)"

  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/flake.nix" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  return 1
}

file_mtime() {
  if stat -f '%m' "$1" >/dev/null 2>&1; then
    stat -f '%m' "$1"
  else
    stat -c '%Y' "$1"
  fi
}

current_system() {
  case "$(uname -m)-$(uname -s)" in
    x86_64-Linux)
      printf 'x86_64-linux\n'
      ;;
    aarch64-Linux|arm64-Linux)
      printf 'aarch64-linux\n'
      ;;
    x86_64-Darwin)
      printf 'x86_64-darwin\n'
      ;;
    arm64-Darwin|aarch64-Darwin)
      printf 'aarch64-darwin\n'
      ;;
    *)
      return 1
      ;;
  esac
}

home_platform() {
  case "$(uname -s)" in
    Linux)
      printf 'linux\n'
      ;;
    Darwin)
      printf 'darwin\n'
      ;;
    *)
      return 1
      ;;
  esac
}

update_command() {
  if [[ "$(uname -s)" == "Darwin" && "$HOME/nixos-config" == "$root" ]]; then
    printf '%s\n' 'sudo nix flake update --flake . && sudo darwin-rebuild switch --flake ~/nixos-config/.#macbook && NIX_FLAKE_AUDIT_INTERVAL_SECONDS=0 nix-flake-audit'
    return 0
  fi

  printf '%s\n' 'nix flake update --flake . && NIX_FLAKE_AUDIT_INTERVAL_SECONDS=0 nix-flake-audit'
}

resolve_target() {
  local root user system platform candidate store_path
  root="$1"
  user="$(id -un)"
  system="$(current_system || true)"
  platform="$(home_platform || true)"

  local candidates=()
  if [[ -n "$platform" ]]; then
    candidates+=(".#homeConfigurations.\"${user}-${platform}\".activationPackage.outPath")
  fi
  if [[ -n "$system" ]]; then
    candidates+=(".#packages.${system}.default.outPath")
    candidates+=(".#defaultPackage.${system}.outPath")
  fi

  for candidate in "${candidates[@]}"; do
    store_path="$(
      cd "$root" &&
      nix eval --raw --no-write-lock-file "$candidate" 2>/dev/null
    )" || continue

    if [[ -n "$store_path" ]]; then
      printf '%s\n%s\n' "$candidate" "$store_path"
      return 0
    fi
  done

  return 1
}

root="$(find_flake_root || true)"
if [[ -z "$root" ]]; then
  exit 0
fi

cache_key="$(printf '%s' "$root" | cksum | awk '{print $1}')"
summary_file="$cache_root/$cache_key.summary"
stamp_file="$cache_root/$cache_key.stamp"
report_file="$cache_root/$cache_key.vulnix.txt"

now="$(date +%s)"
if [[ -f "$stamp_file" && -f "$summary_file" ]]; then
  last_run="$(cat "$stamp_file")"
  if [[ "$last_run" =~ ^[0-9]+$ ]] && (( now - last_run < interval_seconds )); then
    printf '[nix-audit] using cached result for %s\n' "$root"
    cat "$summary_file"
    exit 0
  fi
fi

printf '[nix-audit] scanning %s\n' "$root"

tmp_summary="$(mktemp)"
tmp_report="$(mktemp)"
had_output=0

add_line() {
  printf '%s\n' "$1" >> "$tmp_summary"
  had_output=1
}

lock_file="$root/flake.lock"
if [[ ! -f "$lock_file" ]]; then
  add_line "[nix-audit] $root"
  add_line "warn: flake.lock is missing; flake inputs are not pinned."
else
  lock_age_seconds=$(( now - $(file_mtime "$lock_file") ))
  lock_age_days=$(( lock_age_seconds / 86400 ))
  if (( lock_age_days > 30 )); then
    add_line "[nix-audit] $root"
    add_line "warn: flake.lock is ${lock_age_days} days old."
  fi

  nixpkgs_revs="$(
    jq -r '
      .nodes
      | to_entries[]
      | select(.value.locked.owner? == "NixOS" and .value.locked.repo? == "nixpkgs" and .value.locked.rev?)
      | .value.locked.rev
    ' "$lock_file" | sort -u
  )"

  if [[ -n "$nixpkgs_revs" ]]; then
    rev_count="$(printf '%s\n' "$nixpkgs_revs" | sed '/^$/d' | wc -l | tr -d ' ')"
    if (( rev_count > 1 )); then
      short_revs="$(
        printf '%s\n' "$nixpkgs_revs" |
          sed 's/^\(........\).*/\1/' |
          awk 'BEGIN { sep = "" } { printf "%s%s", sep, $0; sep = ", " } END { print "" }'
      )"
      if (( had_output == 0 )); then
        add_line "[nix-audit] $root"
      fi
      add_line "warn: flake.lock contains ${rev_count} nixpkgs revisions: ${short_revs}."
      add_line "hint: align dependent inputs with \`inputs.<name>.inputs.nixpkgs.follows = \"nixpkgs\";\`."
    fi
  fi
fi

if command -v vulnix >/dev/null 2>&1; then
  target_info="$(resolve_target "$root" || true)"
  if [[ -n "$target_info" ]]; then
    installable="$(printf '%s\n' "$target_info" | sed -n '1p')"
    store_path="$(printf '%s\n' "$target_info" | sed -n '2p')"

    if vulnix "$store_path" > "$tmp_report" 2>/dev/null; then
      :
    fi

    first_line="$(sed -n '1p' "$tmp_report")"
    finding_count="${first_line%% *}"

    if [[ "$finding_count" =~ ^[0-9]+$ ]] && (( finding_count > 0 )); then
      if (( had_output == 0 )); then
        add_line "[nix-audit] $root"
      fi
      add_line "cve: ${finding_count} derivations with active advisories for ${installable}."
      add_line "see: ${report_file}"
      mv "$tmp_report" "$report_file"
      tmp_report=""
    else
      rm -f "$report_file"
    fi
  fi
fi

if (( had_output == 1 )); then
  add_line "update: run $(update_command)"
fi

printf '%s\n' "$now" > "$stamp_file"
if (( had_output == 0 )); then
  printf '%s\n' "[nix-audit] audit complete - flake is clean" > "$summary_file"
else
  mv "$tmp_summary" "$summary_file"
fi

if [[ -n "${tmp_report:-}" ]]; then
  rm -f "$tmp_report"
fi
rm -f "$tmp_summary"

cat "$summary_file"
