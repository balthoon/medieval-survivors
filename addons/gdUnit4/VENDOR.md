# Vendored package: gdUnit4

This directory is a vendored third-party addon, not project code. Do not edit it
in place; upgrade by replacing it wholesale from a tagged upstream archive and
updating this record.

| Field | Value |
|---|---|
| **Package** | gdUnit4 — Unit Testing Framework for Godot Scripts |
| **Version** | 6.2.2 (`addons/gdUnit4/plugin.cfg`) |
| **Upstream** | https://github.com/godot-gdunit-labs/gdUnit4 |
| **Release** | https://github.com/godot-gdunit-labs/gdUnit4/releases/tag/v6.2.2 |
| **Archive URL** | https://github.com/godot-gdunit-labs/gdUnit4/archive/refs/tags/v6.2.2.zip |
| **Tag commit** | `0127a55f4543dfc24746f6e5c7ba6f94105d51f2` |
| **Downloaded** | 2026-11-09 |
| **SHA-256 (archive)** | `ddb44730ffb9cd77fd70d283753450759b00c5016143d7572bf63625f64d5433` |
| **License** | MIT (Copyright (c) 2023 Mike Schulze) — see `LICENSE` |

## What was taken

The release publishes no binary asset; the official distribution for the tag is
the GitHub source archive. Only `addons/gdUnit4/` was copied from the archive
root, verbatim:

- `LICENSE`, `plugin.cfg`, `plugin.gd`, `runtest.cmd`, `runtest.sh`
- `bin/` — `GdUnitCmdTool.gd`, `GdUnitCopyLog.gd` (the headless entry point)
- `src/` — the framework

Nothing was modified. Godot 4.7.2 generated `.uid` sidecar files under `src/` and
`bin/` on first import; those are engine metadata, not upstream changes.

The addon is enabled in `project.godot` (`[editor_plugins]` →
`res://addons/gdUnit4/plugin.cfg`). Tests run headless through
`bin/GdUnitCmdTool.gd`, which does not require the editor plugin to be loaded.

## Verification performed at vendoring time

- `plugin.cfg` reports `version="6.2.2"`.
- The archive was fetched over HTTPS from `github.com` and its SHA-256 recorded
  above.
- A deliberately failing test run exited `100`; the corrected run exited `0`
  (see `docs/architecture/ADR-0001-test-framework.md`).

## Upgrading

1. Download the source archive for the new tag.
2. Replace `addons/gdUnit4/` with the archive's `addons/gdUnit4/`.
3. Update this file (version, URL, tag commit, SHA-256, date).
4. Run the project's `commands.test` and confirm exit `0`.
