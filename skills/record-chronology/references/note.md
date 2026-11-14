[🏠 Chronology](../../../README.md) / [Record the chronology](../SKILL.md)

# Chronology note

One chat window is one file. The file says what was tried in this project and whether it worked. A second window is another file, even on the same day and on the same topic.

## When to write

Write at the end of a turn that changed the project or reached a result. Do not wait to be asked. Cursor's `sessionStart` hook may already have given the window id and the person folder. Use those values when they match this procedure. When the hook did not run, resolve them yourself.

In Cursor, do not create or edit the chronology files. Put the block from the skill in thinking. The `afterAgentThought` hook writes the file. Where that hook does not run, write the file yourself.

Skip the file, and omit the block, when the turn did not change the project and did not reach `worked`, `failed`, or `partial`. A question with no result is a skip. Add no chronology line.

## Person

Run `git config user.name`. The folder is that value, trimmed, lowercased, with accents folded (`áàäâã` to `a`, `éèëê` to `e`, `íìïî` to `i`, `óòöôõ` to `o`, `úùüû` to `u`, `ñ` to `n`, `ç` to `c`), spaces turned into single hyphens, and every other character dropped. `Ana López` is `ana-lopez`.

When the command prints nothing, the name is missing. Follow "When a prerequisite is missing" in the skill. Do not use the email, the machine name, or a guessed name.

## Window

The window id is the `session_id` from the hook context. It is the same value as `conversation_id`. Keep only letters, digits, and hyphens. Put this comment under the title, on its own line:

```text
<!-- window:a1f3c9 -->
```

Search the output folder for that exact comment before choosing a number. A match is this window's file. Do not open another file for the same id.

## Number

`<NNN>` is the highest `<NNN>-chronology-*.md` in this person's folder, plus one, formatted to three digits. Another person's `001` does not count. The number is not reliable across two machines of the same person that have not synced: both can pick the same next number. When the path already exists and its window comment is a different id, save this note at the next free number of that person. Do not change the window id. When a merge leaves two notes for one path, the file whose window id was already in that number keeps the path. The other moves to the next free number.

## Same window, later section

Append a section. Keep the `<NNN>`. Keep `accepted`. Leave the earlier paragraphs as they are.

Append when the last section's UTC date is a previous day, or when the outcome changed and this UTC day still has fewer than two sections. Do not append when this UTC day already has two sections. Do not append when this UTC day has one section and the outcome is unchanged.

A section heading is the UTC time `yyyy-MM-ddTHH:mm:ssZ`. The outcome line is one of `Outcome: worked`, `Outcome: failed`, `Outcome: partial`. Then one paragraph. The paragraph names what was tried and how it ended. It does not quote a secret, a token, an env file, or the transcript. A later section may name the earlier timestamp in the prose. It does not delete it.

## File

```text
# Login

<!-- window:a1f3c9 -->

## 2026-11-02T16:40:00Z

Outcome: failed

The correct password was still rejected after the bcrypt rounds were lowered.

## 2026-11-03T11:15:00Z

Outcome: worked

Follows the 16:40 section. The rejection came from the token clock. A 30-second skew is accepted.
```

The title and the paragraph follow the language of the request. The topic in the file name is kebab-case and keeps the words the person already used. The type stays `chronology`: `001-chronology-login.md`.

`STATUS.md` row for that file:

```text
| 001 | ana/001-chronology-login.md | accepted | | window:a1f3c9; outcome:worked; at:2026-11-03T11:15:00Z |
```

Update `outcome` and `at` to the latest section. Do not put `|` in `notas`. Leave `sustituye` empty. Do not mark an earlier note `superseded` because a later window exists.

`Closed:` is written by the Cursor `sessionEnd` hook. Do not invent that line while the window is open.

## Prompt when the name is missing

The reply does not print this prompt. A missing name stays silent, unless the person asked for the chronology note. That reply is the skipped line in the skill.

```text
Set git user.name and ask again for the chronology note. Window id: #…
```

## Done

- The file is the one window: the comment `<!-- window:<id> -->` matches this chat, and a second window was not appended into it.
- The paragraph says what was tried and ends in `worked`, `failed`, or `partial`. It has no transcript and no secret.
- This UTC day has at most two sections in that file. An earlier section is still readable.
- `<NNN>` is the next free number in that person's folder, or the number the existing window comment already had.
- The `STATUS.md` row for this file is `accepted`, `sustituye` is empty, and `notas` has `window:`, `outcome:`, and `at:` with no `|`.
- A turn that did not change the project and did not reach a result wrote no file, added no chronology line, and put no block in thinking. In Cursor the agent did not create or edit the chronology files.
- A line that says `updated` uses the `<NNN>` of the file that already contains this window id. No such file means the line was `ADRenaline chronology: missing note.` and no next number was chosen.
