(() => {
	try {
		const stored = window.localStorage.getItem("sp-theme");
		document.documentElement.dataset.theme =
			stored === "light" || stored === "dark" || stored === "system"
				? stored
				: "system";
	} catch {
		document.documentElement.dataset.theme = "system";
	}
})();
