#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WEB_STRINGS="$ROOT_DIR/apps/web/src/messages/vi.ts"
IOS_CATALOG="$ROOT_DIR/apps/ios/SongPhangKit/Sources/DesignSystem/Resources/Localizable.xcstrings"

node - "$WEB_STRINGS" "$IOS_CATALOG" <<'EOF'
const fs = require("fs");
const [webPath, catalogPath] = process.argv.slice(2);

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

const webFlat = flatten(vi);
const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8"));
const catalogStrings = catalog.strings || {};

let failures = 0;

for (const [key, webValue] of Object.entries(webFlat)) {
  const entry = catalogStrings[key];
  const iosValue =
    entry &&
    entry.localizations &&
    entry.localizations.vi &&
    entry.localizations.vi.stringUnit &&
    entry.localizations.vi.stringUnit.value;

  if (iosValue === undefined) {
    console.log(`MISSING: ${key}`);
    failures++;
  } else if (iosValue !== webValue) {
    console.log(`DIFFERING: ${key}`);
    console.log(`  web: ${JSON.stringify(webValue)}`);
    console.log(`  ios: ${JSON.stringify(iosValue)}`);
    failures++;
  }
}

for (const [key, entry] of Object.entries(catalogStrings)) {
  if (key.startsWith("ios.")) continue;
  if (!(key in webFlat)) {
    console.log(`EXTRA: ${key}`);
    failures++;
  }
}

if (failures > 0) {
  process.exit(1);
}
console.log(`OK: ${Object.keys(webFlat).length} web keys verified, 0 missing, 0 differing.`);
EOF
