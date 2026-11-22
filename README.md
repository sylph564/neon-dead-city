# NEON: DEAD CITY

A first-person 3D cyberpunk city prototype built with Godot 4.

## Current prototype
- First-person movement, mouse look, mobile joystick and touch camera controls.
- District 01 with neon architecture, lit shopfronts, road markings, fog, glow and directional shadows.
- Ambient pedestrian patrols and lightweight moving traffic.
- Cyberware menu with install/remove controls and seven active skills: Sandevistan, Mantis Blades, Gorilla Arms, Pulse Core, Reflex Booster, Monowire and Projectile Launch System.
- Training dummy with damage and DPS readout.
- Android arm64 debug export preset; GL Compatibility renderer for mobile devices.

Sandevistan slows ambient pedestrians and traffic while boosting player movement, with a timed screen effect. The city NPCs and vehicles use lightweight procedural meshes to keep the scene suitable for mobile hardware.

## Build an Android APK
The **Build Android APK** workflow runs on pushes to `main` and can also be started manually from the Actions tab. When it succeeds, open the run and download the `NEON-DEAD-CITY-Android` artifact.

This remains an evolving prototype: quests, save data, advanced AI, detailed interiors and a larger streaming open world are not yet implemented.
