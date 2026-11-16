#if DEBUG
  public import Domain

  public nonisolated enum QuickEntryFixtures {
    private static let minhId = TripScenario.minhId
    private static let lanId = TripScenario.lanId
    private static let hungId = TripScenario.hungId
    private static let thuId = TripScenario.thuId
    private static let allFour = [minhId, lanId, hungId, thuId]

    // Transcribed from fixtures/29-parse-1.json through 44-parse-10.json
    public static let readingsByText: [String: QuickEntryReading] = [
      // 29-parse-1.json & 30-parse-1-preview.json
      "cà phê 180k chia 4": QuickEntryReading(
        status: .ok,
        text: "cà phê 180k chia 4",
        draft: QuickEntryReading.Draft(
          description: "cà phê",
          amount: Money(180_000),
          payers: [MemberAmount(memberId: minhId, amount: Money(180_000))],
          split: .equal(members: allFour)
        ),
        shares: [
          MemberAmount(memberId: minhId, amount: Money(45_000)),
          MemberAmount(memberId: lanId, amount: Money(45_000)),
          MemberAmount(memberId: hungId, amount: Money(45_000)),
          MemberAmount(memberId: thuId, amount: Money(45_000)),
        ],
        spans: [
          QuickEntryReading.Span(start: 0, end: 6, kind: .description),
          QuickEntryReading.Span(start: 7, end: 11, kind: .amount),
          QuickEntryReading.Span(start: 12, end: 18, kind: .equal),
        ],
        issues: []
      ),
      // 31-parse-2.json & 32-parse-2-preview.json
      "taxi 250k lan trả": QuickEntryReading(
        status: .ok,
        text: "taxi 250k lan trả",
        draft: QuickEntryReading.Draft(
          description: "taxi",
          amount: Money(250_000),
          payers: [MemberAmount(memberId: lanId, amount: Money(250_000))],
          split: .equal(members: allFour)
        ),
        shares: [
          MemberAmount(memberId: minhId, amount: Money(62_500)),
          MemberAmount(memberId: lanId, amount: Money(62_500)),
          MemberAmount(memberId: hungId, amount: Money(62_500)),
          MemberAmount(memberId: thuId, amount: Money(62_500)),
        ],
        spans: [
          QuickEntryReading.Span(start: 0, end: 4, kind: .description),
          QuickEntryReading.Span(start: 5, end: 9, kind: .amount),
          QuickEntryReading.Span(start: 10, end: 17, kind: .payer),
        ],
        issues: []
      ),
      // 33-parse-3.json & 34-parse-3-preview.json
      "nước 100k chia lan, hùng, thu": QuickEntryReading(
        status: .ok,
        text: "nước 100k chia lan, hùng, thu",
        draft: QuickEntryReading.Draft(
          description: "nước",
          amount: Money(100_000),
          payers: [MemberAmount(memberId: minhId, amount: Money(100_000))],
          split: .equal(members: [lanId, hungId, thuId])
        ),
        shares: [
          MemberAmount(memberId: lanId, amount: Money(33_334)),
          MemberAmount(memberId: hungId, amount: Money(33_333)),
          MemberAmount(memberId: thuId, amount: Money(33_333)),
        ],
        spans: [
          QuickEntryReading.Span(start: 0, end: 4, kind: .description),
          QuickEntryReading.Span(start: 5, end: 9, kind: .amount),
          QuickEntryReading.Span(start: 10, end: 29, kind: .equal),
        ],
        issues: []
      ),
      // 35-parse-4.json & 36-parse-4-preview.json
      "lẩu 300k, mình trả. mình 80 lan 60 hùng 40, còn lại chia đều": QuickEntryReading(
        status: .ok,
        text: "lẩu 300k, mình trả. mình 80 lan 60 hùng 40, còn lại chia đều",
        draft: QuickEntryReading.Draft(
          description: "lẩu",
          amount: Money(300_000),
          payers: [MemberAmount(memberId: minhId, amount: Money(300_000))],
          split: .exact(
            members: [minhId, lanId, hungId],
            entries: [
              SplitSpec.ExactEntry(memberId: minhId, amount: Money(80_000)),
              SplitSpec.ExactEntry(memberId: lanId, amount: Money(60_000)),
              SplitSpec.ExactEntry(memberId: hungId, amount: Money(40_000)),
            ],
            remainder: .equalAmongAll
          )
        ),
        shares: [
          MemberAmount(memberId: minhId, amount: Money(120_000)),
          MemberAmount(memberId: lanId, amount: Money(100_000)),
          MemberAmount(memberId: hungId, amount: Money(80_000)),
        ],
        spans: [
          QuickEntryReading.Span(start: 0, end: 3, kind: .description),
          QuickEntryReading.Span(start: 4, end: 8, kind: .amount),
          QuickEntryReading.Span(start: 10, end: 18, kind: .payer),
          QuickEntryReading.Span(start: 20, end: 42, kind: .exact),
          QuickEntryReading.Span(start: 44, end: 60, kind: .remainder),
        ],
        issues: []
      ),
      // 37-parse-5.json & 38-parse-5-preview.json
      "kẹo 1001": QuickEntryReading(
        status: .ok,
        text: "kẹo 1001",
        draft: QuickEntryReading.Draft(
          description: "kẹo",
          amount: Money(1001),
          payers: [MemberAmount(memberId: minhId, amount: Money(1001))],
          split: .equal(members: allFour)
        ),
        shares: [
          MemberAmount(memberId: minhId, amount: Money(251)),
          MemberAmount(memberId: lanId, amount: Money(250)),
          MemberAmount(memberId: hungId, amount: Money(250)),
          MemberAmount(memberId: thuId, amount: Money(250)),
        ],
        spans: [
          QuickEntryReading.Span(start: 0, end: 3, kind: .description),
          QuickEntryReading.Span(start: 4, end: 8, kind: .amount),
        ],
        issues: []
      ),
      // 39-parse-6.json & 40-parse-6-preview.json
      "chợ 500k thu trả, lan 200 thu 300": QuickEntryReading(
        status: .ok,
        text: "chợ 500k thu trả, lan 200 thu 300",
        draft: QuickEntryReading.Draft(
          description: "chợ",
          amount: Money(500_000),
          payers: [MemberAmount(memberId: thuId, amount: Money(500_000))],
          split: .exact(
            members: [lanId, thuId],
            entries: [
              SplitSpec.ExactEntry(memberId: lanId, amount: Money(200_000)),
              SplitSpec.ExactEntry(memberId: thuId, amount: Money(300_000)),
            ],
            remainder: .none
          )
        ),
        shares: [
          MemberAmount(memberId: lanId, amount: Money(200_000)),
          MemberAmount(memberId: thuId, amount: Money(300_000)),
        ],
        spans: [
          QuickEntryReading.Span(start: 0, end: 3, kind: .description),
          QuickEntryReading.Span(start: 4, end: 8, kind: .amount),
          QuickEntryReading.Span(start: 9, end: 16, kind: .payer),
          QuickEntryReading.Span(start: 18, end: 33, kind: .exact),
        ],
        issues: []
      ),
      // 41-parse-7.json
      "cà phê 180k chia 3": QuickEntryReading(
        status: .needsInput,
        text: "cà phê 180k chia 3",
        draft: QuickEntryReading.Draft(
          description: "cà phê",
          amount: Money(180_000),
          payers: [MemberAmount(memberId: minhId, amount: Money(180_000))],
          split: nil
        ),
        shares: nil,
        spans: [
          QuickEntryReading.Span(start: 0, end: 6, kind: .description),
          QuickEntryReading.Span(start: 7, end: 11, kind: .amount),
          QuickEntryReading.Span(start: 12, end: 18, kind: .equal),
        ],
        issues: [
          QuickEntryReading.Issue(
            code: .countMismatch,
            start: 12,
            end: 18,
            candidates: allFour,
            count: 3
          )
        ]
      ),
      // 42-parse-8.json
      "180k": QuickEntryReading(
        status: .needsInput,
        text: "180k",
        draft: QuickEntryReading.Draft(
          description: nil,
          amount: Money(180_000),
          payers: [MemberAmount(memberId: minhId, amount: Money(180_000))],
          split: .equal(members: allFour)
        ),
        shares: [
          MemberAmount(memberId: minhId, amount: Money(45_000)),
          MemberAmount(memberId: lanId, amount: Money(45_000)),
          MemberAmount(memberId: hungId, amount: Money(45_000)),
          MemberAmount(memberId: thuId, amount: Money(45_000)),
        ],
        spans: [
          QuickEntryReading.Span(start: 0, end: 4, kind: .amount)
        ],
        issues: [
          QuickEntryReading.Issue(
            code: .descriptionMissing,
            start: 0,
            end: 0,
            candidates: []
          )
        ]
      ),
      // 43-parse-9.json
      "cà phê": QuickEntryReading(
        status: .unparsed,
        text: "cà phê",
        draft: QuickEntryReading.Draft(
          description: "cà phê",
          amount: nil,
          payers: [],
          split: .equal(members: allFour)
        ),
        shares: nil,
        spans: [
          QuickEntryReading.Span(start: 0, end: 6, kind: .description)
        ],
        issues: [
          QuickEntryReading.Issue(
            code: .amountMissing,
            start: 0,
            end: 6,
            candidates: []
          )
        ]
      ),
      // 44-parse-10.json
      "cà phê 180k chia 9": QuickEntryReading(
        status: .unparsed,
        text: "cà phê 180k chia 9",
        draft: QuickEntryReading.Draft(
          description: "cà phê",
          amount: Money(180_000),
          payers: [MemberAmount(memberId: minhId, amount: Money(180_000))],
          split: nil
        ),
        shares: nil,
        spans: [
          QuickEntryReading.Span(start: 0, end: 6, kind: .description),
          QuickEntryReading.Span(start: 7, end: 11, kind: .amount),
          QuickEntryReading.Span(start: 12, end: 18, kind: .equal),
        ],
        issues: [
          QuickEntryReading.Issue(
            code: .countMismatch,
            start: 12,
            end: 18,
            candidates: allFour,
            count: 9
          )
        ]
      ),
    ]

    public static func unparsedReading(for text: String) -> QuickEntryReading {
      QuickEntryReading(
        status: .unparsed,
        text: text,
        draft: QuickEntryReading.Draft(
          description: text,
          amount: nil,
          payers: [],
          split: .equal(members: allFour)
        ),
        shares: nil,
        spans: [
          QuickEntryReading.Span(start: 0, end: text.count, kind: .description)
        ],
        issues: [
          QuickEntryReading.Issue(
            code: .amountMissing,
            start: 0,
            end: text.count,
            candidates: []
          )
        ]
      )
    }
  }
#endif
