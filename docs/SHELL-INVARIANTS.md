# Operator shell invariants

The bootstrap header states the intended contract: convergence, idempotence, explicit operation and bounded scope. This page distinguishes those goals from guarantees demonstrated by the current implementation. **It is not a security certification.**

| ID | Intended property | Current assessment | Basis |
| --- | --- | --- | --- |
| INV-01 | Explicit profile selection | Partial | Flags mutate a host-wide marker; no-flags inherits previous state |
| INV-02 | Reproducible, idempotent setup | Partial | Here-doc output is repeatable; plugin revisions, Git settings and failure handling are not fully reconciled |
| INV-03 | Dependency-free minimal shell | Not met | Shared Zsh loader still loads Oh My Zsh and its plugins |
| INV-04 | Optional features degrade safely | Partial | Missing optional dependencies are logged, yet `fh` calls `fzf` unconditionally |
| INV-05 | Authority context is visible | Partial | Prompt exposes `EUID`; startup `UID` comparison does not establish sudo/su provenance |
| INV-06 | Host and namespace reporting is factual | Limited | Mount-namespace comparison is informative, not proof of host isolation |
| INV-07 | Prompt state is accurate | Not met | Git asterisk is unconditional; minimal prompt references unloaded helpers |
| INV-08 | Privileged changes are explicit | Partial | Root path requires a flag, but profile selection alters global `/etc` state |
| INV-09 | Changes are bounded and reversible | Not met | Existing dotfiles and Git global settings can be overwritten without backup |
| INV-10 | Dependency inputs are reproducible | Not met | Upstream install script and plugins are not pinned |

## Definitions

**Profile intent** is the operator's declared preference, not a detection of the machine type. **Authority** is the effective credential state of the current process, not evidence of how that state was obtained. **Mount context** compares `/proc/self/ns/mnt` with `/proc/1/ns/mnt` and may be different, equal or indeterminate. Equality is not proof of a physical host.

**Convergence** requires reconciliation of the entire owned state, including stale data and incomplete operations. Current repeatability is limited to deterministic generation of a few files under unchanged inputs.

## Acceptance criteria for future work

1. Minimal mode starts and renders a usable prompt without Oh My Zsh or optional commands.
2. Every optional integration is guarded or has a documented fallback.
3. Prompt Git state and prior-command status are accurate and bounded in runtime.
4. The operator can preview changes, preserve existing files and roll back from recorded state.
5. Default execution makes no privileged changes; privileged scopes are individually opt-in.
6. Repeated runs and partial failures are tested as full-state transitions.
7. Unavailable environment probes show *unknown* rather than making false isolation claims.
8. Installer/plugin revisions are pinned or independently verified.

Changes to an invariant require corresponding code, tests and docs. Do not upgrade a partial/not-met row to met without executable evidence.
