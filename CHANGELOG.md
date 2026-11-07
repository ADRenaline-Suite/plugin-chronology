# Changelog

## [0.0.1] - 2026-11-07

### Added

- One chronology note per chat window in `adrenaline/chronology/<person>/`. The number restarts in that person's folder. The window id stays inside the file.
- A later section in the same window is appended to that file, at most twice per UTC day.
- `/chronology-note` writes or updates that file. Cursor also writes it at the end of a turn that changed the project or reached a result, without a command.
- Cursor hooks pass the window id, remember a file edit, ask once when the note is missing, and stamp `Closed:` when the window ends. Claude Code receives the window id on `SessionStart`. The close stamp stays in Cursor.
