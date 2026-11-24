import Domain
import Foundation
import GeneratedAPI

enum CategoryMapping {
  static func mapCategory(_ dto: Components.Schemas.CategoryDto) -> GroupCategory {
    GroupCategory(
      id: GroupCategory.ID(dto.id),
      name: dto.name,
      color: MemberColor(code: dto.color.rawValue),
      archived: dto.archived
    )
  }

  static func encodeCreateColor(
    _ color: MemberColor
  ) -> Components.Schemas.CreateCategoryRequest.colorPayload {
    switch color {
    case .mint: return .mint
    case .sky: return .sky
    case .coral: return .coral
    case .lilac: return .lilac
    case .unknown: return .mint
    }
  }

  static func encodeUpdateColor(
    _ color: MemberColor
  ) -> Components.Schemas.UpdateCategoryRequest.colorPayload {
    switch color {
    case .mint: return .mint
    case .sky: return .sky
    case .coral: return .coral
    case .lilac: return .lilac
    case .unknown: return .mint
    }
  }

  struct RawCategory: Codable, Sendable {
    let id: String
    let name: String
    let color: String
    let archived: Bool

    init(_ category: GroupCategory) {
      self.id = category.id.rawValue
      self.name = category.name
      self.color = category.color.code
      self.archived = category.archived
    }

    func toDomain() -> GroupCategory {
      GroupCategory(
        id: GroupCategory.ID(id),
        name: name,
        color: MemberColor(code: color),
        archived: archived
      )
    }
  }

  private struct RawCategoryListEnvelope: Decodable {
    let categories: [RawCategory]
  }

  static func decodeResilientList(from data: Data) throws -> [GroupCategory] {
    let decoded = try JSONDecoder().decode(RawCategoryListEnvelope.self, from: data)
    return decoded.categories.map { $0.toDomain() }
  }

  static func decodeResilientSingle(from data: Data) throws -> GroupCategory {
    struct Envelope: Decodable { let category: RawCategory }
    return try JSONDecoder().decode(Envelope.self, from: data).category.toDomain()
  }

  static func encodeSnapshot(_ categories: [GroupCategory]) -> Data? {
    try? JSONEncoder().encode(categories.map(RawCategory.init))
  }

  static func decodeSnapshot(from data: Data) throws -> [GroupCategory] {
    try JSONDecoder().decode([RawCategory].self, from: data).map { $0.toDomain() }
  }
}
