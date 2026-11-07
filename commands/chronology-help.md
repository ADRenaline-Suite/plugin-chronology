---
name: chronology-help
description: "ADRenaline. Help: catalog of plugin-chronology (skills, rules, commands)."
---

# Help — ADRenaline Chronology

Print this catalog as the reply. Do not run any skill or command. Do not invent entries that are not listed. If a component was added to the plugin and is missing here, add one line from its frontmatter `description` and say the catalog was refreshed.

When this help command is the first command in the message, every command, skill, or rule named after it is the subject of the help. Do not run those names. Do not print the full catalog. For each name, in the order given, print its catalog line (the linked id and the sentence). When the README has a heading for that command, also print the paragraphs under that heading, up to the next heading. A skill name uses the skill's catalog line and the README group that names that skill, up to its first command heading. A name that is not in this catalog is one line: it is not in this plugin. Do not invent what it does, and do not write a file.

Write the sentences in the language of the request. Keep command names, file ids, and every URL unchanged. Every id is a markdown link to the GitHub URL on its line. Do not print a repository `name` as the visible label of a plugin.

Keep the section headings, in this order: Plugin, Commands, Skills, Rules, then Agents, Hooks, and MCP when the plugin has them, then Output, then Not in this plugin. The title and the Plugin line show `ADRenaline` plus the `displayName`, then one sentence on what the plugin does. Under Commands, group the lines by the skill named in the line. Each group opens with that skill name linked to its SKILL.md. One line per item: the linked id, then the sentence. Output links this plugin's GitHub repository under that same label. A plugin under Not in this plugin uses `ADRenaline` plus its short name, and links to `https://github.com/<owner>/<other-plugin>` only when that repository exists.

## Plugin

- [**ADRenaline Chronology**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/README.md) — Writes one paragraph per chat window about what was tried in this project and whether it worked.

## Commands

- [**/chronology-help**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/README.md) — This help (one-line catalog of the plugin).
- [**/chronology-note**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/skills/record-chronology/references/note.md) — Chronology note (skill record-chronology): what this chat window tried in this project and whether it worked, one file per window.

## Skills

- [**record-chronology**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/skills/record-chronology/SKILL.md) — Writes one paragraph per chat window about what was tried in this project and whether it worked. Use it at the end of a turn that changed the project or reached a result, without waiting to be asked, and when someone asks for the chronology note.

## Rules

- [**output-folder**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/rules/output-folder.mdc) — Every file goes in `adrenaline/chronology/` (or in `outputDirs["plugin-chronology"]` of `.cursor/adrenaline.json`). One file per window lives in the person's folder, and that folder has its own number.
- [**chronology-note**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/rules/chronology-note.mdc) — The note is written in the same turn when work landed or a result was reached, without waiting to be asked.

## Hooks

- [**sessionStart**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/hooks/cursor-hooks.json) — Cursor: gives the agent the window id and the person folder from `git user.name`.
- [**afterFileEdit**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/hooks/cursor-hooks.json) — Cursor: remembers that this window edited a file outside the chronology folder. The memory stays on this machine.
- [**stop**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/hooks/cursor-hooks.json) — Cursor: one follow-up when that edit has no note yet. It stays quiet when the note is already there.
- [**sessionEnd**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/hooks/cursor-hooks.json) — Cursor: appends `Closed:` to the note of this window. It does not write the paragraph.
- [**SessionStart**](https://github.com/ADRenaline-Suite/plugin-chronology/blob/main/hooks/claude-hooks.json) — Claude Code: passes the window id. The close stamp does not run there. The portable write is `/chronology-note`.

## Output

- Repository: [**ADRenaline Chronology**](https://github.com/ADRenaline-Suite/plugin-chronology).
- Folder: `adrenaline/chronology/` (override via `.cursor/adrenaline.json`). An existing `chronology/` at the project root keeps receiving files.
- Name: `<person>/<NNN>-chronology-<topic>.md`. `<NNN>` is the next free number in that person's folder. The paragraph follows the language of the request. The type stays `chronology`.

| Format | Description |
| --- | --- |
| `.md` | One chat window. The window id is an HTML comment. Each section has `Outcome:` and one paragraph. |
| `STATUS.md` | State of each file. Columns stay `N`, `archivo`, `estado`, `sustituye`, `notas`. `N` restarts per person. |
| `ORIGIN.json` | Folder marker: `suite`, `plugin`, `repository`, `convention` `adr-001`. Not an `<NNN>` file |

## Not in this plugin

- Current picture of the project → [**ADRenaline Project Context**](https://github.com/ADRenaline-Suite/plugin-project-context).
- A decision that must stay in force → [**ADRenaline Software Architect**](https://github.com/ADRenaline-Suite/plugin-software-architect).
- Runtime signals → ADRenaline Observability (`plugin-observability`).
- UML diagram → [**ADRenaline UML Diagrams**](https://github.com/ADRenaline-Suite/plugin-uml-diagrams).

In Claude Code, commands use the prefix `/plugin-chronology:` (example: `/plugin-chronology:chronology-help`).

## Done

- With no names after this command, the reply is this catalog. Every id is a markdown link to the GitHub URL listed here. Commands are grouped by skill.
- With names after this command, the reply is only the help for those names, in that order: the catalog line and, when the README has it, the paragraphs under that heading. The other names were not run.
- No skill ran. No command ran. No file was written.
- No entry was invented. If a component exists in the plugin and is missing here, one line was added from its `description` and the reply says the catalog was refreshed.
