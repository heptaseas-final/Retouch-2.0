---
name: retouch-spec
description: Engineering rules for the Retouch iOS app (Team Heptaseas): MVVM structure, where files go, call order, naming, concurrency, tests, and how AI assistants must work so teammates using different AIs do not create merge conflicts. Use this skill whenever the user writes, edits, reviews, refactors or plans Swift or SwiftUI code for Retouch, adds a feature, service, component or file, asks where something belongs or how to call something, or mentions Retouch, mirror, zoom gesture, auto lighting, onboarding, AppContainer, MOVE_MAP or SPEC.md, even if they never say "skill" or "architecture".
---

# Retouch engineering

Version: 1. If `engineering.md` shows a different version, tell the user this skill is outdated and must be re-uploaded.

SPEC.md says what to build. `engineering.md` says how. Follow both.

## Start of every task

1. This chat cannot see the repo. Ask the user to attach SPEC.md (if product behavior matters) and the exact files the task will change. Say which ones you are missing. Never guess file contents.
2. Read `engineering.md`.
3. Pick the playbook that matches the task and read it:

| Task | Read |
|---|---|
| New screen or flow | `playbooks/add-feature.md` |
| New camera, lighting, zoom, rendering or storage capability | `playbooks/add-service.md` |
| New reusable UI piece | `playbooks/add-component.md` |
| Change, fix or refactor existing code | `playbooks/modify-existing.md` |

4. Code shape comes from `templates/View.md`, `templates/ViewModel.md`, `templates/Service.md`. Copy the shape, do not invent a new one.
5. Reply with a short plan first: files to create or edit with full paths, assumptions, open questions. Wait for approval before writing code.

## Output rules

- New files: complete and ready to paste. Existing files: complete file based on the version the user attached, changing only the lines the task needs.
- No comments in code, including file headers, MARK and TODO.
- Touch only files the task needs. Report unrelated problems, do not fix them.
- You cannot build or run anything. Say what was not verified and what the user must check on a real iPhone.
- Keep replies short. No em dashes.
