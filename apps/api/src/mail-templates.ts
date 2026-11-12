export function verificationMail(name: string, link: string) {
	return {
		subject: "Xác minh email của bạn",
		text: `Chào ${name},\n\nBấm vào link dưới đây để xác minh email cho tài khoản Sòng Phẳng. Link có hiệu lực trong 24 giờ.\n\n${link}\n\nNếu bạn không đăng ký, hãy bỏ qua thư này.`,
	};
}
export function accountExistsMail(link: string) {
	return {
		subject: "Bạn đã có tài khoản Sòng Phẳng",
		text: `Có người vừa dùng email này để đăng ký. Bạn đã có tài khoản; hãy đăng nhập, hoặc đặt lại mật khẩu nếu quên.\n\n${link}`,
	};
}
export function resetPasswordMail(link: string) {
	return {
		subject: "Đặt lại mật khẩu Sòng Phẳng",
		text: `Bấm vào link dưới đây để đặt mật khẩu mới. Link có hiệu lực trong 1 giờ và chỉ dùng được một lần.\n\n${link}\n\nNếu bạn không yêu cầu, hãy bỏ qua thư này.`,
	};
}
