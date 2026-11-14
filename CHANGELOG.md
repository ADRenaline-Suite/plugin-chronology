# Changelog

## [Unreleased]

### Added

- One agent, `plugin-chronology`. It follows this plugin's skills and names when to ask another plugin. The method stays in the skill.

## [0.0.1] - 2026-11-07

### Changed

- The chat stays on the request. The note is written by the `afterAgentThought` hook from a block in thinking, and an edit in the chronology folder is refused so the conversation does not show that diff.
- The line `ADRenaline chronology: updated <NNN>` is printed only when that `<NNN>` already belongs to this window's note file. A missing file prints `ADRenaline chronology: missing note.` and the next number is not chosen.
- `stop` writes one `partial` note when the window changed a file and the thought brought no block. A later block in that window replaces it. `stop` still sends no follow-up.

### Added

- One chronology note per chat window in `adrenaline/chronology/<person>/`. The number restarts in that person's folder. The window id stays inside the file.
- A later section in the same window is appended to that file, at most twice per UTC day.
- `/chronology-note` writes or updates that file. Cursor also writes it at the end of a turn that changed the project or reached a result, without a command.
- Cursor hooks pass the window id, remember a file edit, ask once when the note is missing, and stamp `Closed:` when the window ends. Claude Code receives the window id on `SessionStart`. The close stamp stays in Cursor.
