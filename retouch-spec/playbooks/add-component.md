# Playbook: add a UI component

Read `../engineering.md` first.

Ask: is it used by one feature, or by two or more?

| Answer | Location |
|---|---|
| One feature | `Features/<Feature>/Components/` |
| Two or more | `Components/` |

Rules:
- A component takes values and closures. It never takes a ViewModel or a service.
- One component per file. Its modifier, config or small enum may share the file.
- Add a `#Preview` with inline sample data.
- No hard-coded colors or sizes that already exist in `Extensions/Color+App.swift` or a `*Config`.

Promoting a feature component to `Components/` when a second feature needs it:
1. Do it in its own commit, `git mv` only, no logic change.
2. Update only the imports and references the move breaks.
3. Tell the team before merging, because it touches two features.
