#!/usr/bin/env bash
#
# Shell Bootstrap
#
# This script converges an operator-facing shell environment into a
# known, predictable state. It is governed by the invariants defined in
# SHELL-INVARIANTS.md and documented in BOOTSTRAP.md.
#
# The script is:
# - convergent (corrects drift)
# - idempotent (safe to re-run)
# - explicit (no heuristics)
# - bounded in scope
#
# It intentionally avoids:
# - automatic package installation
# - distro-specific logic
# - plugin managers
# - implicit persistence
#

set -euo pipefail

LOG="[shell-bootstrap]"
info()  { echo "$LOG INFO: $*"; }
warn()  { echo "$LOG WARN: $*" >&2; }
fatal() { echo "$LOG ERROR: $*" >&2; exit 1; }

# -----------------------------
# Argument parsing
# -----------------------------
#
# Profile selection is host-scoped and explicit.
# See BOOTSTRAP.md for rationale.
#

HUMAN_MODE=false
MINIMAL_MODE=false
ADD_ROOT_SHELL=false

for arg in "$@"; do
  case "$arg" in
    --human)   HUMAN_MODE=true ;;
    --minimal) MINIMAL_MODE=true ;;
    --add-root-shell) ADD_ROOT_SHELL=true ;;
    *) fatal "Unknown argument: $arg" ;;
  esac
done

if [[ "$HUMAN_MODE" == "true" && "$MINIMAL_MODE" == "true" ]]; then
  fatal "Cannot specify --human and --minimal together"
fi

if [[ "$ADD_ROOT_SHELL" == "true" && "$HUMAN_MODE" != "true" ]]; then
  fatal "--add-root-shell requires --human"
fi

info "Starting shell bootstrap (convergent)"

# -----------------------------
# Preconditions
# -----------------------------
#
# We require only:
# - zsh (shell runtime)
# - git (plugin transport)
#
# All other tools are optional and degrade gracefully.
#

command -v zsh >/dev/null || fatal "zsh not found"
command -v git >/dev/null || fatal "git not found"

OPTIONAL=(fzf zoxide delta)
MISSING=()

for bin in "${OPTIONAL[@]}"; do
  command -v "$bin" >/dev/null || MISSING+=("$bin")
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  warn "Optional tools not found (functionality will degrade): ${MISSING[*]}"
fi

# -----------------------------
# oh-my-zsh (plugin loader only)
# -----------------------------
#
# oh-my-zsh is used strictly as a loader for known plugins.
# No themes or dynamic behavior are enabled.
#

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing oh-my-zsh"
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  info "oh-my-zsh present"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_plugin() {
  local name="$1" repo="$2"
  local dir="$ZSH_CUSTOM/plugins/$name"

  if [[ ! -d "$dir" ]]; then
    info "Cloning plugin: $name"
    git clone --depth=1 "$repo" "$dir"
  fi
}

clone_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# -----------------------------
# Git integration (optional)
# -----------------------------
#
# Git behavior must remain correct without enhancement.
# Enhancements apply only if the tool is present.
#

if command -v delta >/dev/null; then
  git config --global core.pager delta
  git config --global interactive.diffFilter 'delta --color-only'
  git config --global delta.navigate true
  git config --global delta.side-by-side false
fi

# -----------------------------
# Shell configuration files
# -----------------------------
#
# Files in ~/.zsh and ~/.zshrc* are owned by this bootstrap
# and are overwritten deterministically.
#

mkdir -p "$HOME/.zsh"

# Minimal profile (safe everywhere)
cat > "$HOME/.zshrc.minimal" <<'EOF'
# Minimal zsh profile
# No plugins, no color, no external dependencies

# Helper functions (definitions only)

__init_authority() {
  ps -p 1 -o comm= 2>/dev/null
}

__mount_context() {
  local self_ns pid1_ns

  self_ns=$(readlink /proc/self/ns/mnt 2>/dev/null) || {
    echo "indeterminate (kernel interface unavailable)"
    return
  }

  pid1_ns=$(readlink /proc/1/ns/mnt 2>/dev/null) || {
    echo "indeterminate (PID 1 namespace inaccessible)"
    return
  }

  if [[ "$self_ns" != "$pid1_ns" ]]; then
    echo "isolated (namespace)"
  else
    echo "host"
  fi
}

__interaction_context() {
  tty >/dev/null 2>&1 || echo "non-tty (job control limited)"
}

# Behavioral logic (conditional execution)

if [[ -o interactive ]]; then
  {

    # Privilege boundary disclosure (descriptive only)

    if [[ "$EUID" -eq 0 && "$UID" -ne 0 ]]; then
      print "boundary notice:"
      print "  authority transition: non-root → root"
      print "  note                : root shell entered via privilege escalation"
      print "  note                : shell invariants preserved; authority changed"
      print
    fi

    local host
    host=$(uname -n 2>/dev/null) || return

    # Interaction context disclosure (descriptive only)

    interaction="$(__interaction_context)"
    if [[ -n "$interaction" ]]; then
      print "interaction     : $interaction"
      print
    fi

    print "shell context:"
    print "  hostname       : ${host}"
    print "  host identity  : kernel (uname)"
    print "  profile intent : none (minimal profile active)"
    print "  mount context  : $(__mount_context)"
    print "  init authority : $(__init_authority) (PID 1)"
    print
  } 2>/dev/null
fi

HISTSIZE=10000
SAVEHIST=10000
setopt inc_append_history
setopt hist_ignore_dups

PROMPT='$(host_prompt)$(cwd_prompt) ❯ '
EOF

# Human profile (ergonomics + safety)
cat > "$HOME/.zshrc.human" <<'EOF'
# Human zsh profile
# Ergonomics and safety enhancements without altering semantics

# Helper functions (definitions only)

__init_authority() {
  ps -p 1 -o comm= 2>/dev/null
}

__mount_context() {
  local self_ns pid1_ns

  self_ns=$(readlink /proc/self/ns/mnt 2>/dev/null) || {
    echo "indeterminate (kernel interface unavailable)"
    return
  }

  pid1_ns=$(readlink /proc/1/ns/mnt 2>/dev/null) || {
    echo "indeterminate (PID 1 namespace inaccessible)"
    return
  }

  if [[ "$self_ns" != "$pid1_ns" ]]; then
    echo "isolated (namespace)"
  else
    echo "host"
  fi
}

__interaction_context() {
  tty >/dev/null 2>&1 || echo "non-tty (job control limited)"
}

# Behavioral logic (conditional execution)

if [[ -o interactive ]]; then
  {

    # Privilege boundary disclosure (descriptive only)
    if [[ "$EUID" -eq 0 && "$UID" -ne 0 ]]; then
      print "boundary notice:"
      print "  authority transition: non-root → root"
      print "  note                : root shell entered via privilege escalation"
      print "  note                : shell invariants preserved; authority changed"
      print
    fi

    local host
    host=$(uname -n 2>/dev/null) || return

    # Interaction context disclosure (descriptive only)

    interaction="$(__interaction_context)"
    if [[ -n "$interaction" ]]; then
      print "interaction     : $interaction"
      print
    fi

    print "shell context:"
    print "  hostname       : ${host}"
    print "  host identity  : kernel (uname)"
    print "  profile intent : /etc/zsh-profile-human"
    print "  mount context  : $(__mount_context)"
    print "  init authority : $(__init_authority) (PID 1)"
    print "  note           : userland intent not validated against kernel state"
    print
  } 2>/dev/null
fi

# Safety invariants
setopt noclobber
bindkey -e
stty stop undef 2>/dev/null || true
umask 077

# History as recall engine
setopt extended_history
setopt hist_ignore_space

# Optional ergonomics
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Source shared components
source ~/.zsh/aliases.zsh
source ~/.zsh/functions.zsh
source ~/.zsh/prompt.zsh
EOF

# Base zshrc (profile selection)
cat > "$HOME/.zshrc" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

HISTSIZE=50000
SAVEHIST=50000
setopt inc_append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_reduce_blanks

if [[ -f /etc/zsh-profile-human ]]; then
  source ~/.zshrc.human
else
  source ~/.zshrc.minimal
fi
EOF

# Prompt (risk-aware, constant-time)
cat > "$HOME/.zsh/prompt.zsh" <<'EOF'
# ~/.zsh/prompt.zsh
# Risk-aware, operator-grade prompt
# Safe under nested shells, SSH, and non-interactive sourcing

[[ -n "$ZSH_VERSION" ]] || return

autoload -Uz colors && colors
setopt prompt_subst

# -----------------------------
# Git context (cheap, optional)
# -----------------------------
git_prompt() {
  local b
  b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
  echo " %F{yellow}${b}*%f"
}

# -----------------------------
# Namespace divergence detection
# -----------------------------
namespace_marker() {
  local self_ns pid1_ns
  self_ns=$(readlink /proc/self/ns/mnt 2>/dev/null) || return
  pid1_ns=$(readlink /proc/1/ns/mnt 2>/dev/null) || return

  [[ "$self_ns" != "$pid1_ns" ]] && echo "[ns] "
}

# -----------------------------
# Host identity + authority (continuous safety signal)
# -----------------------------
host_prompt() {
  local host ns authority
  host=$(uname -n 2>/dev/null) || return
  ns=$(namespace_marker)

  if [[ "$EUID" -eq 0 ]]; then
    authority="#"
  else
    authority="$"
  fi

  if [[ -f /etc/zsh-profile-human ]]; then
    echo "%F{red}${host}%f ${ns}${authority} "
  else
    echo "${host} ${ns}${authority} "
  fi
}

# -----------------------------
# Exit status (failure visibility)
# -----------------------------
status_prompt() {
  [[ $? -ne 0 ]] && echo "%F{red}✗ %f"
}

# -----------------------------
# Working directory (danger signal)
# -----------------------------
cwd_prompt() {
  if [[ "$PWD" == "/" ]]; then
    echo "%F{red}/%f"
  else
    echo "%F{cyan}%~%f"
  fi
}

# -----------------------------
# Final prompt
# -----------------------------
PROMPT='$(status_prompt)$(host_prompt)$(cwd_prompt)$(git_prompt) ❯ '
EOF

# Aliases (keystroke reduction only)
cat > "$HOME/.zsh/aliases.zsh" <<'EOF'
alias g=git
alias k=kubectl
alias d=docker
alias ll="ls -lah"
alias ..="cd .."
EOF

# Functions (workflow helpers)
cat > "$HOME/.zsh/functions.zsh" <<'EOF'
# History recall (fzf-powered if available)
fh() {
  print -z "$(history | fzf | sed 's/^[ 0-9]*//')"
}
EOF

# -----------------------------
# Host intent marker
# -----------------------------
#
# Presence of /etc/zsh-profile-human determines profile.
#

if [[ "$HUMAN_MODE" == "true" ]]; then
  sudo touch /etc/zsh-profile-human
elif [[ "$MINIMAL_MODE" == "true" ]]; then
  sudo rm -f /etc/zsh-profile-human
fi

# -----------------------------
# Optional root shell provisioning
# -----------------------------

if [[ "$ADD_ROOT_SHELL" == "true" ]]; then
  info "Provisioning root shell (explicit operator request)"

  ZSH_BIN="$(command -v zsh)"

  if [[ -z "$ZSH_BIN" ]]; then
    fatal "Cannot provision root shell: zsh not found"
  fi

  if sudo chsh -s "$ZSH_BIN" root; then
    info "Root login shell set to zsh"
  else
    fatal "Failed to set root login shell"
  fi

  info "Ensuring oh-my-zsh is present for root"

  if ! sudo test -d /root/.oh-my-zsh; then
    sudo RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      >/dev/null
    info "oh-my-zsh installed for root"
  else
    info "oh-my-zsh already present for root"
  fi

  info "Installing oh-my-zsh plugins for root"
  sudo cp -r "$HOME/.oh-my-zsh/custom" /root/.oh-my-zsh/

  info "Installing shell configuration for root"
  sudo mkdir -p /root/.zsh
  sudo cp -r "$HOME/.zsh" /root/
  sudo cp "$HOME/.zshrc" /root/.zshrc
  sudo cp "$HOME/.zshrc.human" /root/.zshrc.human

  info "Root shell provisioned (explicit, persistent)"
fi

info "Shell bootstrap converged"