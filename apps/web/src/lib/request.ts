export function jsonRequest(
	method: "POST" | "PATCH" | "DELETE",
	body?: unknown,
	idempotencyKey?: string,
): RequestInit {
	return {
		method,
		headers: {
			...(body === undefined ? {} : { "Content-Type": "application/json" }),
			...(idempotencyKey === undefined
				? {}
				: { "Idempotency-Key": idempotencyKey }),
		},
		...(body === undefined ? {} : { body: JSON.stringify(body) }),
	};
}
