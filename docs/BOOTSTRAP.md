# Bootstrap reference

This describes the imported `bootstrap_shell.sh` implementation, not a proposed design.

## CLI

```text
bash bootstrap_shell.sh [--human | --minimal] [--add-root-shell]
```

| Arguments | Result |
| --- | --- |
| none | Still performs setup and overwrites generated files; chooses the profile already indicated by the marker |
| `--human` | Uses `sudo touch /etc/zsh-profile-human` |
| `--minimal` | Uses `sudo rm -f /etc/zsh-profile-human` |
| `--human --add-root-shell` | Also provisions root login shell and root configuration |
| `--human --minimal` | Rejected before setup |
| `--add-root-shell` alone | Rejected before setup |
| Unknown flag | Rejected before setup |

There is no `--help`, dry-run, uninstall or per-user selector.

## Execution order

1. Validate flags and require `zsh` and `git`. Warn for missing `fzf`, `zoxide` or `delta`.
2. If missing, install Oh My Zsh by downloading the current upstream script with `curl` and executing via `sh`.
3. Clone autosuggestions and syntax highlighting into `$ZSH_CUSTOM/plugins` when missing.
4. If delta exists, change four global Git values (`core.pager`, `interactive.diffFilter`, `delta.navigate`, `delta.side-by-side`).
5. Overwrite `~/.zshrc`, both profiles and the three files under `~/.zsh`.
6. Change `/etc/zsh-profile-human` if a profile flag was specified.
7. If requested, use elevated commands to alter root's login shell and files.
8. Print success if no step failed. A failure may leave partially applied state.

## Loading and semantics

`~/.zshrc` always sources Oh My Zsh with plugins `git`, `fzf`, `zsh-autosuggestions` and `zsh-syntax-highlighting` **before** selecting a profile. Common history size is 50,000; minimal overrides it to 10,000. The human profile enables `noclobber`, `umask 077`, Emacs key bindings, history options, zoxide initialization (if present), aliases/functions/prompt.

In human mode the prompt queries the hostname, effective UID, namespace symlinks and current Git branch. The trailing asterisk after the Git branch is unconditional, **not** a dirty-worktree check. A mount namespace different from PID 1's is labeled `[ns]`; equality does **not** establish physical-host identity.

In minimal mode the prompt refers to `host_prompt` and `cwd_prompt`, but the module that defines them is not sourced. The minimal profile also does not explicitly enable prompt substitution. These are implementation defects, not expected behavior.

## Persistence and ownership

The script deterministically rewrites the named dotfiles, but it does **not** manage unrelated files under `~/.zsh`, reconcile previously cloned repositories, record original Git values, stage atomic changes or roll back on error. `/etc/zsh-profile-human` is a **host-wide** selector, not a per-user preference. The root provisioning path is a separate, incomplete state tree.

Re-running with identical input can reproduce generated file contents; this must not be confused with full convergence of the host state. See [invariants](SHELL-INVARIANTS.md) and [known issues](KNOWN-ISSUES.md).
