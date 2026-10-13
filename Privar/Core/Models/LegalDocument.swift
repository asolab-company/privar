import Foundation

enum LegalDocument: String {
  case privacy, terms
  var title: String { self == .privacy ? "Privacy Policy" : "Terms of Use" }
  var configurationKey: String { self == .privacy ? "PrivarPrivacyURL" : "PrivarTermsURL" }
  var url: URL? {
    guard let value = Bundle.main.object(forInfoDictionaryKey: configurationKey) as? String,
      let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
      url.scheme?.lowercased() == "https", let host = url.host, !host.isEmpty
    else { return nil }
    return url
  }
}
