export type ChangeSeverity = "additive" | "breaking";

export type OpenApiDiffEntry = {
	severity: ChangeSeverity;
	path: string;
	reason: string;
};

export type OpenApiDiffResult = {
	identical: boolean;
	changes: OpenApiDiffEntry[];
	breakingCount: number;
	additiveCount: number;
};

function isRecord(value: unknown): value is Record<string, unknown> {
	return value !== null && typeof value === "object" && !Array.isArray(value);
}

function sameJson(a: unknown, b: unknown): boolean {
	return JSON.stringify(a) === JSON.stringify(b);
}

function compareRequiredList(
	path: string,
	oldList: unknown,
	newList: unknown,
	changes: OpenApiDiffEntry[],
): void {
	const oldSet = new Set(Array.isArray(oldList) ? oldList.map(String) : []);
	const newSet = new Set(Array.isArray(newList) ? newList.map(String) : []);
	for (const field of newSet) {
		if (!oldSet.has(field)) {
			changes.push({
				severity: "breaking",
				path: `${path}.required.${field}`,
				reason: `Field "${field}" became required`,
			});
		}
	}
	for (const field of oldSet) {
		if (!newSet.has(field)) {
			changes.push({
				severity: "additive",
				path: `${path}.required.${field}`,
				reason: `Field "${field}" is no longer required`,
			});
		}
	}
}

function compareEnumList(
	path: string,
	oldList: unknown,
	newList: unknown,
	changes: OpenApiDiffEntry[],
): void {
	const oldItems = Array.isArray(oldList) ? oldList : [];
	const newItems = Array.isArray(newList) ? newList : [];
	for (const item of oldItems) {
		if (!newItems.some((candidate) => sameJson(candidate, item))) {
			changes.push({
				severity: "breaking",
				path: `${path}.enum`,
				reason: `Enum value ${JSON.stringify(item)} removed`,
			});
		}
	}
	for (const item of newItems) {
		if (!oldItems.some((candidate) => sameJson(candidate, item))) {
			changes.push({
				severity: "additive",
				path: `${path}.enum`,
				reason: `Enum value ${JSON.stringify(item)} added`,
			});
		}
	}
}

function compareProperties(
	path: string,
	oldProps: Record<string, unknown>,
	newProps: Record<string, unknown>,
	newRequired: Set<string>,
	changes: OpenApiDiffEntry[],
): void {
	const keys = new Set([...Object.keys(oldProps), ...Object.keys(newProps)]);
	for (const key of [...keys].sort()) {
		const childPath = `${path}.properties.${key}`;
		if (!(key in newProps)) {
			changes.push({
				severity: "breaking",
				path: childPath,
				reason: `Property "${key}" removed`,
			});
			continue;
		}
		if (!(key in oldProps)) {
			const isReq = newRequired.has(key);
			changes.push({
				severity: isReq ? "breaking" : "additive",
				path: childPath,
				reason: isReq
					? `Required property "${key}" added`
					: `Optional property "${key}" added`,
			});
			continue;
		}
		compareNode(childPath, oldProps[key], newProps[key], changes);
	}
}

function compareNode(
	path: string,
	oldValue: unknown,
	newValue: unknown,
	changes: OpenApiDiffEntry[],
): void {
	if (sameJson(oldValue, newValue)) return;

	if (!isRecord(oldValue) || !isRecord(newValue)) {
		const isMetadata =
			path.endsWith(".description") ||
			path.endsWith(".summary") ||
			path.endsWith(".example") ||
			path.startsWith("info.");
		changes.push({
			severity: isMetadata ? "additive" : "breaking",
			path,
			reason: isMetadata ? "Documentation updated" : "Schema value changed",
		});
		return;
	}

	const keys = new Set([...Object.keys(oldValue), ...Object.keys(newValue)]);
	const newRequired = new Set(
		Array.isArray(newValue.required) ? newValue.required.map(String) : [],
	);

	for (const key of [...keys].sort()) {
		const childPath = path ? `${path}.${key}` : key;
		if (
			key === "required" &&
			(Array.isArray(oldValue.required) || Array.isArray(newValue.required))
		) {
			compareRequiredList(path, oldValue.required, newValue.required, changes);
			continue;
		}
		if (
			key === "enum" &&
			(Array.isArray(oldValue.enum) || Array.isArray(newValue.enum))
		) {
			compareEnumList(path, oldValue.enum, newValue.enum, changes);
			continue;
		}
		if (
			key === "properties" &&
			isRecord(oldValue.properties) &&
			isRecord(newValue.properties)
		) {
			compareProperties(
				path,
				oldValue.properties,
				newValue.properties,
				newRequired,
				changes,
			);
			continue;
		}
		if (!(key in newValue)) {
			const isMetadata =
				key === "description" || key === "summary" || key === "example";
			changes.push({
				severity: isMetadata ? "additive" : "breaking",
				path: childPath,
				reason: `Removed "${key}"`,
			});
			continue;
		}
		if (!(key in oldValue)) {
			const addedNode = newValue[key];
			const isRequiredRequestBody =
				key === "requestBody" &&
				isRecord(addedNode) &&
				addedNode.required === true;
			const isAddedRequiredTrue = key === "required" && addedNode === true;
			const isBreakingConstraint =
				key === "minLength" ||
				key === "maxLength" ||
				key === "minimum" ||
				key === "maximum" ||
				key === "pattern" ||
				key === "minItems" ||
				key === "maxItems";
			const isBreaking =
				isRequiredRequestBody || isAddedRequiredTrue || isBreakingConstraint;
			changes.push({
				severity: isBreaking ? "breaking" : "additive",
				path: childPath,
				reason:
					isRequiredRequestBody || isAddedRequiredTrue
						? `Added required "${key}"`
						: isBreakingConstraint
							? `Added stricter constraint "${key}"`
							: `Added "${key}"`,
			});
			continue;
		}
		compareNode(childPath, oldValue[key], newValue[key], changes);
	}
}

export function diffOpenApiSnapshots(
	baseline: Record<string, unknown>,
	candidate: Record<string, unknown>,
): OpenApiDiffResult {
	const changes: OpenApiDiffEntry[] = [];
	compareNode("", baseline, candidate, changes);
	const breakingCount = changes.filter((c) => c.severity === "breaking").length;
	const additiveCount = changes.filter((c) => c.severity === "additive").length;
	return {
		identical: changes.length === 0,
		changes,
		breakingCount,
		additiveCount,
	};
}
