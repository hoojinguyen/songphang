import { BANKS } from "./banks.ts";
import { foldVietnamese } from "./quick-entry/normalize.ts";

export function findBank(bin: string) {
	return BANKS.find((bank) => bank.bin === bin);
}

export function crc16CcittFalse(text: string): string {
	let crc = 0xffff;
	for (const character of text) {
		const byte = character.charCodeAt(0);
		if (byte > 0x7f) throw new RangeError("CRC input must be ASCII");
		crc ^= byte << 8;
		for (let bit = 0; bit < 8; bit++)
			crc = ((crc << 1) ^ ((crc & 0x8000) !== 0 ? 0x1021 : 0)) & 0xffff;
	}
	return crc.toString(16).toUpperCase().padStart(4, "0");
}

function plainName(name: string): string {
	return Array.from(name, (character) => {
		const folded = foldVietnamese(character);
		return character === character.toLocaleUpperCase("vi")
			? folded.toUpperCase()
			: folded;
	}).join("");
}

export function transferPurpose(fromName: string, toName: string): string {
	return `SP ${plainName(fromName)} tra ${plainName(toName)}`
		.replace(/[^A-Za-z0-9 ]/g, "")
		.replace(/ +/g, " ")
		.slice(0, 25)
		.trimEnd();
}

export function groupTransferPurpose(groupName: string): string {
	const cleaned = plainName(groupName)
		.replace(/[^A-Za-z0-9 ]/g, "")
		.replace(/ +/g, " ")
		.trim();
	if (cleaned.length === 0) return "SP Thanh toan";
	const purpose = `SP ${cleaned}`.slice(0, 25).trimEnd();
	return purpose.length > 2 ? purpose : "SP Thanh toan";
}

function field(id: string, value: string): string {
	if (value.length > 99) throw new RangeError("QR field is too long");
	return `${id}${String(value.length).padStart(2, "0")}${value}`;
}

function isValidPurpose(purpose: string): boolean {
	return (
		purpose.length >= 1 &&
		purpose.length <= 25 &&
		/^[\x20-\x7e]+$/.test(purpose)
	);
}

function buildQrPayloadCore(input: {
	pointOfInitiationMethod: "11" | "12";
	bankBin: string;
	accountNumber: string;
	amount?: number;
	purpose?: string;
}): string {
	if (
		!/^\d{6}$/.test(input.bankBin) ||
		!/^[A-Za-z0-9]{4,19}$/.test(input.accountNumber) ||
		(input.purpose !== undefined && !isValidPurpose(input.purpose)) ||
		(input.amount !== undefined &&
			(!Number.isSafeInteger(input.amount) ||
				input.amount < 1 ||
				input.amount > 999_999_999_999))
	) {
		throw new RangeError("Invalid VietQR input");
	}
	const account = field("00", input.bankBin) + field("01", input.accountNumber);
	const merchant =
		field("00", "A000000727") + field("01", account) + field("02", "QRIBFTTA");
	const payload =
		field("00", "01") +
		field("01", input.pointOfInitiationMethod) +
		field("38", merchant) +
		field("53", "704") +
		(input.amount !== undefined ? field("54", String(input.amount)) : "") +
		field("58", "VN") +
		(input.purpose !== undefined
			? field("62", field("08", input.purpose))
			: "") +
		"6304";
	return payload + crc16CcittFalse(payload);
}

export function buildVietQrPayload(input: {
	bankBin: string;
	accountNumber: string;
	amount: number;
	purpose: string;
}): string {
	return buildQrPayloadCore({
		pointOfInitiationMethod: "12",
		bankBin: input.bankBin,
		accountNumber: input.accountNumber,
		amount: input.amount,
		purpose: input.purpose,
	});
}

export function buildStaticVietQrPayload(input: {
	bankBin: string;
	accountNumber: string;
	purpose?: string;
}): string {
	return buildQrPayloadCore({
		pointOfInitiationMethod: "11",
		bankBin: input.bankBin,
		accountNumber: input.accountNumber,
		...(input.purpose !== undefined ? { purpose: input.purpose } : {}),
	});
}
