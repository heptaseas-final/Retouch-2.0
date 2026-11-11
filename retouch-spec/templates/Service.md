# Template: Service, its fake, and container registration

```swift
nonisolated protocol ExampleServicing: Sendable {
    func loadTitle() async -> String
}

nonisolated final class ExampleService: ExampleServicing {
    func loadTitle() async -> String {
        "Example"
    }
}
```

Fake, in `RetouchTests/Fakes/FakeExampleService.swift`:

```swift
nonisolated final class FakeExampleService: ExampleServicing {
    func loadTitle() async -> String {
        "Example"
    }
}
```

Registration in `AppContainer.swift`, appended:

```swift
let example = ExampleService()

func makeExampleViewModel() -> ExampleViewModel {
    ExampleViewModel(service: example)
}
```

Rules:
- Protocol first, implementation second, both `nonisolated` unless the service must run on the main actor.
- Per-frame code must not allocate per frame.
- Created only in `AppContainer`, never inside a View or ViewModel.
- Verify these templates compile in Xcode when the project default isolation changes.
