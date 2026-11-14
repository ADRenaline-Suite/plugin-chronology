---
name: record-chronology
description: Writes one paragraph per chat window about what was tried in this project and whether it worked. Use it at the end of a turn that changed the project or reached a result, without waiting to be asked, and when someone asks for the chronology note.
---

<p align="right">Language:&emsp;<img alt="English" src="https://raw.githubusercontent.com/ADRenaline-Suite/.github/main/profile/lang-en-on.svg" align="middle" style="vertical-align:middle"> <a href="SKILL.es.md" style="vertical-align:middle"><img alt="Español" src="https://raw.githubusercontent.com/ADRenaline-Suite/.github/main/profile/lang-es-off.svg" align="middle" style="vertical-align:middle"></a></p>

[🏠 Chronology](../../README.md)

# Record the chronology

Write one note for this chat window: what was tried in this project and whether it worked. The note is for the project where this plugin is installed. A failed attempt that never became a commit stays in the note.

Source: Sam Bleckley, Lab Notebooks (https://sambleckley.com/writing/lab-notebooks.html); Joseph Hallenbeck, Lab Notebooks & Software Development (https://joehallenbeck.com/lab-notebooks-and-software-development/). There is no ISO standard for this record. The Cursor hook behavior is the vendor mechanism (https://cursor.com/docs/hooks), not the lab-notebook practice.

## Before writing

1. Read only [note.md](references/note.md).
2. `/chronology-note` fixes this situation. A turn that changed the project or reached a result does the same, without waiting to be asked.
3. Do not copy the transcript. Do not write a secret, a token, or the contents of an env file. Do not write the architecture decision, the project picture, or a diagram. Ask that plugin when the request is its artifact.

## Language

The instructions stay in English. Write the paragraph in the language of the request. If the request names a language, use that one. Otherwise use the language the request is written in. Keep names the person already used. The type in the file name stays `chronology`. `STATUS.md` columns stay `N`, `archivo`, `estado`, `sustituye`, `notas`. The reply stays on the request. The labels `Outcome:` and `Closed:`, and the comment `<!-- window:<id> -->`, stay in English.

## When a prerequisite is missing

`git config user.name` is required. When it is missing, write no chronology file and put no block in thinking.

When the person asked for the chronology note, the reply is only this line:

```text
ADRenaline chronology: skipped, missing git user.name.
```

When the note would have ridden on another task, add no line.

## Delivery

The folder is `adrenaline/chronology/` at the project root. If `.cursor/adrenaline.json` has `outputDirs["plugin-chronology"]` set to a relative path, without `..` and not absolute, use that path. If the file, the key, or a valid path is missing, use `adrenaline/chronology/`. If `adrenaline/chronology/` does not exist yet and `chronology/` at the project root already has this plugin's `ORIGIN.json` or `STATUS.md`, keep writing there. The writer creates the folder if it does not exist, and does not write outside it. The reply does not name the folder.

The person folder is `git config user.name` made kebab-case, as [note.md](references/note.md) says. Do not invent a person. `<NNN>` is the next free integer, three digits, in that person's folder, and it is not reused. Another person's folder has its own count. The file is `<person>/<NNN>-chronology-<topic>.md`. One chat window is one file. A later section of the same window is appended to that file. The `archivo` cell is `<person>/<file>`.

Keep `<folder>/STATUS.md` with columns `N`, `archivo`, `estado`, `sustituye`, and `notas`. `N` is the number in that person's folder. The same `N` may appear on two rows when the people differ. `sustituye` stays empty: an older note stays `accepted`. `notas` is `window:<id>; outcome:<worked|failed|partial>; at:<UTC>` and must not contain `|`.

Keep `<folder>/ORIGIN.json` beside `STATUS.md`. It is not an `<NNN>` file and it has no row in `STATUS.md`. Write it when the folder is created. On a later delivery, write it again only when it is missing or a field differs. The fields are `suite` `ADRenaline-Suite`, `plugin` `plugin-chronology`, `repository` `https://github.com/ADRenaline-Suite/plugin-chronology`, and `convention` `adr-001`. The marker names the folder. It does not say that each file inside is unchanged.

A new window is the next `<NNN>` of that person and starts `accepted`. The same window keeps its `<NNN>` and stays `accepted` when a section is appended.

In Cursor, do not create or edit these files. That edit is what the chat shows. Put one block in thinking and nowhere else. The `afterAgentThought` hook writes the file, picks the number, and decides whether to append. The reply stays the answer to the request.

```text
<<<chronology
title: Login
outcome: failed

The correct password was still rejected after the bcrypt rounds were lowered.
chronology>>>
```

`title` is a short topic. `outcome` is `worked`, `failed`, or `partial`. The paragraph is one block, in the language of the request. Omit the block when this turn does not qualify.

Where that hook does not run, write the files yourself and still leave them out of the reply.

When the person asked for the chronology note, the reply is only this line. Do not paste the paragraph.

```text
ADRenaline chronology: updated 001, worked.
```

`001` is the `<NNN>` of the note file that already contains this window id. Read that number from the file name or from its row in `STATUS.md`. The last word is the outcome of the latest section. The line stays in English.

If this window id is not in a note file, do not print `updated` and do not choose the next number. The reply is only this line, and the block still goes in thinking:

```text
ADRenaline chronology: missing note.
```

On `stop`, if this window changed a file and no note exists yet, the hook writes one `partial` note. The paragraph says the thought did not say what was tried. A later block in that same window replaces that note. `missing note` remains the reply when the person asks and the file is still absent: this turn has not stopped, or the hook did not see a file change.

## Done

Before you close, evaluate this list and the `## Done` list in the reference for this situation. A command fixes the situation: use the reference that command names. Every item is true, or you fix the delivery in this turn. Do not leave a file that fails an item. Do not mark it `accepted` while an item fails. A template the reference names is applied and recorded under Assumed; the delivery uses the state that reference names. A prerequisite that still stops the delivery is not a failed list: follow "When a prerequisite is missing" and write no files for that piece.

- The only file this skill adds is the chronology note, or it adds nothing when the turn did not change the project and did not reach a result.
- Files are only in the output folder, named as Delivery says. `<NNN>` is not reused inside that person's folder. `STATUS.md` matches the files and the state this situation allows.
- `ORIGIN.json` is in the output folder. Its four fields match this plugin. It has no row in `STATUS.md`.
- The artifact language matches the request. `STATUS.md` columns stay `N`, `archivo`, `estado`, `sustituye`, `notas`.
- Every field the template requires is filled. No placeholder remains (`#…`, `<task>`, `TBD`, lorem ipsum). A field the reference tells you to leave blank until data arrives is blank on purpose, and the state is the one the reference names.
- Nothing this skill forbids was added. The reference names what stays out.
- The reply does not mention the note unless the person asked for the chronology note. In that case the reply is only `ADRenaline chronology: updated <NNN>, <outcome>.` `<NNN>` is the number of the note file that already contains this window id. If that file is absent, the reply is only `ADRenaline chronology: missing note.` and the next number is not chosen. A missing `git user.name`, when they asked for the note, is `ADRenaline chronology: skipped, missing git user.name.` Any other turn adds no chronology line. In Cursor the agent does not create or edit the chronology files. The block is only in thinking, and only when the turn qualifies.

## Example

Input: the request is in Spanish, in a project called `tienda`. `git config user.name` is `Ana`. The window id is `a1f3c9`. This turn changed the login check. The correct password was still rejected after lowering the bcrypt rounds. No earlier note contains `<!-- window:a1f3c9 -->`. Ana's folder has no chronology files.

`accepted` output: `adrenaline/chronology/ana/001-chronology-login.md`, with `Outcome: failed` and one Spanish paragraph. `STATUS.md` has `N` `001`, `archivo` `ana/001-chronology-login.md`, `estado` `accepted`, `sustituye` empty, and `notas` `window:a1f3c9; outcome:failed; at:<the section timestamp>`. In Cursor the hook writes that file from the thinking block. The reply is only about the login check.
