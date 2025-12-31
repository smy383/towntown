# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TownTown (타운타운) is a village-based SNS metaverse app built with Flutter. Users can create characters, explore villages, and interact in a 2D environment.

**Target Platforms:** Android, iOS, Web

## Common Commands

```bash
# Run on Chrome (web)
flutter run -d chrome --web-port=8080

# Run on Android emulator
flutter run -d android

# Run on iOS simulator
flutter run -d ios

# Get dependencies
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Architecture

Currently a single-file app (`lib/main.dart`) with all code in one place. As the app grows, it should follow this structure:

```
lib/
├── main.dart              # App entry point
├── screens/               # Screen widgets
├── widgets/               # Reusable widgets
├── models/                # Data models
├── services/              # Business logic
└── utils/                 # Utility functions
```

## Key Components

### Character System
- **StickmanPainter**: CustomPainter that renders a stick figure character with joint-based animation
- **WalkCycle**: Calculates pose data (hip angles, knee bends, arm swings) for walk/run animations
- **Joint**: Helper class for calculating joint positions using rotation

### Animation System
- Front view when standing still, side view when moving
- Tap to walk (slow), long press to run (fast)
- Uses `AnimationController` for movement and walk cycle animations

### Screens
- **CreateCharacterScreen**: Character name input with animated preview
- **VillageLand**: Main game area with tap-to-move character control

## Technical Notes

- Uses `CustomPainter` for character rendering instead of sprites
- Joint angles use radians (pi/2 = down, 0 = right)
- Knee joints bend forward only (positive direction)
- Elbow joints bend forward only (negative direction in angle calculation)
- Character faces direction of movement via `Matrix4.scale` transform

## Future Integration

See `TECHNICAL_GUIDE.md` for reference implementation patterns for:
- Firebase backend (Auth, Firestore, Storage, Functions)
- Authentication (Google, Apple, Kakao)
- In-app purchases (Google Play, App Store, PortOne for web)
- Real-time chat with FCM push notifications
- Provider state management
