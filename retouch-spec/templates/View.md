# Template: View

A View owns its ViewModel through `State`, receives it in `init`, and only calls its methods.

```swift
import SwiftUI

struct ExampleView: View {
    @State private var viewModel: ExampleViewModel

    init(viewModel: ExampleViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Text(viewModel.title)
            .task { await viewModel.onAppear() }
    }
}
```

Rules:
- Break large bodies into small `View` structs in `Components/`, not computed properties.
- Use `Button` for taps, `foregroundStyle`, `clipShape(.rect(cornerRadius:))`.
- No service, container or UserDefaults access.
- No `@MainActor`, the target already defaults to MainActor.
