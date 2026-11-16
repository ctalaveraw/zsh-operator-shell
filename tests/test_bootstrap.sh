#!/usr/bin/env bash
# Offline smoke test. It does not exercise Zsh, network, sudo, or root provisioning.
set -euo pipefail

repo="$(cd -- "$(dirname -- "$0")/.." && pwd)"
script="$repo/bootstrap_shell.sh"
bash -n "$script"

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home"
export GIT_CONFIG_GLOBAL="$tmp/gitconfig"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
mkdir -p "$tmp/bin"
printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/zsh"
chmod +x "$tmp/bin/zsh"
export PATH="$tmp/bin:/usr/bin:/bin"

reject() {
  if bash "$script" "$@" >"$tmp/rejected.log" 2>&1; then
    printf 'ERROR: invalid flags accepted: %s\n' "$*" >&2
    exit 1
  fi
}

reject --unknown
reject --human --minimal
reject --add-root-shell

bash "$script" >"$tmp/first.log" 2>&1
files=( .zshrc .zshrc.human .zshrc.minimal .zsh/prompt.zsh .zsh/aliases.zsh .zsh/functions.zsh )
for file in "${files[@]}"; do
  [[ -s "$HOME/$file" ]] || {
    printf 'ERROR: missing/empty generated file: %s\n' "$file" >&2
    exit 1
  }
done

fingerprint() {
  for file in "${files[@]}"; do
    sha256sum "$HOME/$file"
  done
}
before="$(fingerprint)"
bash "$script" >"$tmp/second.log" 2>&1
after="$(fingerprint)"
[[ "$before" == "$after" ]] || {
  echo 'ERROR: generated output differs on second run' >&2
  exit 1
}

echo 'PASS: syntax, rejected flags, deterministic generated files'
