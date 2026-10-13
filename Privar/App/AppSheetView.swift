import SwiftUI

struct AppSheetView: View {
  let sheet: AppState.Sheet
  var body: some View {
    switch sheet {
    case .legal(let document): LegalSheet(document: document)
    case .share(let url): ShareSheet(url: url)
    }
  }
}
