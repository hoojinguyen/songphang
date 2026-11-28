#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WEB_STRINGS="$ROOT_DIR/apps/web/src/messages/vi.ts"
IOS_CATALOG="$ROOT_DIR/apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings"
RUNS_DIR="$ROOT_DIR/docs/superpowers/runs"

node - "$WEB_STRINGS" "$IOS_CATALOG" "$RUNS_DIR" <<'EOF'
const fs = require("fs");
const path = require("path");
const [webPath, catalogPath, runsDir] = process.argv.slice(2);

const src = fs.readFileSync(webPath, "utf8");
const objCode = src
  .replace(/^export const vi = /, "")
  .replace(/ as const;[\s\S]*$/, "");
const vi = eval("(" + objCode + ")");

function flatten(obj, prefix = "", out = {}) {
  for (const [k, v] of Object.entries(obj)) {
    const key = prefix ? `${prefix}.${k}` : k;
    if (Array.isArray(v)) {
      v.forEach((item, idx) => {
        out[`${key}.${idx}`] = item;
      });
    } else if (v && typeof v === "object") {
      flatten(v, key, out);
    } else {
      out[key] = v;
    }
  }
  return out;
}

function unquoteCell(raw) {
  const trimmed = raw.trim();
  if (trimmed.startsWith("`") && trimmed.endsWith("`") && trimmed.length >= 2) {
    return trimmed.slice(1, -1);
  }
  return trimmed;
}

function splitMarkdownCells(line) {
  let trimmed = line.trim();
  if (trimmed.startsWith("|")) trimmed = trimmed.slice(1);
  if (trimmed.endsWith("|") && !trimmed.endsWith("\\|")) trimmed = trimmed.slice(0, -1);
  const cells = [];
  let current = "";
  for (let i = 0; i < trimmed.length; i++) {
    const ch = trimmed[i];
    if (ch === "\\" && i + 1 < trimmed.length && trimmed[i + 1] === "|") {
      current += "|";
      i++;
    } else if (ch === "|") {
      cells.push(current);
      current = "";
    } else {
      current += ch;
    }
  }
  cells.push(current);
  return cells;
}

function loadCopyChangesAllowlist(dir) {
  const allowlist = new Map();
  const conflicts = [];
  if (!fs.existsSync(dir)) return { allowlist, conflicts };
  const runDirs = fs
    .readdirSync(dir, { withFileTypes: true })
    .filter((d) => d.isDirectory() && d.name.startsWith("phase-5-"))
    .map((d) => d.name)
    .sort();
  for (const runName of runDirs) {
    const filePath = path.join(dir, runName, "copy-changes.md");
    if (!fs.existsSync(filePath)) continue;
    const source = path.join(runName, "copy-changes.md");
    const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith("|")) continue;
      const cells = splitMarkdownCells(trimmed);
      if (cells.length < 4) continue;
      const key = unquoteCell(cells[0]);
      const oldValue = unquoteCell(cells[1]);
      const newValue = unquoteCell(cells[2]);
      if (!key || key === "Key" || /^-+$/.test(key)) continue;
      const isAdded = oldValue === "(added)";
      const isRemoved = newValue === "(removed)";
      if (allowlist.has(key)) {
        const prev = allowlist.get(key);
        conflicts.push({ key, prevSource: prev.source, nextSource: source });
        continue;
      }
      allowlist.set(key, { oldValue, newValue, isAdded, isRemoved, source });
    }
  }
  return { allowlist, conflicts };
}

const webFlat = flatten(vi);
const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8"));
const catalogStrings = catalog.strings || {};
const { allowlist, conflicts } = loadCopyChangesAllowlist(runsDir);

let failures = 0;
let allowed = 0;

for (const c of conflicts) {
  console.log(`CONFLICTING_COPY_CHANGE: ${c.key} (${c.prevSource} vs ${c.nextSource})`);
  failures++;
}

for (const [key, webValue] of Object.entries(webFlat)) {
  const hasEntry = Object.prototype.hasOwnProperty.call(catalogStrings, key);
  const entry = hasEntry ? catalogStrings[key] : undefined;
  const iosValue =
    entry &&
    entry.localizations &&
    entry.localizations.vi &&
    entry.localizations.vi.stringUnit &&
    entry.localizations.vi.stringUnit.value;

  if (!hasEntry) {
    const allowedChange = allowlist.get(key);
    if (allowedChange && allowedChange.isRemoved && allowedChange.oldValue === webValue) {
      console.log(`ALLOWED (copy-changes): ${key} (removed) [${allowedChange.source}]`);
      allowed++;
    } else if (allowedChange && allowedChange.isRemoved) {
      console.log(`OLD_VALUE_MISMATCH: ${key} (web=${JSON.stringify(webValue)}, copy-changes=${JSON.stringify(allowedChange.oldValue)})`);
      failures++;
    } else {
      console.log(`MISSING: ${key}`);
      failures++;
    }
  } else if (iosValue === undefined) {
    console.log(`MISSING_VI: ${key}`);
    failures++;
  } else if (iosValue !== webValue) {
    const allowedChange = allowlist.get(key);
    if (
      allowedChange &&
      !allowedChange.isRemoved &&
      !allowedChange.isAdded &&
      allowedChange.oldValue === webValue &&
      allowedChange.newValue === iosValue
    ) {
      console.log(`ALLOWED (copy-changes): ${key} [${allowedChange.source}]`);
      allowed++;
    } else if (allowedChange && !allowedChange.isRemoved && allowedChange.newValue === iosValue) {
      console.log(`OLD_VALUE_MISMATCH: ${key} (web=${JSON.stringify(webValue)}, copy-changes=${JSON.stringify(allowedChange.oldValue)})`);
      failures++;
    } else {
      console.log(`DIFFERING: ${key}`);
      console.log(`  web: ${JSON.stringify(webValue)}`);
      console.log(`  ios: ${JSON.stringify(iosValue)}`);
      failures++;
    }
  }
}

for (const [key, entry] of Object.entries(catalogStrings)) {
  if (key.startsWith("ios.")) continue;
  if (!(key in webFlat)) {
    const iosValue =
      entry &&
      entry.localizations &&
      entry.localizations.vi &&
      entry.localizations.vi.stringUnit &&
      entry.localizations.vi.stringUnit.value;
    const allowedChange = allowlist.get(key);
    if (
      allowedChange &&
      allowedChange.isAdded &&
      !allowedChange.isRemoved &&
      allowedChange.newValue === iosValue
    ) {
      console.log(`ALLOWED (copy-changes): ${key} [${allowedChange.source}]`);
      allowed++;
    } else {
      console.log(`EXTRA: ${key}`);
      failures++;
    }
  }
}

for (const [key, allowedChange] of allowlist.entries()) {
  if (!key.startsWith("ios.")) continue;
  const hasEntry = Object.prototype.hasOwnProperty.call(catalogStrings, key);
  const entry = hasEntry ? catalogStrings[key] : undefined;
  const iosValue =
    entry &&
    entry.localizations &&
    entry.localizations.vi &&
    entry.localizations.vi.stringUnit &&
    entry.localizations.vi.stringUnit.value;

  if (allowedChange.isRemoved) {
    if (hasEntry) {
      console.log(`IOS_KEY_NOT_REMOVED: ${key} [${allowedChange.source}]`);
      failures++;
    } else {
      console.log(`ALLOWED (copy-changes): ${key} (removed) [${allowedChange.source}]`);
      allowed++;
    }
  } else if (!hasEntry || iosValue === undefined) {
    console.log(`IOS_KEY_MISSING: ${key} [${allowedChange.source}]`);
    failures++;
  } else if (iosValue !== allowedChange.newValue) {
    console.log(`IOS_KEY_DIFFERING: ${key} [${allowedChange.source}]`);
    console.log(`  copy-changes: ${JSON.stringify(allowedChange.newValue)}`);
    console.log(`  ios: ${JSON.stringify(iosValue)}`);
    failures++;
  }
}

if (failures > 0) {
  console.log(
    `FAILED: ${Object.keys(webFlat).length} web keys checked, ${allowed} allowlisted, ${failures} failing.`
  );
  process.exit(1);
}
console.log(
  `OK: ${Object.keys(webFlat).length} web keys verified, ${allowed} allowlisted via copy-changes.md, 0 missing, 0 differing.`
);
EOF
