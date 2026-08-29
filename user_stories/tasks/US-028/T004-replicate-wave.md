# T004: Replicate wave, knockback, and sheet

**Story**: US-028  
**Status**: Todo  
**Depends on**: T003  
**Parallel**: no

## Goal

Wave, knockback, sheet spawn/expire, duration, and size are host-authoritative. Peers see the same sheet.

## Files

- Wave + sheet from T002–T003
- Combat replication pattern

## Requirements

- FR-005, MR-001, MR-002
- Duration/size configurable on the host; clients receive the live sheet rect + remaining time.
- Late join during ice: receive current sheet.

## Acceptance

- **Given** a host Freeze Wave, **When** peers watch, **Then** they see the same wave, knockback, and ice sheet.
- **Given** a late joiner on a live sheet, **When** they spawn, **Then** they slide on the same rect.

## Notes

Do not replicate Jet. Do not create a zone pocket.
