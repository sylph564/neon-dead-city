# NEON: DEAD CITY

A first-person 3D cyberpunk district prototype built with Godot 4.3 and the GL Compatibility renderer.

## Current prototype

- First-person movement with mobile joystick, touch camera, sprint, and jump.
- District 01 with neon architecture, road markings, shopfronts, fog, glow, and directional shadows.
- Procedural skyline, street props, holographic panels, puddles, kiosk, and curb lighting.
- Fixed-lane traffic using physics collision and obstacle response.
- Collidable pedestrian characters with simple patrol movement, visual outfit variants, and dialogue interaction.
- Mobile TALK control and keyboard E interaction.
- Sandevistan movement boost with a rainbow movement ribbon and world time dilation.
- Existing cyberware terminal and training area from the earlier prototype.
- Android arm64 debug export preset.

## Build an Android APK

The **Build Android APK** workflow runs on pushes to `main` and `neon-update-0.2.0`, and can also be started manually from GitHub Actions. When it succeeds, open the workflow run and download the `NEON-DEAD-CITY-Android` artifact.

## Performance target

The project retains Godot's GL Compatibility renderer to maximize device compatibility. The scene uses procedural primitive meshes and limited dynamic lights. A larger city with imported high-quality models, rigged character animations, detailed interiors, audio, and mission content is still future work.

## 0.4.0 City & World Pass

See `CHANGELOG_0.4.0.md` for the changes and verification limits. The archive has not yet been runtime-tested in Godot or on an Android device.
