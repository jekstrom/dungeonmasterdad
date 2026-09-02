# T006: Verification harness

**Story**: US-013  
**Status**: Todo  
**Depends on**: T002–T005, T007–T008  
**Owner**: QA / Gameplay

## Goal

Assert spawn is gremlin scene (not goblin); relocate cycle; death drop; no double-pickup; **2× speed**; **walkable-only** pathing (no off-map stuck); **staples damage**; **flee PP**; two-window visual / state match.

## Requirements

- AC1–AC12, MR-001–MR-004

## Acceptance

- **Given** the harness, **When** it runs, **Then** gremlin≠goblin, relocate, speed, walkable, staples, and flee asserts pass without manual editor clicks.
