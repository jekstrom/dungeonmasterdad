# T003: Host-authoritative boss combat

**Story**: US-017  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002

## Goal

Boss **HP, wander, attack, blast, and die** run on the host. Clients show the replicated state.

## Files

- `monsters/enemy.gd` / `enemy_state_machine.gd` — pattern
- New Baja Blast boss states (wander / attack / blast / die)
- US-005 staple + melee already hit monsters; do not special-case Reality combat

## Requirements

- FR-010, AC2 (death is the gate to T004)
- Host owns HP and the kill. Clients may predict hit VFX.
- Wander in the exit room; attack and blast are boss moves (blast is a Baja-flavored attack, not Bemidji Blizzard).
- Die at 0 HP. Do not unlock here (T004 listens to death).
- Boss pulled into Reality is still this dungeon boss (edge).

## Acceptance

- **Given** the boss is alive, **When** it acts, **Then** wander/attack/blast are decided on the host.
- **Given** HP reaches 0, **When** the host resolves, **Then** the boss enters die and does not keep attacking.

## Notes

Unlock + can are T004. Do not implement US-018 fireball or US-020 cozy.
