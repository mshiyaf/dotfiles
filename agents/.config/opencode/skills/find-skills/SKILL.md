---
name: find-skills
description: Use when searching for public agent skills, evaluating whether a skill is safe to install, or deciding between existing and custom skills.
---
Vendored from `vercel-labs/skills/find-skills` and trimmed for this global OpenCode setup.

## When to use
- The user asks whether an existing skill exists for a task.
- A task looks common enough that a reusable public skill may already exist.
- You are considering adding a new global skill.
- You need to compare public skills against local fallback skills.

## Procedure
1. Understand the task domain and whether it is broadly reusable.
2. Search trusted sources first: `skills.sh`, `skillsgate.ai`, OpenCode docs, and reputable GitHub repos.
3. Prefer skills that are generic, readable, maintained, and safe for global use.
4. Do not choose by popularity alone; inspect the actual `SKILL.md` content.
5. Avoid large random packs, vague always-on behavior, narrow framework skills, and domain/company skills.
6. Recommend global install only when the skill is useful across many repositories.
7. Recommend repo-local install for framework, product, company, architecture, or domain behavior.

## Quality checklist
- Source is reputable or the repo is easy to inspect.
- Skill content is concise enough to load on demand.
- Instructions are procedural, not vague personality prompts.
- No suspicious shell commands, credential handling, or broad automation.
- No stack-specific assumptions unless intentionally local.

## Install guidance
Use the public install command only after review. For this dotfiles repo, prefer vendoring a reviewed `SKILL.md` into `opencode/.config/opencode/skills/<name>/SKILL.md` so Stow can manage it deterministically.
