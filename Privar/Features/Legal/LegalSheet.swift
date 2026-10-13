import SwiftUI
import WebKit

struct LegalSheet: View {
  let document: LegalDocument
  @Environment(\.dismiss) private var dismiss
  @State private var loading = true
  @State private var failed = false
  @State private var request = UUID()
  var body: some View {
    NavigationStack {
      Group {
        if let url = document.url {
          LegalWebPage(url: url, request: request, loading: $loading, failed: $failed)
            .overlay {
              if failed {
                ContentUnavailableView {
                  Label("Unable to Load Document", systemImage: "wifi.exclamationmark")
                } description: {
                  Text("Check your connection and try again.")
                } actions: {
                  Button("Try Again") { request = UUID() }.buttonStyle(.borderedProminent)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.background)
              } else if loading {
                ProgressView("Loading…").padding(24)
                  .background(.regularMaterial, in: .rect(cornerRadius: 16))
              }
            }
        } else {
          ContentUnavailableView(
            document.title, systemImage: "doc.text",
            description: Text("This document is not available yet."))
        }
      }
      .navigationTitle(document.title).navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Close") { dismiss() } } }
    }
    .tint(Theme.green).preferredColorScheme(.dark)
    .presentationDetents([.large]).presentationDragIndicator(.visible)
  }
}
private struct LegalWebPage: UIViewRepresentable {
  let url: URL
  let request: UUID
  @Binding var loading: Bool
  @Binding var failed: Bool
  func makeCoordinator() -> Coordinator { Coordinator(loading: $loading, failed: $failed) }
  func makeUIView(context: Context) -> WKWebView {
    let view = WKWebView()
    view.navigationDelegate = context.coordinator
    view.uiDelegate = context.coordinator
    view.allowsBackForwardNavigationGestures = true
    return view
  }
  func updateUIView(_ view: WKWebView, context: Context) {
    guard context.coordinator.request != request else { return }
    context.coordinator.request = request
    view.load(URLRequest(url: url))
  }
  static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
    view.stopLoading()
    view.navigationDelegate = nil
    view.uiDelegate = nil
  }
  final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var request: UUID?
    @Binding var loading: Bool
    @Binding var failed: Bool
    init(loading: Binding<Bool>, failed: Binding<Bool>) {
      _loading = loading
      _failed = failed
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
      loading = true
      failed = false
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loading = false }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      finish(error)
    }
    func webView(
      _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      finish(error)
    }
    private func finish(_ error: Error) {
      guard (error as NSError).code != NSURLErrorCancelled else { return }
      loading = false
      failed = true
    }
    func webView(
      _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
      for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
      if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
      return nil
    }
  }
}
