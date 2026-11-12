# Phase 1 — manual checks for the project owner

Written by the implementation agent from the "Manual checks for the project owner" blocks of the plan, reorganized by screen (S1–S13) and then by flow (A–H). Each line: what to do, where, and what must be true. Invalid cases are included.

## Before you start

## Screens

## Flows

## After the Google OAuth app exists


## Core money functions (1A.1)
1. From the repository root run `node --input-type=module -e 'import {splitEqually} from "./packages/core/src/index.ts"; console.log(splitEqually(100000,["a","b","c"]))'` → amounts 33334,33333,33333, summing to 100000.
2. Call `netPairwiseDebts` with b→a 90 and c→b 90, order a,b,c → two transfers; call `suggestMinimizedSettlements` with a +90,b 0,c −90 → one c→a 90.
3. Call `splitEqually(0,["a"])` or `splitEqually(1000,[])` → RangeError, no amounts.
