# dotfiles/git-lb.sh
#!/usr/bin/env bash
set -euo pipefail

branch=$(
  git reflog --pretty='%gs' \
    | sed -nE \
        -e "s/^checkout: moving from .* to (.+)$/\1/p" \
        -e "s/^switch: (.+) -> (.+)$/\2/p" \
        -e "s/^switch: created branch '(.+)'$/\1/p" \
    | awk '!seen[$0]++' \
    | head -n 10 \
    | fzf
)

[ -n "$branch" ] && git switch "$branch"
