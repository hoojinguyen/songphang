# 08 — Quick-entry sample sentences

Updated: 2026-11-12. Status: draft, approved together with the phase 1 plan.

This is the list FR-1.100 requires: sentences for the rule-based reader, each with the result it must produce, including sentences that must be refused. It is the measuring stick for stage 1D: every sentence is run through `POST …/transactions/parse` and compared with its row.

## 1. Reading rules

The rules restate FR-1.91–1.99 with the choices needed to make them unambiguous.

**Text.** The sentence is normalized to Unicode NFC; `spans` index UTF-16 code units of that text. Matching ignores letter case and Vietnamese diacritics (`đ` matches `d`). The description keeps the original letters.

**Amount token.** One of: digits followed by `k`; digits in groups of three separated by dots (`300.000`, `1.200.000`); plain digits with a value of at least 1000; digits followed by `nghìn` or `ngàn`; digits followed by `tr` or `triệu`, optionally with a decimal part written `1,2tr`, `1.2tr`, `1.2 triệu`, or with trailing digits `1tr2` (1.200.000), `1tr25` (1.250.000). A space between number and unit is allowed. A value of 0 or above 999.999.999.999 is not an amount. A bare number below 1000 is not an amount token.

**Total.** The first amount token in the sentence.

**Description.** The text before the total, without a payer phrase, trimmed, inner spaces collapsed, trailing punctuation removed. Missing → issue `DESCRIPTION_MISSING` (`needs_input`).

**Payer.** `<name> trả`, anywhere in the sentence, at most once. `mình`, `tôi`, `tớ` mean the writer's member. No payer phrase → the writer's member.

**Names.** At a name position the reader first tries the longest run of words equal to a member's whole name; otherwise one word equal to any word of a member's name. Only active members match. One match → that member. Several → `MEMBER_AMBIGUOUS` with the candidates (`needs_input`). None → `MEMBER_UNKNOWN` (`unparsed`). The accented word `mình` is always the writer; unaccented `minh` means the writer and also matches members with the word "Minh" in their name; if those are different people the word is ambiguous.

**Equal split.** Nothing, or `chia đều`: all active members. `chia <N>`: all active members when N equals their number; fewer → `COUNT_MISMATCH` (`needs_input`, the card asks for exactly N people); more → `COUNT_MISMATCH` (`unparsed`). `chia <name>, <name>…` (separated by commas, spaces or `và`): equally among those members.

**Personal parts.** After the total, a run of `<name> <number>` pairs. A number is an amount token, or a bare number: below 1000 it means thousands of đồng, otherwise đồng. With `còn lại chia đều` the unassigned part is split equally among the named members (`exact` with `equal_among_all`). Without it the parts must sum to the total (`exact` with `none`); otherwise `SUM_MISMATCH` (`unparsed`). Parts above the total are `SUM_MISMATCH` in both cases.

**Everything else.** After the total, any text that no rule consumed (other than `, . ; :`) is `TEXT_NOT_UNDERSTOOD` (`unparsed`): an unmatched word followed by `trả` or by a number, or inside a `chia` list, is reported as `MEMBER_UNKNOWN` instead. A `chia` phrase together with personal parts, a second payer phrase, or a member named twice in the parts is `TEXT_NOT_UNDERSTOOD`.

**Status.** Any `unparsed` issue → `unparsed`. Otherwise any `needs_input` issue → `needs_input`. Otherwise `ok`. The reader never chooses for the user.

## 2. Groups used

| Group | Members in position order | Writer |
|---|---|---|
| A | Minh, Lan, Hùng, Thu — all active | Minh |
| B | Minh Anh, Minh Đức, Lan — all active | Lan |
| C | Minh, Lan, Hùng, Thu — Thu inactive | Minh |

In the tables, "all" means every active member, and amounts are đồng in position order. The payer is the writer unless stated.

## 3. Group A — must be read (`ok`)

| # | Sentence | Description | Total | Payer | Shares |
|---|---|---|---|---|---|
| A01 | `cà phê 180k chia 4` | cà phê | 180000 | Minh | all: 45000 each |
| A02 | `cà phê 180K` | cà phê | 180000 | Minh | all: 45000 each |
| A03 | `ăn sáng 300.000` | ăn sáng | 300000 | Minh | all: 75000 each |
| A04 | `xăng 300000` | xăng | 300000 | Minh | all: 75000 each |
| A05 | `trà sữa 300 nghìn` | trà sữa | 300000 | Minh | all: 75000 each |
| A06 | `trà sữa 300 ngàn chia đều` | trà sữa | 300000 | Minh | all: 75000 each |
| A07 | `khách sạn 1tr` | khách sạn | 1000000 | Minh | all: 250000 each |
| A08 | `khách sạn 1tr2` | khách sạn | 1200000 | Minh | all: 300000 each |
| A09 | `vé máy bay 1,2tr` | vé máy bay | 1200000 | Minh | all: 300000 each |
| A10 | `vé tàu 1.2 triệu` | vé tàu | 1200000 | Minh | all: 300000 each |
| A11 | `quà 1tr5 chia đều` | quà | 1500000 | Minh | all: 375000 each |
| A12 | `vé 1.5tr` | vé | 1500000 | Minh | all: 375000 each |
| A13 | `vé 2 triệu` | vé | 2000000 | Minh | all: 500000 each |
| A14 | `ăn 1.200.000` | ăn | 1200000 | Minh | all: 300000 each |
| A15 | `cà phê 99k` | cà phê | 99000 | Minh | all: 24750 each |
| A16 | `nước 10k` | nước | 10000 | Minh | all: 2500 each |
| A17 | `bánh 1.000` | bánh | 1000 | Minh | all: 250 each |
| A18 | `kẹo 1001` | kẹo | 1001 | Minh | 251, 250, 250, 250 |
| A19 | `phòng 2 đêm 1tr6` | phòng 2 đêm | 1600000 | Minh | all: 400000 each |
| A20 | `bia 333 100k` | bia 333 | 100000 | Minh | all: 25000 each |
| A21 | `  cà phê    180k  ` | cà phê | 180000 | Minh | all: 45000 each |
| A22 | `Vé Cáp Treo 800K THU TRẢ` | Vé Cáp Treo | 800000 | Thu | all: 200000 each |
| A23 | `taxi 250k lan trả` | taxi | 250000 | Lan | all: 62500 each |
| A24 | `taxi 250k, Lan trả` | taxi | 250000 | Lan | all: 62500 each |
| A25 | `lan trả taxi 250k` | taxi | 250000 | Lan | all: 62500 each |
| A26 | `bún chả 200k mình trả` | bún chả | 200000 | Minh | all: 50000 each |
| A27 | `bún chả 200k tôi trả` | bún chả | 200000 | Minh | all: 50000 each |
| A28 | `bún chả 200k tớ trả` | bún chả | 200000 | Minh | all: 50000 each |
| A29 | `vé xem phim 400k hung tra` | vé xem phim | 400000 | Hùng | all: 100000 each |
| A30 | `cà phê 180k chia 4 lan trả` | cà phê | 180000 | Lan | all: 45000 each |
| A31 | `nước 100k chia lan, hùng, thu` | nước | 100000 | Minh | Lan 33334, Hùng 33333, Thu 33333 |
| A32 | `ăn trưa 240k chia mình, lan` | ăn trưa | 240000 | Minh | Minh 120000, Lan 120000 |
| A33 | `ăn trưa 240k chia mình và lan` | ăn trưa | 240000 | Minh | Minh 120000, Lan 120000 |
| A34 | `grab 45k mình trả chia lan, hùng` | grab | 45000 | Minh | Lan 22500, Hùng 22500 |
| A35 | `ăn vặt 50k chia thu` | ăn vặt | 50000 | Minh | Thu 50000 |
| A36 | `lẩu 300k, mình trả. mình 80 lan 60 hùng 40, còn lại chia đều` | lẩu | 300000 | Minh | Minh 120000, Lan 100000, Hùng 80000 |
| A37 | `lẩu 300k mình 120 lan 100 hùng 80` | lẩu | 300000 | Minh | Minh 120000, Lan 100000, Hùng 80000 |
| A38 | `lẩu 300k minh 120k lan 100k hung 80k` | lẩu | 300000 | Minh | Minh 120000, Lan 100000, Hùng 80000 |
| A39 | `lẩu 300k mình 100 lan 100, còn lại chia đều` | lẩu | 300000 | Minh | Minh 150000, Lan 150000 |
| A40 | `nhậu 1tr lan 300 hùng 300 thu 400` | nhậu | 1000000 | Minh | Lan 300000, Hùng 300000, Thu 400000 |
| A41 | `nhậu 1tr mình 250.000 lan 250.000 hùng 250.000 thu 250.000` | nhậu | 1000000 | Minh | all: 250000 each |
| A42 | `bia 100k mình 33 lan 33, còn lại chia đều` | bia | 100000 | Minh | Minh 50000, Lan 50000 |
| A43 | `kem 100k lan 10 hùng 10 thu 10, còn lại chia đều` | kem | 100000 | Minh | Lan 33334, Hùng 33333, Thu 33333 |
| A44 | `chợ 500k thu trả, lan 200 thu 300` | chợ | 500000 | Thu | Lan 200000, Thu 300000 |
| A45 | `đồ ăn 250k lan 1500 hùng 248500` | đồ ăn | 250000 | Minh | Lan 1500, Hùng 248500 |

Split stored for A36: `{ "method": "exact", "members": [Minh, Lan, Hùng], "entries": [80000, 60000, 40000], "remainder": "equal_among_all" }`. For A37: the same members with entries 120000, 100000, 80000 and `"remainder": "none"`. For A31: `{ "method": "equal", "members": [Lan, Hùng, Thu] }`.

Spans for A36, which fix the convention: `description` 0–3, `amount` 4–8, `payer` 10–18, `exact` 20–42, `remainder` 44–60. For A01: `description` 0–6, `amount` 7–11, `equal` 12–18.

## 4. Group A — must ask (`needs_input`)

`draft` holds everything understood; `shares` is absent.

| # | Sentence | Issue | Draft |
|---|---|---|---|
| A46 | `cà phê 180k chia 3` | `COUNT_MISMATCH`, count 3, candidates all four | cà phê, 180000, payer Minh, no split |
| A47 | `cà phê 180k chia 2` | `COUNT_MISMATCH`, count 2, candidates all four | cà phê, 180000, payer Minh, no split |
| A48 | `180k` | `DESCRIPTION_MISSING` | no description, 180000, payer Minh, equal among all |
| A49 | `180k lan trả` | `DESCRIPTION_MISSING` | no description, 180000, payer Lan, equal among all |

## 5. Group A — must be refused (`unparsed`)

The listed issue must be present; others may accompany it. Nothing is ever saved.

| # | Sentence | Issue |
|---|---|---|
| A50 | `cà phê` | `AMOUNT_MISSING` |
| A51 | `cà phê 180` | `AMOUNT_MISSING` |
| A52 | `cà phê 0k` | `AMOUNT_MISSING` |
| A53 | `lẩu 300k minh 80 lan 60 hùng 40` | `SUM_MISMATCH`, expected 300000, actual 180000 |
| A54 | `lẩu 300k mình 200 lan 200, còn lại chia đều` | `SUM_MISMATCH`, expected 300000, actual 400000 |
| A55 | `lẩu 300k nam trả` | `MEMBER_UNKNOWN` on `nam` |
| A56 | `lẩu 300k nam 100 lan 200` | `MEMBER_UNKNOWN` on `nam` |
| A57 | `cà phê 180k chia 5` | `COUNT_MISMATCH`, count 5 |
| A58 | `lẩu 300k chia 3 mình 100 lan 200` | `TEXT_NOT_UNDERSTOOD` |
| A59 | `cà phê 180k hôm qua` | `TEXT_NOT_UNDERSTOOD` on `hôm qua` |
| A60 | `cà phê 180k và bánh 50k` | `MEMBER_UNKNOWN` on `bánh` |
| A61 | `lẩu 300k lan 100 lan 200` | `TEXT_NOT_UNDERSTOOD` |
| A62 | `lẩu 300k lan trả hùng trả` | `TEXT_NOT_UNDERSTOOD` |
| A63 | `lẩu 300k chia lan, nam` | `MEMBER_UNKNOWN` on `nam` |

For A53 the draft still holds: lẩu, 300000, payer Minh, exact entries Minh 80000, Lan 60000, Hùng 40000.

## 6. Group B — names that collide (writer: Lan)

| # | Sentence | Status | Result |
|---|---|---|---|
| B01 | `phở 150k mình trả` | `ok` | payer Lan; all: 50000 each |
| B02 | `phở 150k minh trả` | `needs_input` | `MEMBER_AMBIGUOUS` on `minh`; candidates Minh Anh, Minh Đức, Lan |
| B03 | `phở 150k minh anh trả` | `ok` | payer Minh Anh; all: 50000 each |
| B04 | `phở 150k Minh Đức trả` | `ok` | payer Minh Đức; all: 50000 each |
| B05 | `phở 150k anh trả` | `ok` | payer Minh Anh; all: 50000 each |
| B06 | `phở 150k chia minh, lan` | `needs_input` | `MEMBER_AMBIGUOUS` on `minh` |
| B07 | `phở 150k minh duc 100 lan 50` | `ok` | payer Lan; Minh Đức 100000, Lan 50000 |
| B08 | `phở 150k duc 100 mình 50` | `ok` | payer Lan; Minh Đức 100000, Lan 50000 |

## 7. Group C — an inactive member (Thu)

| # | Sentence | Status | Result |
|---|---|---|---|
| C01 | `cà phê 180k` | `ok` | Minh, Lan, Hùng: 60000 each |
| C02 | `cà phê 180k chia 3` | `ok` | Minh, Lan, Hùng: 60000 each |
| C03 | `cà phê 180k chia 4` | `unparsed` | `COUNT_MISMATCH`, count 4 |
| C04 | `cà phê 180k thu trả` | `unparsed` | `MEMBER_UNKNOWN` on `thu` |

## 8. Outside the reader

A sentence longer than 300 characters is refused by the API with 400 `VALIDATION_FAILED` before the reader runs. Transfers, income, dates, categories and several payers cannot be typed; they belong to the form.


## 9. Phase 2 fund samples — approved 2026-11-17

These rows are fixed advisor inputs, calculated independently before reader implementation. The preceding 75 samples are unchanged.

Group F: active people Minh, Lan, Hùng in that position order; active fund named Quỹ chung in position 3; writer Minh. Group N: the same three people without a fund. Group Q: group F plus active person Quy in position 4; writer Minh. Shares always refer to people, never the fund. A fund alias in a payer position is `quỹ` or `quy`; the fund's full name is also accepted. Refused rows must contain the listed issue and must never be saved.

| # | Group | Sentence | Status | Independently calculated expected result |
|---|---|---|---|---|
| F01 | F | `ăn tối 300k quỹ trả` | ok | description ăn tối; total 300000; payer fund; Minh 100000, Lan 100000, Hùng 100000 |
| F02 | F | `an toi 300k quy tra` | ok | description an toi; total 300000; payer fund; Minh 100000, Lan 100000, Hùng 100000 |
| F03 | F | `từ quỹ cà phê 100k` | ok | description cà phê; total 100000; payer fund; Minh 33334, Lan 33333, Hùng 33333 |
| F04 | F | `tu quy ca phe 100k` | ok | description ca phe; total 100000; payer fund; Minh 33334, Lan 33333, Hùng 33333 |
| F05 | F | `vé 1001 quỹ chung trả` | ok | description vé; total 1001; payer fund; Minh 334, Lan 334, Hùng 333 |
| F06 | F | `ăn 90k quỹ trả chia lan, hùng` | ok | description ăn; total 90000; payer fund; Lan 45000, Hùng 45000 |
| F07 | F | `ăn 300k quỹ trả chia 3` | ok | description ăn; total 300000; payer fund; Minh 100000, Lan 100000, Hùng 100000 |
| F08 | F | `ăn 300k quỹ trả chia 4` | unparsed | COUNT_MISMATCH, count 4, three active people |
| F09 | N | `ăn 300k quỹ trả` | unparsed | MEMBER_UNKNOWN on quỹ |
| F10 | F | `ăn 300k chia quỹ` | unparsed | FUND_CANNOT_SHARE on quỹ |
| F11 | F | `ăn 300k quỹ 100 lan 200` | unparsed | FUND_CANNOT_SHARE on quỹ |
| F12 | Q | `ăn 300k quy tra` | needs_input | MEMBER_AMBIGUOUS on quy; candidates fund and person Quy; no payer chosen |

Arithmetic: 300000 = 3 × 100000; 100000 = 33334 + 33333 + 33333; 1001 = 334 + 334 + 333; 90000 = 45000 + 45000. Ties receive extra đồng in person position order. Sample F11's entered parts sum to 300000 but are refused because a fund cannot bear a share.
