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

function loadCopyChangesAllowlist(dir) {
  const allowlist = new Map();
  if (!fs.existsSync(dir)) return allowlist;
  const runDirs = fs
    .readdirSync(dir, { withFileTypes: true })
    .filter((d) => d.isDirectory() && d.name.startsWith("phase-5-"))
    .map((d) => d.name)
    .sort();
  for (const runName of runDirs) {
    const filePath = path.join(dir, runName, "copy-changes.md");
    if (!fs.existsSync(filePath)) continue;
    const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith("|")) continue;
      const cells = trimmed.split("|").slice(1, -1);
      if (cells.length < 3) continue;
      const key = unquoteCell(cells[0]);
      const oldValue = unquoteCell(cells[1]);
      const newValue = unquoteCell(cells[2]);
      if (!key || key === "Key" || /^-+$/.test(key)) continue;
      allowlist.set(key, { oldValue, newValue, source: path.join(runName, "copy-changes.md") });
    }
  }
  return allowlist;
}

const webFlat = flatten(vi);
const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8"));
const catalogStrings = catalog.strings || {};
const allowlist = loadCopyChangesAllowlist(runsDir);

let failures = 0;
let allowed = 0;

for (const [key, webValue] of Object.entries(webFlat)) {
  const entry = catalogStrings[key];
  const iosValue =
    entry &&
    entry.localizations &&
    entry.localizations.vi &&
    entry.localizations.vi.stringUnit &&
    entry.localizations.vi.stringUnit.value;

  if (iosValue === undefined) {
    const allowedChange = allowlist.get(key);
    if (allowedChange && allowedChange.newValue === "(removed)") {
      console.log(`ALLOWED (copy-changes): ${key} (removed)`);
      allowed++;
    } else {
      console.log(`MISSING: ${key}`);
      failures++;
    }
  } else if (iosValue !== webValue) {
    const allowedChange = allowlist.get(key);
    if (allowedChange && allowedChange.newValue === iosValue) {
      console.log(`ALLOWED (copy-changes): ${key}`);
      allowed++;
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
    if (allowedChange && allowedChange.newValue === iosValue) {
      console.log(`ALLOWED (copy-changes): ${key}`);
      allowed++;
    } else {
      console.log(`EXTRA: ${key}`);
      failures++;
    }
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
