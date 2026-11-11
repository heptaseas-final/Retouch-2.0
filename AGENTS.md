# AGENTS.md

This repo has a strict structure. Before writing or changing any code:

1. Read `retouch-spec/SKILL.md`, then `retouch-spec/engineering.md`, then the matching file in `retouch-spec/playbooks/`.
2. Read `SPEC.md` for product behavior.
3. Send a short plan (file paths, assumptions, open questions) and wait for approval.

Hard rules:
- Call path: View, ViewModel, Service (protocol), Model. Services are created only in `App/AppContainer.swift`.
- One file, one responsibility, under 300 lines. No new folders.
- No comments in code, no singletons, no third-party packages.
- Touch only the files the task needs. Report unrelated issues, do not fix them.
- Do not edit `project.yml`, build settings, or `RetouchWidgetExt/OpenRetouchIntent.swift`.
