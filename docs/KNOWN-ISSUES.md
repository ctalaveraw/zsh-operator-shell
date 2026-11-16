# Known issues and technical debt

**Assessment method:** static review of the uploaded script, Bash syntax validation, and isolated no-network output smoke testing. Interactive Zsh, real privilege paths, network installation and non-Linux targets remain untested. Priorities reflect operational risk, not a vulnerability rating.

| Priority | Issue | Impact and recommended correction |
| --- | --- | --- |
| High | Unprotected dotfile overwrites | Every run truncates the managed files without preserving prior values. Add preview, atomic writes and restorable backups. |
| High | Unpinned installer and plugins | Downloads and executes upstream Oh My Zsh at runtime; clones moving plugin heads. Pin versions and verify provenance. |
| High | Broken minimal profile | Base config loads plugins before profile selection; minimal prompt calls `host_prompt`/`cwd_prompt` without sourcing definitions or enabling prompt substitution. Make it standalone. |
| High | Incomplete root copy | Root provisioning does not copy `~/.zshrc.minimal`; removing the shared marker afterward leaves a root profile missing. |
| High | Incorrect root custom-folder copy | Copying `~/.oh-my-zsh/custom` recursively into `/root/.oh-my-zsh/` can nest `custom/custom` if the destination already exists. Copy precise subpaths. |
| Medium | Global marker despite host-scoped wording | `/etc/zsh-profile-human` impacts all users using this config, not just the invoker. Separate user preference from administrator policy. |
| Medium | Optional fzf not optional for `fh` | Missing fzf is warned about, but the helper still invokes it. Guard it or offer a non-fzf fallback. |
| Medium | Misleading Git dirty indicator | `git_prompt` always appends an asterisk, including in clean repositories. Query true dirty status or use a neutral separator. |
| Medium | Misleading privilege-transition banner | The `UID`/`EUID` comparison cannot reliably identify the provenance of an elevated session. Report current credentials only. |
| Medium | Namespace label overclaims | Equality with PID 1's mount namespace does not prove host identity and can occur inside a container. Use “same as PID 1” / “different” / “unknown.” |
| Medium | Persistent Git mutation | Delta settings are installed globally if delta exists, never restored if it disappears. Preserve prior state and make opt-in. |
| Medium | Partial failures | No transaction, staging or rollback; the bootstrap can stop halfway through. Add phases, verification and failure recovery. |
| Low | Banner verbosity and external calls | Context commands run on interactive startups; may be noisy over SSH and in nested shells. |
| Low | No `--help` or dry-run | Operator cannot inspect or validate changes before they occur. |
| Low | Incomplete runtime tests | Current smoke test only checks Bash parsing and generated output. Add Zsh, root, Linux distro and target-environment integration tests. |

## Additional factual discrepancies

- `curl` is necessary for first-time Oh My Zsh installation but is not included in the executable preflight.
- `setopt noclobber` prevents accidental `>` overwrite in human Zsh; `>|` remains an intentional override.
- The opening comments say the script avoids plugin managers and implicit persistence, but it installs Oh My Zsh/plugins and permanently writes dotfiles and Git settings.
- `stty stop undef`, `ps -p 1 -o comm=`, `/proc` namespace symlinks, `sudo` and `chsh` all assume specific host facilities.
- The prompt is advertised as constant-time, but `git rev-parse` is invoked on each render; no performance bounds were measured.

**Do not promote the script as safe for unattended fleet deployment until the high-priority behaviors are fixed and covered by runtime tests.**
