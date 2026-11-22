# NEON: DEAD CITY — update 0.2.0

## Added
- Six lightweight animated pedestrians on the district sidewalks.
- Two low-poly traffic vehicles with animated wheels and emissive lights.
- Ambient night environment: fog, glow and directional shadows tuned for the GL Compatibility renderer.
- Monowire and Projectile Launch System cyberware, including first-person arm attachments, skill buttons, range/damage behavior and energy impact effects.
- Sandevistan time dilation for ambient pedestrians and traffic, a player speed boost, camera FOV shift and screen overlay.

## Fixed
- Training dummy now spawns in front of the player instead of behind them.
- Melee bonus/range metadata is reset after every attack, including missed attacks.
- Cyberware menu refresh skips the character-preview row instead of treating it as an implant row.
- Cyberware capacity and install/remove controls now account for seven implants.

## Notes
- The project remains a mobile-focused prototype using Godot 4.3 and GL Compatibility.
- This environment did not have the Godot editor/runtime installed, so an Android APK export and in-engine playtest could not be performed here. The source project is packaged for import and testing in Godot 4.3.
