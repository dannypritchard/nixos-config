autoload -Uz add-zsh-hook

_nix_flake_audit_find_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/flake.nix" ]]; then
      print -r -- "$dir"
      return 0
    fi
    dir="${dir:h}"
  done
  return 1
}

_nix_flake_audit_maybe_run() {
  local root

  [[ -n "${NIX_FLAKE_AUDIT_DISABLE:-}" ]] && return 0
  command -v nix-flake-audit >/dev/null 2>&1 || return 0

  root="$(_nix_flake_audit_find_root)" || {
    unset _NIX_FLAKE_AUDIT_ROOT
    return 0
  }

  [[ "${_NIX_FLAKE_AUDIT_ROOT:-}" == "$root" ]] && return 0
  _NIX_FLAKE_AUDIT_ROOT="$root"
  nix-flake-audit
}

add-zsh-hook chpwd _nix_flake_audit_maybe_run
_nix_flake_audit_maybe_run
