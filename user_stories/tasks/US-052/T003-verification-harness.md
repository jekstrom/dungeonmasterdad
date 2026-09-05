# T003: Verification harness

**Story**: US-052  
**Status**: Todo  
**Depends on**: T002  
**Owner**: QA / Gameplay

## Goal

Headless or harness: not-owned baseline speed, force-own applies **1.5× DM movement speed**, no dash action exists, peers agree on locomotion.

## Requirements

- AC1–AC5 smoke

## Acceptance

- **Given** the harness, **When** it runs, **Then** owned vs not-owned speed asserts pass without manual editor clicks.
- **Given** owned, **When** queried, **Then** the harness MUST NOT require or grant a dash input.
