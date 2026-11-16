export function foldVietnamese(text: string): string {
	return Array.from(text)
		.map((character) => {
			const folded = character
				.toLocaleLowerCase("vi")
				.normalize("NFD")
				.replace(/\p{M}/gu, "")
				.replace(/đ/g, "d");
			return folded.length === character.length ? folded : character;
		})
		.join("");
}
