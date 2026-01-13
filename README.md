# Alarm Clock - macOS Native App

A native macOS alarm clock application built with Swift and SwiftUI that plays custom MP3 files at scheduled times.

## Features

- ✅ Simple, intuitive UI
- ✅ Time picker for alarm selection
- ✅ Custom MP3 file selection for alarm sound
- ✅ Test song button to preview audio
- ✅ Set/Disable alarm functionality
- ✅ UNUserNotificationCenter integration for reliable alarm triggering
- ✅ Audio playback with AVAudioPlayer
- ✅ Visual alarm status display

## Project Structure

```
AlarmClockApp/
├── AlarmClockApp/
│   ├── AlarmClockApp.swift           # Main app entry point
│   ├── ContentView.swift             # Main UI with time picker, buttons, file selection
│   ├── AlarmManager.swift            # Alarm state and notification scheduling
│   ├── AudioPlayer.swift             # Audio playback with AVAudioPlayer
│   └── NotificationDelegate.swift    # UNUserNotificationCenterDelegate
├── Package.swift                     # Swift Package Manager configuration
└── README.md                         # This file
```

## Building and Running

### Prerequisites
- macOS 14.5 (Sonoma) or later
- Xcode Command Line Tools installed
- Swift 5.9+

### Build the App

```bash
cd AlarmClockApp
swift build
```

### Run the App

```bash
.build/debug/AlarmClockApp
```

Or build and run in one step:

```bash
swift run
```

## How to Use

1. **Launch the app**: Run the executable from the command line or double-click it
2. **Select alarm time**: Use the time picker to choose when you want the alarm to go off
3. **Choose a song**: Click "Choose Song" and select an MP3 file from your computer
4. **Test the song** (optional): Click "Test Song" to preview the audio
5. **Set the alarm**: Click "Set Alarm" to schedule the notification
6. **Status display**: The app will show "Alarm Status: ACTIVE" and the scheduled time
7. **When alarm triggers**: The app will play your selected song on loop and show an alert
8. **Stop the alarm**: Click "Stop Alarm" in the alert to stop the audio
9. **Disable alarm**: Click "Disable Alarm" to cancel a scheduled alarm

## How It Works

### Notification System
The app uses macOS's `UNUserNotificationCenter` API for scheduling alarms:
- **Calendar-based triggers**: Alarms fire at specific hours and minutes
- **Kernel scheduling**: Zero CPU usage while waiting for alarm
- **Foreground handling**: When app is open, the delegate fires the callback to play audio
- **Permission request**: On first launch, you'll be asked to allow notifications

### Audio Playback
Uses AVFoundation's `AVAudioPlayer`:
- Supports MP3, WAV, and other audio formats
- Loop playback for alarms (plays continuously until stopped)
- One-time playback for testing

### Architecture
- **AlarmManager**: Manages alarm state and schedules notifications with UNUserNotificationCenter
- **AudioPlayer**: Handles audio file playback with AVAudioPlayer
- **NotificationDelegate**: Receives notification callbacks and triggers alarm behavior
- **ContentView**: SwiftUI interface that coordinates all components

## Important Notes

1. **App must be running**: Per the requirements, the app is designed to be open when the alarm fires
2. **Mac must be awake**: The alarm will only fire if your Mac is not sleeping
3. **Notification permissions**: You must grant notification permissions on first launch
4. **Audio file format**: MP3 files work best, but other formats supported by AVAudioPlayer will work

## Advantages of This Implementation

✅ **No packaging issues**: Native Swift app builds directly as a macOS executable
✅ **UNUserNotificationCenter works perfectly**: No bundle proxy errors (unlike Python approaches)
✅ **Native macOS integration**: Uses system APIs correctly
✅ **Clean architecture**: SwiftUI for UI, separate classes for business logic
✅ **Performant**: Zero CPU usage while waiting for alarm (kernel-level scheduling)
✅ **Maintainable**: Standard Swift Package Manager structure

## Development Timeline

All 5 phases completed:
- ✅ Phase 1: Hello World window
- ✅ Phase 2: Time picker and file selection UI
- ✅ Phase 3: Set/Disable alarm buttons with state management
- ✅ Phase 4: Test Song button with audio playback
- ✅ Phase 5: UNUserNotificationCenter integration

## Troubleshooting

**Notifications not firing?**
- Make sure you granted notification permissions when prompted
- Check System Settings > Notifications to verify the app has permissions
- Ensure the app is running when the alarm time arrives

**Audio not playing?**
- Verify your MP3 file is not corrupted
- Try using the "Test Song" button first
- Check your system volume settings

**Build errors?**
- Ensure you have Xcode Command Line Tools installed: `xcode-select --install`
- Verify Swift version: `swift --version` (should be 5.9+)
- Make sure you're in the AlarmClockApp directory when building

## Future Enhancements

Possible improvements for the future:
- Multiple alarms support
- Recurring alarms (daily, weekdays, etc.)
- Volume control slider
- Snooze functionality
- Alarm history/logging
- Dark mode support
- App icon and branding

## License

This project was created as a demonstration of native macOS app development with Swift and SwiftUI.
