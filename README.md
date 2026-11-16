# Zsh Operator Shell

A Bash bootstrap that generates an operator-oriented Zsh setup: an explicit human/minimal profile selector, contextual prompts, short command aliases, and optional CLI enhancements.

**Project status:** initial import, **not production-validated**. The original `bootstrap_shell.sh` has been committed without modification. Review [known issues](docs/KNOWN-ISSUES.md) before installation.

## What it manages

| File or setting | Purpose |
| --- | --- |
| `~/.zshrc` | Oh My Zsh loader, history configuration, profile dispatch |
| `~/.zshrc.human` | Visibility banner, `noclobber`, `umask 077`, history and ergonomics |
| `~/.zshrc.minimal` | Small profile intent; current implementation still inherits the common plugin loader |
| `~/.zsh/prompt.zsh` | Host, UID, mount namespace, Git branch, working directory and intended failure marker |
| `~/.zsh/aliases.zsh` | `g`, `k`, `d`, `ll`, `..` shortcuts |
| `~/.zsh/functions.zsh` | `fh` fuzzy history recall |
| `/etc/zsh-profile-human` | System-wide marker selecting the human profile |
| `~/.oh-my-zsh` | Downloaded loader and Git-cloned plugins, when absent |
| Git global configuration | Delta integration, when delta is installed |

## Requirements

- Bash to run bootstrap; Zsh for the target shell; Git for plugin transport.
- curl, network access and shell tooling if Oh My Zsh must be installed.
- sudo and a writable `/etc` for `--human` or `--minimal`; root provisioning requires additional administrative capabilities.
- Linux-like `/proc` and utilities for environment reporting. `fzf`, `zoxide` and `delta` are optional but their degradation is incomplete.

**No end-to-end platform is certified yet.** Termux, WSL, macOS, containers, remote/non-TTY shells and root provisioning have not been integration-tested.

## First review and smoke test

```bash
git clone https://github.com/ctalaveraw/zsh-operator-shell.git
cd zsh-operator-shell
bash -n bootstrap_shell.sh
bash tests/test_bootstrap.sh
```

These tests require no network, sudo, or real Oh My Zsh installation. They check Bash syntax, argument rejection and repeatable generated files, **not actual Zsh behavior**.

## Installation caution

Running the bootstrap **overwrites managed dotfiles**, even with no flags. It can also download/execute an unpinned upstream installer, clone moving plugin revisions, write global Git settings and change a host-wide marker. There is no dry-run or transaction/rollback mechanism.

Before running it on a real workstation, inspect the source, follow the [backup checklist](docs/OPERATIONS.md), and test inside a disposable VM/account. Thereafter, the currently implemented commands are:

```bash
bash bootstrap_shell.sh --human   # Sets shared /etc marker
# OR
bash bootstrap_shell.sh --minimal # Removes shared /etc marker
```

Do **not** use `--add-root-shell` on an important host pending review of its documented defects.

## Further reading

- [Bootstrap contract and execution order](docs/BOOTSTRAP.md)
- [Design invariants and current guarantees](docs/SHELL-INVARIANTS.md)
- [Operations and rollback](docs/OPERATIONS.md)
- [Known issues and technical debt](docs/KNOWN-ISSUES.md)

The project currently has no selected software license.
