import SwiftUI

struct OnboardingPager: View {
  @Bindable var app: AppState
  private var selection: Binding<Int> {
    Binding(
      get: {
        if case .onboarding(let index) = app.page { return index }
        return 0
      },
      set: { index in
        guard case .onboarding = app.page else { return }
        app.page = .onboarding(index)
      })
  }
  var body: some View {
    TabView(selection: selection) {
      ForEach(0..<3) { index in
        OnboardingView(app: app, index: index).tag(index)
          .accessibilityHidden(index != selection.wrappedValue)
      }
    }.tabViewStyle(.page(indexDisplayMode: .never))
      .ignoresSafeArea()
      .animation(.easeInOut(duration: 0.25), value: selection.wrappedValue)
      .accessibilityIdentifier("onboardingPager")
  }
}
