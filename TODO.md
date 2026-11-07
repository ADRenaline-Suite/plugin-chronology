# TODO — plugin-chronology

Área compartida. Implementado: la versión y el changelog mandan (`0.0.1`). Este archivo sigue acotando el alcance.

La piden los oficios cuando el equipo quiere saber qué se intentó en este proyecto y si funcionó, incluido lo que no llegó a commit. No es una profesión. No va en todas las filas del ADR 3: se añade cuando hace falta esa bitácora antes de seguir el trabajo. Ningún rol copia sus skills.

El registro es del proyecto donde se instala el plugin. Una ventana de chat es una sesión de ese proyecto, aunque en ella se haya pedido un diagrama o un contrato.

## Resultado

Una carpeta `adrenaline/chronology/` con una nota por ventana de chat. La nota es un archivo en la carpeta de la persona, con un párrafo de lo que se intentó y el resultado (`worked`, `failed` o `partial`). Si la misma ventana sigue abierta, los tramos siguientes se añaden a ese archivo.

## Fuentes

No hay una norma ISO para la bitácora de una sesión de desarrollo. Lo que ninguna fuente dice (la carpeta por persona, el tope de dos tramos por día UTC, los hooks de Cursor) queda dicho como regla de este plugin, no como práctica externa.

- Sam Bleckley, [Lab Notebooks](https://sambleckley.com/writing/lab-notebooks.html). El código guarda lo que se integró. La bitácora guarda el intento que falló y no se commiteó. Una corrección posterior es otra entrada. La anterior se deja legible.
- Joseph Hallenbeck, [Lab Notebooks & Software Development](https://joehallenbeck.com/lab-notebooks-and-software-development/). La entrada anota la fecha, el objetivo y el resultado observado, éxito o fallo.
- Cursor, [Hooks](https://cursor.com/docs/hooks). `sessionStart` puede inyectar contexto. `sessionEnd` no puede pedir otro turno. `stop` puede enviar un mensaje de seguimiento, con tope. Es el mecanismo del editor, no la práctica de la bitácora.

## Qué hace la práctica

1. Una ventana, un archivo. Al cerrarla hay un párrafo. Si sigue abierta y el trabajo ya tiene otro resultado, o el último tramo es de otro día UTC, se añade un tramo al final del mismo archivo. Como máximo, dos tramos por día UTC.
2. El número es el siguiente libre de la carpeta de esa persona. Ana y Luis empiezan los dos en `001`. El id de la ventana va dentro del archivo (`<!-- window:<id> -->`), no en la carpeta.
3. La misma persona en dos equipos, sin haber sincronizado, puede elegir el mismo número. Al juntarlas, el archivo cuyo id de ventana no coincide pasa al siguiente libre de esa persona. El id no cambia.
4. Un turno que no cambió el proyecto y no dejó resultado no crea archivo. No se copia el transcript, ni un token, ni un `.env`.
5. La persona sale de `git config user.name`. Sin ese nombre no se inventa carpeta.

## Alcance previsto

- Nota de la ventana actual: crearla o añadirle un tramo.
- Sello `Closed:` al terminar la ventana, en Cursor.
- Un solo recordatorio automático si hubo edición de archivo y la nota no existe.

## Fuera de este plugin

- La foto vigente del proyecto: `plugin-project-context`.
- Una decisión que tiene que seguir vigente: `plugin-software-architect`.
- Las señales del sistema en ejecución: `plugin-observability`.
- El dibujo UML: `plugin-uml-diagrams`.
- Copiar el chat, los secretos o el volcado de herramientas.
- Una cuenta única para todo el equipo. El ADR 8 la mantiene para el resto de plugins. Este plugin es la excepción escrita en ese ADR.

## Plan de componentes

Un prompt: `skills/record-chronology/SKILL.md`. La situación es la nota.

```text
skills/record-chronology/
├── SKILL.md
└── references/
    └── note.md
```

Commands (oficio `chronology`):

- `/chronology-help` — catálogo.
- `/chronology-note` — la nota de esta ventana.

Rules:

- `rules/output-folder.mdc` — carpeta `adrenaline/chronology/<persona>/`, con la cuenta de esa persona.
- `rules/chronology-note.mdc` — escribir la nota en el mismo turno, sin que se pida, cuando hubo trabajo o un resultado.

Hooks, en archivos distintos:

- Cursor: `sessionStart`, `afterFileEdit`, `stop` (un solo seguimiento), `sessionEnd`.
- Claude Code: `SessionStart`. El sello de cierre no corre ahí. El camino portable es `/chronology-note`.

## Salida

Carpeta por defecto: `adrenaline/chronology/` (o la de `.cursor/adrenaline.json`). Si `chronology/` en la raíz ya tiene la salida de este plugin, se sigue ahí.

- `<persona>/<NNN>-chronology-<tema>.md`
- `STATUS.md` en la raíz de la salida. `N` es el número dentro de la carpeta de esa persona y puede repetirse entre personas. La celda `archivo` es `<persona>/<archivo>`.
- `ORIGIN.json`: `suite`, `plugin`, `repository`, `convention` `adr-001`. Sin fila en `STATUS.md`.

El texto del párrafo sigue el idioma del pedido. El tipo del nombre sigue en inglés (`chronology`). Las etiquetas `Outcome:`, `Closed:` y el comentario `<!-- window: -->` no se traducen: el hook las busca.
