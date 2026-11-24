// Keep this list aligned with packages/core/src/banks.ts.
enum PaymentBanks {
  struct Entry: Hashable, Identifiable {
    var id: String { bin }
    let bin: String
    let shortName: String
    let fullName: String
  }

  static let entries: [Entry] = [
    Entry(bin: "970415", shortName: "VietinBank", fullName: "Ngân hàng TMCP Công thương Việt Nam"),
    Entry(
      bin: "970436", shortName: "Vietcombank", fullName: "Ngân hàng TMCP Ngoại Thương Việt Nam"),
    Entry(
      bin: "970418", shortName: "BIDV", fullName: "Ngân hàng TMCP Đầu tư và Phát triển Việt Nam"),
    Entry(
      bin: "970405", shortName: "Agribank",
      fullName: "Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam"),
    Entry(bin: "970448", shortName: "OCB", fullName: "Ngân hàng TMCP Phương Đông"),
    Entry(bin: "970422", shortName: "MBBank", fullName: "Ngân hàng TMCP Quân đội"),
    Entry(bin: "970407", shortName: "Techcombank", fullName: "Ngân hàng TMCP Kỹ thương Việt Nam"),
    Entry(bin: "970416", shortName: "ACB", fullName: "Ngân hàng TMCP Á Châu"),
    Entry(bin: "970432", shortName: "VPBank", fullName: "Ngân hàng TMCP Việt Nam Thịnh Vượng"),
    Entry(bin: "970423", shortName: "TPBank", fullName: "Ngân hàng TMCP Tiên Phong"),
    Entry(bin: "970403", shortName: "Sacombank", fullName: "Ngân hàng TMCP Sài Gòn Tài Lộc"),
    Entry(
      bin: "970437", shortName: "HDBank",
      fullName: "Ngân hàng TMCP Phát triển Thành phố Hồ Chí Minh"),
    Entry(bin: "970454", shortName: "VietCapitalBank", fullName: "Ngân hàng TMCP Bản Việt"),
    Entry(bin: "970429", shortName: "SCB", fullName: "Ngân hàng TMCP Sài Gòn"),
    Entry(bin: "970441", shortName: "VIB", fullName: "Ngân hàng TMCP Quốc tế Việt Nam"),
    Entry(bin: "970443", shortName: "SHB", fullName: "Ngân hàng TMCP Sài Gòn - Hà Nội"),
    Entry(
      bin: "970431", shortName: "Eximbank", fullName: "Ngân hàng TMCP Xuất Nhập khẩu Việt Nam"),
    Entry(bin: "970426", shortName: "MSB", fullName: "Ngân hàng TMCP Hàng Hải"),
    Entry(
      bin: "546034", shortName: "CAKE",
      fullName: "TMCP Việt Nam Thịnh Vượng - Ngân hàng số CAKE by VPBank"),
    Entry(
      bin: "546035", shortName: "Ubank",
      fullName: "TMCP Việt Nam Thịnh Vượng - Ngân hàng số Ubank by VPBank"),
    Entry(bin: "963388", shortName: "Timo", fullName: "Ngân hàng số Timo by Ban Viet Bank"),
    Entry(bin: "971005", shortName: "ViettelMoney", fullName: "Tổng Công ty Dịch vụ số Viettel"),
    Entry(bin: "971011", shortName: "VNPTMoney", fullName: "Trung tâm dịch vụ tài chính số VNPT"),
    Entry(bin: "970400", shortName: "SaigonBank", fullName: "Ngân hàng TMCP Sài Gòn Công Thương"),
    Entry(bin: "970409", shortName: "BacABank", fullName: "Ngân hàng TMCP Bắc Á"),
    Entry(bin: "971133", shortName: "PVcomBank Pay", fullName: "Ngân hàng số PVcomBank"),
    Entry(bin: "971025", shortName: "MoMo", fullName: "CTCP Dịch Vụ Di Động Trực Tuyến"),
    Entry(bin: "970412", shortName: "PVcomBank", fullName: "Ngân hàng TMCP Đại Chúng Việt Nam"),
    Entry(bin: "970414", shortName: "MBV", fullName: "Ngân hàng TNHH MTV Việt Nam Hiện Đại"),
    Entry(bin: "970419", shortName: "NCB", fullName: "Ngân hàng TMCP Quốc Dân"),
    Entry(bin: "970424", shortName: "ShinhanBank", fullName: "Ngân hàng TNHH MTV Shinhan Việt Nam"),
    Entry(bin: "970425", shortName: "ABBANK", fullName: "Ngân hàng TMCP An Bình"),
    Entry(bin: "970427", shortName: "VietABank", fullName: "Ngân hàng TMCP Việt Á"),
    Entry(bin: "970428", shortName: "NamABank", fullName: "Ngân hàng TMCP Nam Á"),
    Entry(
      bin: "970430", shortName: "PGBank", fullName: "Ngân hàng TMCP Thịnh vượng và Phát triển"),
    Entry(bin: "970433", shortName: "VietBank", fullName: "Ngân hàng TMCP Việt Nam Thương Tín"),
    Entry(bin: "970438", shortName: "BaoVietBank", fullName: "Ngân hàng TMCP Bảo Việt"),
    Entry(bin: "970440", shortName: "SeABank", fullName: "Ngân hàng TMCP Đông Nam Á"),
    Entry(bin: "970446", shortName: "COOPBANK", fullName: "Ngân hàng Hợp tác xã Việt Nam"),
    Entry(bin: "970449", shortName: "LPBank", fullName: "Ngân hàng TMCP Lộc Phát Việt Nam"),
    Entry(bin: "970452", shortName: "KienLongBank", fullName: "Ngân hàng TMCP Kiên Long"),
    Entry(bin: "668888", shortName: "KBank", fullName: "Ngân hàng Đại chúng TNHH Kasikornbank"),
    Entry(bin: "970466", shortName: "KEBHanaHCM", fullName: "Ngân hàng KEB Hana - TP.HCM"),
    Entry(bin: "970467", shortName: "KEBHANAHN", fullName: "Ngân hàng KEB Hana - Hà Nội"),
    Entry(bin: "977777", shortName: "MAFC", fullName: "Công ty Tài chính Mirae Asset Việt Nam"),
    Entry(bin: "999888", shortName: "VBSP", fullName: "Ngân hàng Chính sách Xã hội"),
    Entry(bin: "963668", shortName: "BNP HN", fullName: "Ngân hàng BNP Paribas - Hà Nội"),
    Entry(bin: "555666", shortName: "BIDC", fullName: "Ngân hàng BIDC - Chi nhánh Hà Nội"),
    Entry(bin: "963666", shortName: "BNP HCM", fullName: "Ngân hàng BNP Paribas - TP.HCM"),
    Entry(bin: "971101", shortName: "ZaloPay", fullName: "Ví điện tử ZaloPay"),
    Entry(bin: "963688", shortName: "BOCHK", fullName: "Bank of China (Hong Kong) - TP.HCM"),
    Entry(bin: "970465", shortName: "BSP", fullName: "Ngân hàng SinoPac - TP.HCM"),
    Entry(bin: "168999", shortName: "CUBHCM", fullName: "Cathay United Bank - TP.HCM"),
    Entry(bin: "963686", shortName: "ESUN", fullName: "Ngân hàng E.SUN - Đồng Nai"),
    Entry(bin: "963669", shortName: "ICBC", fullName: "Ngân hàng Công thương Trung Quốc - Hà Nội"),
    Entry(bin: "971032", shortName: "MVAS", fullName: "Trung tâm Dịch vụ số Mobifone"),
    Entry(bin: "963326", shortName: "TNEX", fullName: "TNEX by MSB"),
    Entry(bin: "458761", shortName: "HSBC", fullName: "Ngân hàng TNHH MTV HSBC Việt Nam"),
    Entry(bin: "970442", shortName: "HongLeong", fullName: "Ngân hàng Hong Leong Việt Nam"),
    Entry(bin: "970455", shortName: "IBKHN", fullName: "Industrial Bank of Korea - Hà Nội"),
    Entry(bin: "970456", shortName: "IBKHCM", fullName: "Industrial Bank of Korea - TP.HCM"),
    Entry(bin: "970434", shortName: "IndovinaBank", fullName: "Ngân hàng TNHH Indovina"),
    Entry(bin: "970406", shortName: "Vikki", fullName: "Ngân hàng số Vikki"),
    Entry(bin: "801011", shortName: "Nonghyup", fullName: "Ngân hàng Nonghyup - Hà Nội"),
    Entry(bin: "796500", shortName: "DBSBank", fullName: "DBS Bank Ltd - TP.HCM"),
    Entry(bin: "970439", shortName: "PublicBank", fullName: "Ngân hàng TNHH MTV Public Việt Nam"),
    Entry(bin: "970410", shortName: "StandardChartered", fullName: "Standard Chartered Việt Nam"),
    Entry(bin: "533948", shortName: "Citibank", fullName: "Ngân hàng Citibank - Hà Nội"),
    Entry(bin: "422589", shortName: "CIMB", fullName: "Ngân hàng TNHH MTV CIMB Việt Nam"),
    Entry(bin: "970458", shortName: "UnitedOverseas", fullName: "United Overseas Bank - TP.HCM"),
    Entry(bin: "970444", shortName: "CBBank", fullName: "Ngân hàng CBBank / VCBNeo"),
    Entry(bin: "970408", shortName: "GPBank", fullName: "Ngân hàng Dầu Khí Toàn Cầu"),
    Entry(bin: "970421", shortName: "VRB", fullName: "Ngân hàng Liên doanh Việt - Nga"),
    Entry(bin: "970457", shortName: "Woori", fullName: "Ngân hàng TNHH MTV Woori Việt Nam"),
    Entry(bin: "970462", shortName: "KookminHN", fullName: "Ngân hàng Kookmin - Hà Nội"),
    Entry(bin: "970463", shortName: "KookminHCM", fullName: "Ngân hàng Kookmin - TP.HCM"),
  ]
}
