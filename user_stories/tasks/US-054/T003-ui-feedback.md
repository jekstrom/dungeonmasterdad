# T003: UI wire-up and fail feedback

**Story**: US-054  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Skill Tree node clicks **request** host purchase (no local own). Show remaining SP and each node’s cost (1/2/3/5). Chrome: gated / unaffordable / available / owned. Failed spends show a **distinct** reason (`not_enough_sp` / `row_gated` / `ultimate_prereq` / `already_owned`). Do **not** show a Reality Level gate reason. Refresh SP and affordability live while the panel stays open. Text labels are enough until T006 art lands.

## Requirements

- FR-009, FR-010, FR-016, FR-019, FR-020, FR-022, MR-001, MR-003
- AC7, AC9, AC11–AC13, AC16, AC18, AC22

## Acceptance

- **Given** a gated, unaffordable, owned, or prereq click, **When** the host rejects, **Then** the DM sees the matching reason and SP/ownership are unchanged.
- **Given** the panel is open, **When** FL or SP changes, **Then** the counter and node chrome update without closing the panel.
- **Given** T006 art is missing, **When** a buy fails, **Then** a readable text reason still appears.
