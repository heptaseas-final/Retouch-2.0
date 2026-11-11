# Playbook: add a feature (new screen or flow)

Read `../engineering.md` first.

1. Name the feature in PascalCase. Check `Features/` for an existing feature that already covers it.
2. Create only the folders you need: `Features/<Feature>/Views/`, `ViewModels/`, `Components/`.
3. ViewModel: copy the shape from `../templates/ViewModel.md`. It takes protocols in `init`. If it needs a capability that does not exist, do `add-service.md` first.
4. View: copy the shape from `../templates/View.md`. Sub-views go in `Features/<Feature>/Components/`. If a second feature already needs one, follow `add-component.md`.
5. Register in two places only, always appended at the end:
   - `AppContainer.swift`: one factory method `make<Feature>ViewModel()`.
   - `ContentView.swift`: one route to the new View.
6. Tests: `RetouchTests/Features/<Feature>/<Feature>ViewModelTests.swift` and any fakes in `RetouchTests/Fakes/`.
7. Check: no import of another feature, every file under 300 lines, no comments, no singletons.
8. Share data with another feature through `Models/` or a shared service, never by importing that feature.
9. Report the files created, the two appended lines, and what to check manually.
