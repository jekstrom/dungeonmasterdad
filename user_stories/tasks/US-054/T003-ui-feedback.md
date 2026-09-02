# T003: UI wire-up and fail feedback

**Story**: US-054  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Skill Tree node clicks request host purchase. Show remaining SP. Failed spends show clear reason (SP / FL row gate / ultimate prereq / owned). Do **not** show a Reality Level gate reason for spends.

## Requirements

- FR-009, FR-010, AC3, AC5, AC8, AC11

## Acceptance

- **Given** a gated click, **When** host rejects, **Then** the DM sees why and SP/ownership are unchanged.
