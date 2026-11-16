# Operator runbook

The current bootstrap has no dry-run or rollback mode. Start in a disposable Linux VM or throwaway user account, not an existing workstation.

## Preflight and backup

1. Inspect `bootstrap_shell.sh` and [known issues](KNOWN-ISSUES.md). Do not pipe remote installers into the shell as a shortcut to reviewing this repository.
2. Verify tools needed for the path you will use: `bash`, `zsh`, `git`, `curl`, Linux utilities, and `sudo` for the explicit profile flags.
3. Run `bash -n bootstrap_shell.sh` and `bash tests/test_bootstrap.sh`. Neither is a Zsh integration test.
4. Record prior Git configuration. If delta is present, the bootstrap will overwrite these entries:

   ```bash
   for key in core.pager interactive.diffFilter delta.navigate delta.side-by-side; do
     printf '%s = ' "$key"
     git config --global --get "$key" || echo '<not set>'
   done
   ```

5. Back up the specific managed paths, with permissions preserved:

   ```bash
   backup="$HOME/shell-backup-$(date +%Y%m%d-%H%M%S)"
   mkdir -m 700 -p "$backup"
   for name in .zshrc .zshrc.human .zshrc.minimal .zsh .oh-my-zsh; do
     if [[ -e "$HOME/$name" ]]; then
       cp -a -- "$HOME/$name" "$backup/"
     fi
   done
   printf 'Backup directory: %s\n' "$backup"
   ```

   Record whether `/etc/zsh-profile-human` existed **before** installation. For possible root provisioning, separately record the root login shell, back up root's files with proper privileges, and identify any existing plugin trees.

## Apply on a disposable host

```bash
bash bootstrap_shell.sh --human
# OR:
bash bootstrap_shell.sh --minimal
```

Both flags change a **system-wide** marker using sudo. Running with no flags still generates files and can alter Git configuration. Never compensate for missing permissions with `sudo bash bootstrap_shell.sh`; it may target root's HOME and produce incorrect ownership. Avoid `--add-root-shell` until its documented defects are corrected.

## Verify

Start a fresh Zsh instance in the intended user context and inspect startup output, prompt, effective UID, history, aliases and intended options. In human mode, inspect `setopt` for `noclobber`, check `umask`, and use `fh` only if fzf exists. In minimal mode, check for literal prompt substitutions; the current minimal prompt has known defects.

```bash
command -v zsh git
ls -l "$HOME/.zshrc" "$HOME/.zshrc.human" "$HOME/.zshrc.minimal"
if [[ -e /etc/zsh-profile-human ]]; then
  echo 'host marker: human'
else
  echo 'host marker: minimal'
fi
git config --global --get core.pager || true
```

A successful completion message does not prove root, Git and plugin state are correct.

## Diagnose

| Symptom | Check |
| --- | --- |
| Installer failure | curl availability, TLS/DNS and Oh My Zsh directory state |
| Plugin not loaded | clone path and the actual `ZSH_CUSTOM` used at shell startup |
| Broken minimal prompt | unloaded functions and missing prompt substitution |
| History helper fails | `fzf` on PATH; inspect the `fh` implementation |
| Unexpected Git pager | global Git config (especially `core.pager`) |
| Container shown as host | mount-namespace check is not a host/container classifier |
| Root fallback missing | root provisioning never copies `.zshrc.minimal` |

## Manual rollback

There is no transactional rollback. Stop opening new shells, then **restore the recorded prior state**, not a guessed default. For an existing backed-up dotfile:

```bash
cp -a -- "$backup/.zshrc" "$HOME/.zshrc"
```

Restore other backed-up items similarly. Only delete newly created files or plugin trees if records prove they were absent previously **and** they contain no subsequent work. Restore Git keys to the values recorded in preflight; only unset keys that were previously absent. Reconcile the `/etc` marker to its original existence state with an authorized administrator. If root provisioning ran, independently restore root's recorded login shell and dotfiles. Do not assume the preexisting root shell was Bash.

**Do not run another bootstrap as a rollback attempt.** The same destructive writes will repeat.
