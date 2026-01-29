# Workout Timer for iOS

A beautifully minimal interval timer designed for focused workouts. No ads, no subscriptions, no distractions.

## Features

**Simple Interval Training**
- Configurable work and rest periods (5–300 seconds)
- Customizable round counts (1–50 rounds)
- 5-second warmup countdown before each session

**Custom Workouts**
- Create workout routines with named exercises
- Drag-and-drop exercise reordering
- See the next exercise during rest periods
- Persistent storage across app launches

**Immersive Visual Design**
- Full-screen animated gradient backgrounds
- Distinct colors for each phase: purple (warmup), orange (work), blue (rest)
- Large, readable timer display optimized for mid-workout glances
- Smooth transitions between phases

**Audio Feedback**
- Countdown beeps at 3, 2, 1 seconds
- Distinct sounds for phase transitions
- Background audio support — hear cues even when your phone is locked
- Music ducking that momentarily lowers your music during important cues

**Accessibility First**
- Full VoiceOver support with descriptive labels
- Dynamic Type compatibility
- Respects Reduce Motion preferences
- Large touch targets (44pt minimum)

**Built for Focus**
- No account required
- No internet connection needed
- No tracking or analytics
- Works in the background

## Screenshots

| Ready | Work | Rest | Complete |
|:-----:|:----:|:----:|:--------:|
| Start screen with timer and workout settings | Orange gradient with countdown | Blue gradient showing next exercise | Summary with stats |

## Requirements

- iOS 17.0 or later
- iPhone or iPad

## Tech Stack

- SwiftUI with `@Observable` (iOS 17+)
- AVFoundation for background audio
- No external dependencies

## Privacy

Workout Timer collects no data. All workouts are stored locally on your device.

## License

MIT
