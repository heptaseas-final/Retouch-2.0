# Playbook: add a service (camera, lighting, zoom, rendering, storage)

Read `../engineering.md` first.

1. Search `Services/` for an existing service with the same responsibility. Extend it only if the responsibility is the same, otherwise create a new one.
2. Place it in `Services/<Domain>/`. If the folder would pass 8 files, add a subfolder.
3. Write the protocol `<Name>Servicing` and the implementation `<Name>Service`. Copy the shape from `../templates/Service.md`.
4. Heavy or per-frame work is `nonisolated` or an actor. Publish results to the main actor only at the end.
5. Tuning numbers go in `<Domain>Config` or the existing `*Tuning` file. Never inline them.
6. A persisted setting goes through a `<Name>Store` that wraps UserDefaults.
7. Register in `AppContainer.swift`: create it in `init` in dependency order, one line, then pass it into the ViewModel factories that need it.
8. Add `Fake<Name>Servicing` in `RetouchTests/Fakes/` and tests for the pure logic.
9. Report the files created, the container line, and what to check on a real iPhone.
