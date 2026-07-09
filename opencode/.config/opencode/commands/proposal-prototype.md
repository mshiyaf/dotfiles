---
description: Create a client-facing prototype plan, HTML prototype, or image prompts from a proposal draft.
agent: docs-writer
---

Use the `prototyping-proposals` skill.
Use the `proposal-writing` skill to preserve scope, assumptions, exclusions, and client-safe proposal language.
Use the `frontend-design` skill when creating HTML UI.

Create prototype support material from the supplied proposal, notes, or referenced files.
Default to a prototype plan unless the request explicitly asks to create files, HTML, screens, or generated images.
Do not create generated raster images unless the current agent has an image-generation tool and the user explicitly asks for generated images.
For Codex, use the `imagegen` skill when raster image generation is requested.

Request:
$ARGUMENTS
