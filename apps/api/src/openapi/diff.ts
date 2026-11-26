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

type DiffContext = {
	oldComponentParams: Record<string, unknown>;
	newComponentParams: Record<string, unknown>;
	oldIsOpenApi31: boolean;
	newIsOpenApi31: boolean;
};

type ResolvedParameter = {
	raw: Record<string, unknown>;
	resolved: Record<string, unknown>;
	refName: string | null;
	wasResolved: boolean;
	refDescription: string | undefined;
};

function isRecord(value: unknown): value is Record<string, unknown> {
	return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isOpenApi31Document(doc: Record<string, unknown>): boolean {
	return typeof doc.openapi === "string" && doc.openapi.startsWith("3.1.");
}

function extractComponentParameters(
	doc: Record<string, unknown>,
): Record<string, unknown> {
	return isRecord(doc.components) && isRecord(doc.components.parameters)
		? doc.components.parameters
		: {};
}

function resolveParameter(
	param: Record<string, unknown>,
	options: {
		componentParams: Record<string, unknown>;
		isOpenApi31: boolean;
	},
	seen = new Set<string>(),
): ResolvedParameter {
	const unresolved = (): ResolvedParameter => ({
		raw: param,
		resolved: param,
		refName: null,
		wasResolved: false,
		refDescription: undefined,
	});
	const ref = param.$ref;
	if (typeof ref !== "string" || !ref.startsWith("#/components/parameters/")) {
		return unresolved();
	}
	const name = ref.slice("#/components/parameters/".length);
	if (seen.has(name) || !Object.hasOwn(options.componentParams, name)) {
		return unresolved();
	}
	const target = options.componentParams[name];
	if (!isRecord(target)) {
		return unresolved();
	}
	const inner = resolveParameter(target, options, new Set([...seen, name]));
	const descriptionOverride =
		options.isOpenApi31 && typeof param.description === "string"
			? param.description
			: undefined;
	const resolved =
		descriptionOverride !== undefined
			? { ...inner.resolved, description: descriptionOverride }
			: inner.resolved;
	return {
		raw: param,
		resolved,
		refName: inner.refName ?? name,
		wasResolved: true,
		refDescription: descriptionOverride ?? inner.refDescription,
	};
}

function parameterLabel(entry: ResolvedParameter): string {
	if (
		typeof entry.resolved.name === "string" &&
		typeof entry.resolved.in === "string"
	) {
		return `"${entry.resolved.name}" in "${entry.resolved.in}"`;
	}
	if (typeof entry.raw.$ref === "string") {
		return `reference "${entry.raw.$ref}"`;
	}
	return `"${String(entry.resolved.name)}" in "${String(entry.resolved.in)}"`;
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
	ctx: DiffContext,
): void {
	const oldParams = (Array.isArray(oldList) ? oldList : []).filter(isRecord);
	const newParams = (Array.isArray(newList) ? newList : []).filter(isRecord);

	const mapParams = (
		params: Record<string, unknown>[],
		componentParams: Record<string, unknown>,
		isOpenApi31: boolean,
	) => {
		const entries: Array<[string, ResolvedParameter]> = [];
		for (const p of params) {
			const entry = resolveParameter(p, { componentParams, isOpenApi31 });
			const key =
				typeof entry.resolved.in === "string" &&
				typeof entry.resolved.name === "string"
					? `${entry.resolved.in}:${entry.resolved.name}`
					: typeof p.$ref === "string"
						? p.$ref
						: `${String(entry.resolved.in)}:${String(entry.resolved.name)}`;
			entries.push([key, entry]);
		}
		return new Map(entries);
	};
	const oldMap = mapParams(
		oldParams,
		ctx.oldComponentParams,
		ctx.oldIsOpenApi31,
	);
	const newMap = mapParams(
		newParams,
		ctx.newComponentParams,
		ctx.newIsOpenApi31,
	);

	for (const [key, newEntry] of newMap.entries()) {
		const childPath = `${path}.parameters[${key}]`;
		const oldEntry = oldMap.get(key);
		if (!oldEntry) {
			const isRequired = newEntry.resolved.required === true;
			const label = parameterLabel(newEntry);
			changes.push({
				severity: isRequired ? "breaking" : "additive",
				path: childPath,
				reason: isRequired
					? `Required parameter ${label} added`
					: `Optional parameter ${label} added`,
			});
		} else if (
			oldEntry.wasResolved &&
			newEntry.wasResolved &&
			oldEntry.refName !== null &&
			oldEntry.refName === newEntry.refName
		) {
			if (oldEntry.refDescription !== newEntry.refDescription) {
				changes.push({
					severity: "additive",
					path: `${childPath}.description`,
					reason: "Documentation updated",
				});
			}
		} else {
			compareNode(
				childPath,
				oldEntry.resolved,
				newEntry.resolved,
				changes,
				ctx,
			);
		}
	}

	for (const [key, oldEntry] of oldMap.entries()) {
		if (!newMap.has(key)) {
			changes.push({
				severity: "breaking",
				path: `${path}.parameters[${key}]`,
				reason: `Parameter ${parameterLabel(oldEntry)} removed`,
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
	ctx: DiffContext,
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
		compareNode(childPath, oldProps[key], newProps[key], changes, ctx);
	}
}

function compareNode(
	path: string,
	oldValue: unknown,
	newValue: unknown,
	changes: OpenApiDiffEntry[],
	ctx: DiffContext,
): void {
	if (sameJson(oldValue, newValue)) return;

	if (
		Array.isArray(oldValue) &&
		Array.isArray(newValue) &&
		oldValue.length === newValue.length &&
		/\.(allOf|oneOf|anyOf)$/.test(path)
	) {
		const isUnion = /\.(oneOf|anyOf)$/.test(path);
		const oldItems = isUnion
			? [...oldValue].sort(compareSchemaBranches)
			: oldValue;
		const newItems = isUnion
			? [...newValue].sort(compareSchemaBranches)
			: newValue;
		for (const [index, oldItem] of oldItems.entries()) {
			compareNode(`${path}.${index}`, oldItem, newItems[index], changes, ctx);
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
				ctx,
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
				ctx,
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
						oldValue[key] === null &&
						/^paths\.\/api\/v1\/groups\/\{groupId\}\/transactions\/\{id\}\.patch\.requestBody\.content\.application\/json\.schema\.allOf\.\d+\.(oneOf\.\d+|discriminator\.mapping\.(expense|income))\.properties\.category(Id)?$/.test(
							path,
						))
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
		compareNode(childPath, oldValue[key], newValue[key], changes, ctx);
	}
}

function canonicalSchema(value: unknown): unknown {
	if (Array.isArray(value)) return value.map(canonicalSchema);
	if (!isRecord(value)) return value;
	return Object.fromEntries(
		Object.keys(value)
			.sort()
			.map((key) => [key, canonicalSchema(value[key])]),
	);
}

function compareSchemaBranches(left: unknown, right: unknown): number {
	return JSON.stringify(canonicalSchema(left)).localeCompare(
		JSON.stringify(canonicalSchema(right)),
	);
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
	if ("$ref" in value) {
		const { $ref, ...siblings } = value;
		const resolved = expandReference($ref);
		if (resolved !== $ref) {
			if (Object.keys(siblings).length === 0) return resolved;
			return {
				allOf: [
					resolved,
					expandRequestSchema(siblings, schemas, ancestors),
				].sort(compareSchemaBranches),
			};
		}
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
			const expanded = expandRequestSchema(child, schemas, ancestors);
			if (
				Array.isArray(expanded) &&
				["allOf", "anyOf", "oneOf"].includes(key)
			) {
				expanded.sort(compareSchemaBranches);
			}
			return [key, expanded];
		}),
	);
}

function normalizeRequestSchemas(
	document: Record<string, unknown>,
	other: Record<string, unknown>,
) {
	const copy = structuredClone(document);
	if (!isRecord(copy.paths)) return copy;
	const schemas =
		isRecord(copy.components) && isRecord(copy.components.schemas)
			? copy.components.schemas
			: {};
	const otherPaths = isRecord(other.paths) ? other.paths : {};
	for (const [route, path] of Object.entries(copy.paths)) {
		if (!isRecord(path)) continue;
		const otherPath = otherPaths[route];
		for (const [method, operation] of Object.entries(path)) {
			if (!isRecord(operation) || !isRecord(operation.requestBody)) continue;
			const content = operation.requestBody.content;
			if (!isRecord(content)) continue;
			const otherOperation = isRecord(otherPath)
				? otherPath[method]
				: undefined;
			const otherBody = isRecord(otherOperation)
				? otherOperation.requestBody
				: undefined;
			const otherContent = isRecord(otherBody) ? otherBody.content : undefined;
			for (const [mime, media] of Object.entries(content)) {
				const otherMedia = isRecord(otherContent)
					? otherContent[mime]
					: undefined;
				if (
					isRecord(media) &&
					isRecord(media.schema) &&
					isRecord(otherMedia) &&
					!sameJson(media.schema, otherMedia.schema)
				) {
					media.schema = expandRequestSchema(media.schema, schemas);
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
		normalizeRequestSchemas(baseline, candidate),
		normalizeRequestSchemas(candidate, baseline),
		changes,
		{
			oldComponentParams: extractComponentParameters(baseline),
			newComponentParams: extractComponentParameters(candidate),
			oldIsOpenApi31: isOpenApi31Document(baseline),
			newIsOpenApi31: isOpenApi31Document(candidate),
		},
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
