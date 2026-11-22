import Domain
import Foundation
import GeneratedAPI

enum StatsMapping {
  static func mapStats(_ dto: Components.Schemas.StatsResponse) -> GroupStats {
    GroupStats(
      from: dto.from,
      to: dto.to,
      bucket: StatsBucket(code: dto.bucket.rawValue),
      total: Money(Int64(dto.total)),
      byCategory: dto.byCategory.map { entry in
        CategoryStat(
          category: mapBuiltinCategory(entry.category?.rawValue),
          categoryId: entry.categoryId.map(GroupCategory.ID.init),
          amount: Money(Int64(entry.amount))
        )
      },
      byMember: dto.byMember.map { entry in
        MemberStat(
          memberId: Member.ID(entry.memberId),
          paid: Money(Int64(entry.paid)),
          share: Money(Int64(entry.share))
        )
      },
      byBucket: dto.byBucket.map { entry in
        TimeBucketStat(
          start: entry.start,
          amount: Money(Int64(entry.amount))
        )
      }
    )
  }

  private static func mapBuiltinCategory(_ raw: String?) -> TransactionCategory? {
    guard let raw, !raw.isEmpty else { return nil }
    return TransactionCategory(code: raw)
  }

  private struct RawCategoryStat: Decodable {
    let category: String?
    let categoryId: String?
    let amount: Int64
  }

  private struct RawMemberStat: Decodable {
    let memberId: String
    let paid: Int64
    let share: Int64
  }

  private struct RawTimeBucketStat: Decodable {
    let start: String
    let amount: Int64
  }

  private struct RawStatsResponse: Decodable {
    let from: String
    let to: String
    let bucket: String
    let total: Int64
    let byCategory: [RawCategoryStat]
    let byMember: [RawMemberStat]
    let byBucket: [RawTimeBucketStat]
  }

  static func decodeResilientStats(from data: Data) throws -> GroupStats {
    let raw = try JSONDecoder().decode(RawStatsResponse.self, from: data)
    return GroupStats(
      from: raw.from,
      to: raw.to,
      bucket: StatsBucket(code: raw.bucket),
      total: Money(raw.total),
      byCategory: raw.byCategory.map { entry in
        CategoryStat(
          category: mapBuiltinCategory(entry.category),
          categoryId: entry.categoryId.map(GroupCategory.ID.init),
          amount: Money(entry.amount)
        )
      },
      byMember: raw.byMember.map { entry in
        MemberStat(
          memberId: Member.ID(entry.memberId),
          paid: Money(entry.paid),
          share: Money(entry.share)
        )
      },
      byBucket: raw.byBucket.map { entry in
        TimeBucketStat(start: entry.start, amount: Money(entry.amount))
      }
    )
  }
}
