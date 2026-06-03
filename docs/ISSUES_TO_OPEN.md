# Issues to Open

This repository snapshot does not include a configured GitHub remote, so these issues could not be opened directly from the local checkout. After pushing the branch to GitHub, create the following issues with the GitHub UI or `gh issue create`.

## roadmap: Linux/macOS support

Track the work required to validate and ship TShell on Linux and macOS.

Suggested checklist:

- Audit desktop plugin support for Linux and macOS.
- Add Linux and macOS CI build jobs.
- Validate secure storage behavior on each platform.
- Test terminal keyboard shortcuts and SFTP editor sync on each platform.
- Document platform-specific installation steps.

```sh
gh issue create --title "roadmap: Linux/macOS support" --body-file docs/issues/roadmap-linux-macos.md
```

## improve SFTP editor sync

Improve reliability when editing remote files through a local editor.

Suggested checklist:

- Detect external editor save events consistently.
- Handle conflict detection when the remote file changes during editing.
- Improve upload retry and error messages.
- Add tests around temporary file cleanup and sync state transitions.

```sh
gh issue create --title "improve SFTP editor sync" --body-file docs/issues/improve-sftp-editor-sync.md
```

## add SSH key manager

Add a first-class UI for managing SSH private keys and passphrases.

Suggested checklist:

- Import existing private keys securely.
- Generate new key pairs.
- Associate keys with host profiles.
- Store passphrases securely when users opt in.
- Provide key fingerprint display and copy actions.

```sh
gh issue create --title "add SSH key manager" --body-file docs/issues/add-ssh-key-manager.md
```

## add host import/export

Support portable host profile backup and restore.

Suggested checklist:

- Export non-secret host profile data.
- Offer explicit opt-in for exporting encrypted secrets, if supported.
- Import host lists with conflict resolution.
- Document file format and security expectations.

```sh
gh issue create --title "add host import/export" --body-file docs/issues/add-host-import-export.md
```

## add terminal theme presets

Add built-in terminal color schemes and a preset selector.

Suggested checklist:

- Define a small set of accessible presets.
- Preview foreground, background, ANSI colors, and cursor color.
- Persist per-host or global theme preferences.
- Document how presets interact with the current application theme.

```sh
gh issue create --title "add terminal theme presets" --body-file docs/issues/add-terminal-theme-presets.md
```
