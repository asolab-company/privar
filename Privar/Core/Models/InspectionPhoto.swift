import CoreGraphics
import Foundation

struct InspectionPhoto: Identifiable, Codable {
  let id: UUID
  let filename: String
  let createdAt: Date
  let candidate: CGRect?
}
