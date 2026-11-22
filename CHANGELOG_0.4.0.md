# NEON: DEAD CITY — 0.4.0 City & World Pass

This update focuses on the parts of the prototype that can be improved safely and reliably on the existing Godot 4.3 / GL Compatibility project.

## Changes

- Reworked street traffic to use `CharacterBody3D` collision instead of a free-moving `Node3D` plus a single ray check.
- Traffic follows two fixed lanes on the east-west road, stays within the road segment, and pauses/reverses when blocked by buildings, pedestrians, the player, or another vehicle.
- Added matching static collision for large architectural `BoxMesh` structures.
- Reworked pedestrians as collidable `CharacterBody3D` actors with fixed patrol paths, four visual outfit variants, simple gait animation, and proximity dialogue.
- Added a mobile TALK button and keyboard E interaction with short NPC dialogue.
- Added a Sandevistan movement ribbon that follows the player's movement and fades after the effect ends. This is a visual movement effect, not an attack effect.
- Expanded the district dressing with a distant skyline, emissive signage, hologram panels, curb markers, crosswalk lights, puddles, a street kiosk, and a small number of dynamic lamps.
- Adjusted night-sky colors, fog, ambient light, and glow while retaining the Compatibility renderer for mobile hardware.

## Scope and verification

This is a procedural environment pass, not a claim of GTA 3-level asset quality. It uses primitive meshes because the source project contains no imported character, vehicle, building, or animation assets. Weapon/attack functionality was not expanded in this update.

The project archive was checked for ZIP integrity and resource-path consistency. It has not been run in the Godot editor or on a POCO F3 in this environment, so runtime behavior and Android export still require a real build/device test.
