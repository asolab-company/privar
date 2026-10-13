import SwiftUI

struct PaywallView: View {
  @Bindable var app: AppState

  var body: some View {
    OnboardingView(app: app, index: 3)
  }
}
