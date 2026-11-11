# Template: ViewModel and its test

```swift
import Observation

@Observable
final class ExampleViewModel {
    private(set) var title = ""
    private let service: ExampleServicing

    init(service: ExampleServicing) {
        self.service = service
    }

    func onAppear() async {
        title = await service.loadTitle()
    }
}
```

Test:

```swift
import Testing
@testable import Retouch

@MainActor
struct ExampleViewModelTests {
    @Test func loadsTitle() async {
        let viewModel = ExampleViewModel(service: FakeExampleService())
        await viewModel.onAppear()
        #expect(viewModel.title == "Example")
    }
}
```

Rules:
- One ViewModel per screen, under 300 lines. If it passes that, split it.
- Dependencies are protocols received in `init`.
- State is `private(set)`. Views change it only by calling methods.
- No `ObservableObject`, `@Published`, no `@MainActor` annotation.
