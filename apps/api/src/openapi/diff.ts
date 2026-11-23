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
	if (!Array.isArray(oldList)) {
		if (Array.isArray(newList)) {
			changes.push({
				severity: "breaking",
				path: `${path}.enum`,
				reason: "Added enum constraint to unconstrained schema",
			});
		}
		return;
	}
	const oldItems = Array.isArray(oldList) ? oldList : [];
	if (!Array.isArray(newList)) {
		changes.push({
			severity: "additive",
			path: `${path}.enum`,
			reason: "Removed enum constraint from schema",
		});
		return;
	}
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

function compareParameterList(
	path: string,
	oldList: unknown,
	newList: unknown,
	changes: OpenApiDiffEntry[],
): void {
	const oldParams = (Array.isArray(oldList) ? oldList : []).filter(isRecord);
	const newParams = (Array.isArray(newList) ? newList : []).filter(isRecord);

	const paramKey = (p: Record<string, unknown>) =>
		typeof p.$ref === "string" ? p.$ref : `${String(p.in)}:${String(p.name)}`;
	const oldMap = new Map(oldParams.map((p) => [paramKey(p), p]));
	const newMap = new Map(newParams.map((p) => [paramKey(p), p]));

	for (const [key, newP] of newMap.entries()) {
		const childPath = `${path}.parameters[${key}]`;
		const oldP = oldMap.get(key);
		if (!oldP) {
			const isRequired = newP.required === true;
			changes.push({
				severity: isRequired ? "breaking" : "additive",
				path: childPath,
				reason: isRequired
					? `Required parameter "${String(newP.name)}" in "${String(newP.in)}" added`
					: `Optional parameter "${String(newP.name)}" in "${String(newP.in)}" added`,
			});
		} else {
			compareNode(childPath, oldP, newP, changes);
		}
	}

	for (const [key, oldP] of oldMap.entries()) {
		if (!newMap.has(key)) {
			changes.push({
				severity: "breaking",
				path: `${path}.parameters[${key}]`,
				reason: `Parameter "${String(oldP.name)}" in "${String(oldP.in)}" removed`,
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

	if (
		/\.requestBody\.content\..+\.schema\./.test(path) &&
		Array.isArray(oldValue) &&
		Array.isArray(newValue) &&
		oldValue.length === newValue.length &&
		/\.(allOf|oneOf|anyOf)$/.test(path)
	) {
		for (const [index, oldItem] of oldValue.entries()) {
			compareNode(`${path}.${index}`, oldItem, newValue[index], changes);
		}
		return;
	}

	if (!isRecord(oldValue) || !isRecord(newValue)) {
		const isMetadata =
			path.endsWith(".description") ||
			path.endsWith(".summary") ||
			path.endsWith(".example") ||
			path.startsWith("info.");
		if (path.endsWith(".required") && oldValue === true && newValue === false) {
			changes.push({
				severity: "additive",
				path,
				reason: "Required constraint relaxed to optional",
			});
			return;
		}
		if (typeof oldValue === "number" && typeof newValue === "number") {
			if (
				path.endsWith(".minLength") ||
				path.endsWith(".minItems") ||
				path.endsWith(".minProperties") ||
				path.endsWith(".minimum") ||
				path.endsWith(".exclusiveMinimum")
			) {
				const isNarrowing = newValue > oldValue;
				changes.push({
					severity: isNarrowing ? "breaking" : "additive",
					path,
					reason: isNarrowing
						? `Constraint tightened (${oldValue} -> ${newValue})`
						: `Constraint relaxed (${oldValue} -> ${newValue})`,
				});
				return;
			}
			if (
				path.endsWith(".maxLength") ||
				path.endsWith(".maxItems") ||
				path.endsWith(".maxProperties") ||
				path.endsWith(".maximum") ||
				path.endsWith(".exclusiveMaximum")
			) {
				const isNarrowing = newValue < oldValue;
				changes.push({
					severity: isNarrowing ? "breaking" : "additive",
					path,
					reason: isNarrowing
						? `Constraint tightened (${oldValue} -> ${newValue})`
						: `Constraint relaxed (${oldValue} -> ${newValue})`,
				});
				return;
			}
		}
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
			key === "parameters" &&
			(Array.isArray(oldValue.parameters) || Array.isArray(newValue.parameters))
		) {
			compareParameterList(
				path,
				oldValue.parameters,
				newValue.parameters,
				changes,
			);
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
			const isRemovedRequiredTrue =
				key === "required" && oldValue[key] === true;
			const isMetadata =
				key === "description" || key === "summary" || key === "example";
			changes.push({
				severity:
					isMetadata ||
					isRemovedRequiredTrue ||
					(key === "default" &&
						/\.requestBody\.content\..+\.schema\./.test(path))
						? "additive"
						: "breaking",
				path: childPath,
				reason: isRemovedRequiredTrue
					? `Required constraint removed from "${key}"`
					: `Removed "${key}"`,
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
				key === "exclusiveMinimum" ||
				key === "exclusiveMaximum" ||
				key === "multipleOf" ||
				key === "pattern" ||
				key === "minItems" ||
				key === "maxItems" ||
				key === "uniqueItems" ||
				key === "minProperties" ||
				key === "maxProperties" ||
				key === "const";
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

// Compare request schema structure independently of local component extraction.
function expandRequestSchema(
	value: unknown,
	schemas: Record<string, unknown>,
	ancestors = new Set<string>(),
): unknown {
	if (Array.isArray(value)) {
		return value.map((item) => expandRequestSchema(item, schemas, ancestors));
	}
	if (!isRecord(value)) return value;

	const expandReference = (ref: unknown): unknown => {
		if (typeof ref !== "string" || !ref.startsWith("#/components/schemas/"))
			return ref;
		const name = ref.slice("#/components/schemas/".length);
		if (!Object.hasOwn(schemas, name) || ancestors.has(name)) return ref;
		return expandRequestSchema(
			schemas[name],
			schemas,
			new Set([...ancestors, name]),
		);
	};
	if (Object.keys(value).length === 1 && "$ref" in value) {
		const resolved = expandReference(value.$ref);
		return resolved === value.$ref ? value : resolved;
	}

	return Object.fromEntries(
		Object.entries(value).map(([key, child]) => {
			if (
				key === "discriminator" &&
				isRecord(child) &&
				isRecord(child.mapping)
			) {
				return [
					key,
					{
						...child,
						mapping: Object.fromEntries(
							Object.entries(child.mapping).map(([tag, ref]) => [
								tag,
								expandReference(ref),
							]),
						),
					},
				];
			}
			return [key, expandRequestSchema(child, schemas, ancestors)];
		}),
	);
}

function normalizeRequestSchemas(document: Record<string, unknown>) {
	const copy = structuredClone(document);
	if (
		!isRecord(copy.paths) ||
		!isRecord(copy.components) ||
		!isRecord(copy.components.schemas)
	)
		return copy;
	for (const path of Object.values(copy.paths)) {
		if (!isRecord(path)) continue;
		for (const operation of Object.values(path)) {
			if (!isRecord(operation) || !isRecord(operation.requestBody)) continue;
			const content = operation.requestBody.content;
			if (!isRecord(content)) continue;
			for (const media of Object.values(content)) {
				if (isRecord(media) && isRecord(media.schema)) {
					media.schema = expandRequestSchema(
						media.schema,
						copy.components.schemas,
					);
				}
			}
		}
	}
	return copy;
}

export function diffOpenApiSnapshots(
	baseline: Record<string, unknown>,
	candidate: Record<string, unknown>,
): OpenApiDiffResult {
	const changes: OpenApiDiffEntry[] = [];
	compareNode(
		"",
		normalizeRequestSchemas(baseline),
		normalizeRequestSchemas(candidate),
		changes,
	);
	const breakingCount = changes.filter((c) => c.severity === "breaking").length;
	const additiveCount = changes.filter((c) => c.severity === "additive").length;
	return {
		identical: changes.length === 0,
		changes,
		breakingCount,
		additiveCount,
	};
}
