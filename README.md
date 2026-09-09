# Reto Sin Pena — Pato Odor Block

Juego en vivo para el lanzamiento de Pato Odor Block. Los participantes se
unen con su nombre (buscándolo en la lista de invitados precargada), tienen
un tiempo límite para nombrar lugares incómodos por malos olores, el sistema
valida las respuestas, y se muestra primero una nube de palabras con los
lugares más mencionados y luego el ranking top 5.

## Estructura

- `index.html` — toda la app (HTML + CSS + JS en un solo archivo, sin build
  step). Es un sitio 100% estático: se puede desplegar tal cual a Vercel,
  Netlify, GitHub Pages, o cualquier hosting estático.
- `supabase/schema.sql` — el esquema de base de datos (copia de la migración
  ya aplicada al proyecto de Supabase en vivo). Seguro de volver a correr.

## Cómo funciona el backend (Supabase)

El juego necesita sincronización en tiempo real entre la pantalla del
anfitrión (`#pantalla`) y los teléfonos de los participantes (`#jugar`).
Para eso usa 4 tablas en Supabase, todas con el prefijo `pato_` para no
mezclarse con otras tablas que pueda haber en el mismo proyecto:

| Tabla           | Contenido                                    |
|-----------------|-----------------------------------------------|
| `pato_config`   | configuración del juego (un solo registro)    |
| `pato_state`    | estado de la ronda actual (un solo registro)  |
| `pato_players`  | un registro por participante                  |
| `pato_answers`  | un registro por (ronda, lugar) mencionado     |

Cada tabla guarda su información como un JSON (`data jsonb`), así que el
esquema es muy simple y el modelo de datos vive principalmente en el
JavaScript de `index.html` (función `wrapSupabase`).

La app se conecta a Supabase con la URL del proyecto y la **clave pública
(anon/publishable)**, que están escritas directamente en `index.html`
(constantes `SUPABASE_URL` y `SUPABASE_ANON_KEY`, cerca de la función
`boot()`). Esto es seguro exponerlo en el cliente: esa clave solo puede
hacer lo que las políticas de Row Level Security (RLS) le permiten, y las
políticas de estas 4 tablas están configuradas para ser abiertas
únicamente sobre ellas — no dan acceso a ninguna otra tabla del proyecto.

Si en algún momento cambias de proyecto de Supabase, solo tienes que:

1. Correr `supabase/schema.sql` contra el proyecto nuevo (o pedirle a
   Claude que lo haga con las herramientas de Supabase).
2. Actualizar `SUPABASE_URL` y `SUPABASE_ANON_KEY` en `index.html`.

## Si Supabase no carga

Si por cualquier razón la librería de Supabase no logra cargar (por
ejemplo sin conexión a internet), la app cae automáticamente a un modo
local (`makeLocalStore`) que guarda todo en memoria del navegador — sirve
para seguir probando la interfaz, pero sin sincronizar entre dispositivos.

## Despliegue

Este proyecto no necesita build ni dependencias — es un `index.html`
estático. Cualquier plataforma de hosting estático sirve (Vercel, Netlify,
GitHub Pages, etc.). En Vercel, simplemente se importa el repositorio o se
sube la carpeta directamente, sin configurar ningún comando de build.

## URLs del juego

- Participantes: `https://tu-dominio.vercel.app/#jugar`
- Pantalla del anfitrión (para proyectar): `https://tu-dominio.vercel.app/#pantalla`
