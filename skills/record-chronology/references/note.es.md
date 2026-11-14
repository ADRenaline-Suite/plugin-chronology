[🏠 Cronología](../../../README.es.md) / [Registrar la cronología](../SKILL.es.md)

# Nota de cronología

Una ventana de chat es un archivo. El archivo dice qué se intentó en este proyecto y si funcionó. Una segunda ventana es otro archivo, aunque sea el mismo día y el mismo tema.

## Cuándo escribir

Se escribe al final de un turno que cambió el proyecto o dejó un resultado. No se espera a que se pida. El hook `sessionStart` de Cursor puede haber dado ya el id de la ventana y la carpeta de la persona. Usa esos valores cuando coinciden con este procedimiento. Si el hook no corrió, resuélvelos tú.

En Cursor no crees ni edites los archivos de cronología. Pon en el pensamiento el bloque del skill. El hook `afterAgentThought` escribe el archivo. Donde ese hook no corre, escribe el archivo tú.

No crees archivo, y omite el bloque, cuando el turno no cambió el proyecto y no llegó a `worked`, `failed` o `partial`. Una pregunta sin resultado es un salto. No añadas línea de cronología.

## Persona

Ejecuta `git config user.name`. La carpeta es ese valor, recortado, en minúsculas, con los acentos plegados (`áàäâã` a `a`, `éèëê` a `e`, `íìïî` a `i`, `óòöôõ` a `o`, `úùüû` a `u`, `ñ` a `n`, `ç` a `c`), los espacios vueltos un solo guion, y el resto de caracteres fuera. `Ana López` es `ana-lopez`.

Si el comando no imprime nada, falta el nombre. Sigue «Cuando falta un prerrequisito» en el skill. No uses el correo, el nombre de la máquina ni un nombre supuesto.

## Ventana

El id de la ventana es el `session_id` del contexto del hook. Es el mismo valor que `conversation_id`. Conserva solo letras, dígitos y guiones. Pon este comentario bajo el título, en su propia línea:

```text
<!-- window:a1f3c9 -->
```

Busca en la carpeta de salida ese comentario exacto antes de elegir un número. Una coincidencia es el archivo de esta ventana. No abras otro archivo para el mismo id.

## Número

`<NNN>` es el mayor `<NNN>-chronology-*.md` de la carpeta de esta persona, más uno, con tres dígitos. El `001` de otra persona no cuenta. El número no es fiable entre dos equipos de la misma persona que no han sincronizado: los dos pueden elegir el mismo siguiente. Si la ruta ya existe y su comentario de ventana es otro id, guarda esta nota en el siguiente libre de esa persona. No cambies el id de la ventana. Si un merge deja dos notas para una ruta, el archivo cuyo id de ventana ya estaba en ese número conserva la ruta. El otro pasa al siguiente libre.

## La misma ventana, un tramo después

Añade un tramo. Conserva el `<NNN>`. Conserva `accepted`. Deja los párrafos anteriores como están.

Añade un tramo cuando la fecha UTC del último tramo es de un día anterior, o cuando el resultado cambió y este día UTC todavía tiene menos de dos tramos. No añadas cuando este día UTC ya tiene dos tramos. No añadas cuando este día UTC tiene un tramo y el resultado no cambió.

El encabezado de un tramo es la hora UTC `yyyy-MM-ddTHH:mm:ssZ`. La línea de resultado es una de `Outcome: worked`, `Outcome: failed`, `Outcome: partial`. Después, un párrafo. El párrafo dice qué se intentó y en qué quedó. No cita un secreto, un token, un archivo de entorno ni el transcript. Un tramo posterior puede nombrar la hora anterior en la prosa. No la borra.

## Archivo

```text
# Login

<!-- window:a1f3c9 -->

## 2026-11-02T16:40:00Z

Outcome: failed

La contraseña correcta siguió rechazada después de bajar las rondas de bcrypt.

## 2026-11-03T11:15:00Z

Outcome: worked

Sigue al tramo de las 16:40. El rechazo venía del reloj del token. Se acepta un margen de 30 segundos.
```

El título y el párrafo siguen el idioma del pedido. El tema del nombre de archivo va en kebab-case y conserva las palabras que la persona ya usó. El tipo sigue siendo `chronology`: `001-chronology-login.md`.

Fila de `STATUS.md` para ese archivo:

```text
| 001 | ana/001-chronology-login.md | accepted | | window:a1f3c9; outcome:worked; at:2026-11-03T11:15:00Z |
```

Actualiza `outcome` y `at` al último tramo. No pongas `|` en `notas`. Deja `sustituye` vacío. No marques una nota anterior como `superseded` porque exista una ventana posterior.

`Closed:` lo escribe el hook `sessionEnd` de Cursor. No inventes esa línea mientras la ventana sigue abierta.

## Prompt cuando falta el nombre

La respuesta no imprime este prompt. Un nombre que falta se queda en silencio, salvo que la persona haya pedido la nota de cronología. Esa respuesta es la línea de omisión del skill.

```text
Fija git user.name y vuelve a pedir la nota de cronología. Id de ventana: #…
```

## Hecho

- El archivo es esa ventana: el comentario `<!-- window:<id> -->` coincide con este chat, y una segunda ventana no se añadió dentro.
- El párrafo dice qué se intentó y termina en `worked`, `failed` o `partial`. No tiene transcript ni secreto.
- Este día UTC tiene como máximo dos tramos en ese archivo. Un tramo anterior sigue legible.
- `<NNN>` es el siguiente libre de la carpeta de esa persona, o el número que el comentario de esta ventana ya tenía.
- La fila de `STATUS.md` de este archivo está `accepted`, `sustituye` está vacío, y `notas` tiene `window:`, `outcome:` y `at:` sin `|`.
- Un turno que no cambió el proyecto y no dejó un resultado no escribió archivo, no añadió línea de cronología y no puso el bloque en el pensamiento. En Cursor el agente no creó ni editó los archivos de cronología.
- Una línea que dice `updated` usa el `<NNN>` del archivo que ya contiene el id de esta ventana. Si ese archivo no está, la línea fue `ADRenaline chronology: missing note.` y no se eligió el número siguiente.
