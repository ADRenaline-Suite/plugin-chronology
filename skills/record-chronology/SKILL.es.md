---
name: record-chronology
description: Escribe un párrafo por ventana de chat sobre lo que se intentó en este proyecto y si funcionó. Úsalo al final de un turno que cambió el proyecto o dejó un resultado, sin esperar a que se pida, y cuando alguien pide la nota de cronología.
---

<p align="right">Idioma:&emsp;<a href="SKILL.md" style="vertical-align:middle"><img alt="English" src="https://raw.githubusercontent.com/ADRenaline-Suite/.github/main/profile/lang-en-off.svg" align="middle" style="vertical-align:middle"></a> <img alt="Español" src="https://raw.githubusercontent.com/ADRenaline-Suite/.github/main/profile/lang-es-on.svg" align="middle" style="vertical-align:middle"></p>

[🏠 Cronología](../../README.es.md)

# Registrar la cronología

Escribe una nota de esta ventana de chat: qué se intentó en este proyecto y si funcionó. La nota es del proyecto donde está instalado el plugin. Un intento que falló y no llegó a commit se queda en la nota.

Fuente: Sam Bleckley, Lab Notebooks (https://sambleckley.com/writing/lab-notebooks.html); Joseph Hallenbeck, Lab Notebooks & Software Development (https://joehallenbeck.com/lab-notebooks-and-software-development/). No hay una norma ISO para este registro. El comportamiento de los hooks de Cursor es el mecanismo del editor (https://cursor.com/docs/hooks), no la práctica de la bitácora.

## Antes de escribir

1. Lee solo [note.es.md](references/note.es.md).
2. `/chronology-note` fija esta situación. Un turno que cambió el proyecto o dejó un resultado hace lo mismo, sin esperar a que se pida.
3. No copies el transcript. No escribas un secreto, un token ni el contenido de un archivo de entorno. No escribas la decisión de arquitectura, la foto del proyecto ni un diagrama. Pide ese plugin cuando el pedido sea su artefacto.

## Idioma

Las instrucciones de la página en inglés son las que lee el agente. El párrafo sigue el idioma del pedido. Si el pedido nombra un idioma, se usa ese. Si no, se usa el idioma en el que está escrito el pedido. Se conservan los nombres que la persona ya usó. El tipo del nombre de archivo sigue siendo `chronology`. Las columnas de `STATUS.md` siguen `N`, `archivo`, `estado`, `sustituye`, `notas`. La respuesta usa ese mismo idioma. Las etiquetas `Outcome:` y `Closed:`, y el comentario `<!-- window:<id> -->`, siguen en inglés.

## Cuando falta un prerrequisito

Hace falta `git config user.name`. Si falta, no se escribe archivo de cronología.

Cuando `/chronology-note` es todo el pedido, la respuesta es solo esto, en el idioma del pedido:

1. «Falta:» y `git user.name`.
2. «En un mensaje:» y el prompt de [note.es.md](references/note.es.md).

Cuando la nota va al final de otra tarea, no sustituyas la respuesta de esa tarea. Añade una frase: la nota no se escribió porque falta `git user.name`.

## Entrega

La carpeta es `adrenaline/chronology/` en la raíz del proyecto. Si `.cursor/adrenaline.json` tiene `outputDirs["plugin-chronology"]` con una ruta relativa, sin `..` y no absoluta, se usa esa ruta. Si falta el archivo, la clave o una ruta válida, se usa `adrenaline/chronology/` y, en el último caso, se dice. Si `adrenaline/chronology/` aún no existe y `chronology/` en la raíz ya tiene el `ORIGIN.json` o el `STATUS.md` de este plugin, se sigue escribiendo ahí y se dice. Crea la carpeta si no existe. No escribas fuera de ella.

La carpeta de la persona es `git config user.name` en kebab-case, como dice [note.es.md](references/note.es.md). No inventes una persona. `<NNN>` es el siguiente entero libre, con tres dígitos, en la carpeta de esa persona, y no se reutiliza. La carpeta de otra persona tiene su propia cuenta. El archivo es `<persona>/<NNN>-chronology-<tema>.md`. Una ventana de chat es un archivo. Un tramo posterior de la misma ventana se añade a ese archivo. La celda `archivo` es `<persona>/<archivo>`.

Mantén `<carpeta>/STATUS.md` con columnas `N`, `archivo`, `estado`, `sustituye` y `notas`. `N` es el número en la carpeta de esa persona. El mismo `N` puede aparecer en dos filas cuando las personas son distintas. `sustituye` queda vacío: una nota anterior sigue `accepted`. `notas` es `window:<id>; outcome:<worked|failed|partial>; at:<UTC>` y no lleva `|`.

Mantén `<carpeta>/ORIGIN.json` junto a `STATUS.md`. No es un archivo `<NNN>` y no tiene fila en `STATUS.md`. Se escribe al crear la carpeta. En una entrega posterior se vuelve a escribir solo si falta o si un campo difiere. Los campos son `suite` `ADRenaline-Suite`, `plugin` `plugin-chronology`, `repository` `https://github.com/ADRenaline-Suite/plugin-chronology` y `convention` `adr-001`. El marcador nombra la carpeta. No dice que cada archivo de dentro siga sin cambios.

Una ventana nueva es el siguiente `<NNN>` de esa persona y nace `accepted`. La misma ventana conserva su `<NNN>` y sigue `accepted` cuando se añade un tramo. Al cerrar, di la carpeta, el archivo, el `N` y el estado. Si el turno no calificaba, di que no se escribió nota.

## Hecho

Antes de cerrar, evalúa esta lista y la lista `## Done` de la referencia de esta situación. Un command fija la situación: usa la referencia que nombra. Cada ítem es verdad, o corriges la entrega en este turno. No dejes un archivo que falle un ítem. No lo marques `accepted` mientras un ítem falle.

- El único archivo que añade este skill es la nota de cronología, o no añade nada cuando el turno no cambió el proyecto y no dejó un resultado.
- Los archivos están solo en la carpeta de salida, con el nombre que dice Entrega. `<NNN>` no se reutiliza dentro de la carpeta de esa persona. `STATUS.md` coincide con los archivos y con el estado que esta situación permite.
- `ORIGIN.json` está en la carpeta de salida. Sus cuatro campos coinciden con este plugin. No tiene fila en `STATUS.md`.
- El idioma del artefacto coincide con el pedido. Las columnas de `STATUS.md` siguen `N`, `archivo`, `estado`, `sustituye`, `notas`.
- Cada campo que la plantilla pide está lleno. No queda un hueco (`#…`, `<task>`, `TBD`, lorem ipsum).
- No se añadió nada que este skill prohíbe. La referencia dice qué queda fuera.
- La respuesta nombra la carpeta, los archivos, el `N` y el estado.

## Ejemplo

Entrada: el pedido está en español, en un proyecto llamado `tienda`. `git config user.name` es `Ana`. El id de la ventana es `a1f3c9`. Este turno cambió la comprobación del login. La contraseña correcta siguió rechazada después de bajar las rondas de bcrypt. Ninguna nota anterior contiene `<!-- window:a1f3c9 -->`. La carpeta de Ana no tiene archivos de cronología.

Salida `accepted`: `adrenaline/chronology/ana/001-chronology-login.md`, con `Outcome: failed` y un párrafo en español. `STATUS.md` tiene `N` `001`, `archivo` `ana/001-chronology-login.md`, `estado` `accepted`, `sustituye` vacío y `notas` `window:a1f3c9; outcome:failed; at:<la hora del tramo>`. La respuesta nombra esa carpeta, ese archivo, `001` y `accepted`.
