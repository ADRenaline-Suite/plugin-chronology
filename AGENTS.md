# plugin-chronology

Writes one paragraph per chat window about what was tried in this project and whether it worked. The procedure is in `skills/record-chronology/SKILL.md`. The situation manual is `skills/record-chronology/references/note.md`.

Files go in `adrenaline/chronology/<person>/` at the project root, or in the path `.cursor/adrenaline.json` sets under `outputDirs["plugin-chronology"]`. If `adrenaline/chronology/` does not exist yet and `chronology/` at the project root already has this plugin's `ORIGIN.json` or `STATUS.md`, keep writing there. `<NNN>` is the next free number in that person's folder. The window id stays inside the file. A turn that did not change the project and did not reach a result writes nothing. The person folder comes from `git config user.name`. Do not invent it. In Cursor the hook writes the file from the thinking block. Do not edit those files, and do not mention the note in the reply unless the person asked for it.
