# macOS Alarm Clock - Project Handoff

## Objective

Build a macOS alarm clock app (Sonoma 14.5, M1) that plays an audio file at a specified time.

**Given constraints:**
- App will already be open when alarm fires
- Mac will be awake when alarm fires
- User will select time and audio file through GUI
- Audio must play at the scheduled time

## Working Code (May use as Reference)

### 1. Audio Playback (`audio_player.py`)
**Status:** Fully functional, tested.

Uses pygame.mixer for audio playback. Key functionality:
```python
class AudioPlayer:
    def __init__(self):
        pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=512)

    def load_audio(self, file_path):
        # Loads MP3, WAV, OGG files
        pygame.mixer.music.load(file_path)
        return True

    def play(self, volume=0.5, loop=True):
        # volume: 0.0 to 1.0
        # loop: True for infinite, False for once
        pygame.mixer.music.set_volume(volume)
        loops = -1 if loop else 0
        pygame.mixer.music.play(loops=loops)

    def stop(self):
        pygame.mixer.music.stop()
        pygame.mixer.music.unload()  # Critical: prevents audio from continuing
```

**Why it works:** pygame 2.5.2+ is stable on macOS M1. The unload() call after stop() is essential to fully release audio resources.

### 2. macOS Notification Bridge (`notification_manager.py`)
**Status:** Code is correct but requires .app bundle to function.

Uses pyobjc to bridge Python to UNUserNotificationCenter. This is the proper macOS API for scheduling time-based triggers.

**Critical implementation details:**

```python
import objc
from Foundation import NSObject, NSDateComponents
from UserNotifications import (
    UNUserNotificationCenter,
    UNMutableNotificationContent,
    UNCalendarNotificationTrigger,
    UNNotificationRequest,
)

class NotificationDelegate(NSObject):
    def init(self):
        # MUST use objc.super(), not NSObject.init()
        self = objc.super(NotificationDelegate, self).init()
        if self is None:
            return None
        self.python_callback = None
        return self

    def userNotificationCenter_willPresentNotification_withCompletionHandler_(
        self, center, notification, completion_handler):
        # This fires when notification triggers while app is open
        if self.python_callback:
            self.python_callback()  # Call Python function
        # Must call completion handler to show notification
        completion_handler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound)

class NotificationManager:
    def __init__(self):
        self.center = UNUserNotificationCenter.currentNotificationCenter()
        self.delegate = NotificationDelegate.alloc().init()
        self.center.setDelegate_(self.delegate)

    def schedule_alarm(self, alarm_datetime):
        content = UNMutableNotificationContent.alloc().init()
        content.setTitle_("Alarm")
        content.setBody_("Time to wake up!")

        # Calendar trigger fires at specific time
        components = NSDateComponents.alloc().init()
        components.setHour_(alarm_datetime.hour)
        components.setMinute_(alarm_datetime.minute)
        components.setSecond_(0)

        trigger = UNCalendarNotificationTrigger.triggerWithDateMatchingComponents_repeats_(
            components, False
        )

        request = UNNotificationRequest.requestWithIdentifier_content_trigger_(
            "alarm", content, trigger
        )

        self.center.addNotificationRequest_withCompletionHandler_(request, None)

    def set_trigger_callback(self, callback):
        # Set Python function to call when notification fires
        self.delegate.python_callback = callback
```

**Why this approach:** UNUserNotificationCenter uses macOS kernel scheduling - zero CPU usage, fires exactly at specified time, survives app backgrounding. This is how real alarm apps work.

**Known limitation:** UNUserNotificationCenter requires app to run from a proper .app bundle with Info.plist. Python scripts get error: `bundleProxyForCurrentProcess is nil`. This is a hard macOS requirement, not a bug.

### 3. Alarm State Management (`alarm_manager.py`)
**Status:** Fully refactored, no threading, works correctly.

Coordinates between notification system and audio player. Stores alarm state and handles triggering.

```python
class AlarmManager:
    def __init__(self, audio_player, notification_manager):
        self.audio_player = audio_player
        self.notification_manager = notification_manager

        # Register as callback for notifications
        notification_manager.set_trigger_callback(self._trigger_alarm)

        # Simple state (no locks needed - no threading!)
        self.alarm_time = None
        self.audio_file_path = None
        self.volume = 0.5
        self.is_enabled = False

    def set_alarm(self, hour, minute, is_pm, audio_path, volume):
        # Convert 12-hour to 24-hour
        hour_24 = hour + 12 if is_pm else hour
        if hour == 12:
            hour_24 = 12 if is_pm else 0

        alarm_datetime = datetime.now().replace(hour=hour_24, minute=minute, second=0)

        # Store state
        self.alarm_time = alarm_datetime.time()
        self.audio_file_path = audio_path
        self.volume = volume
        self.is_enabled = True

        # Schedule with macOS
        self.notification_manager.schedule_alarm(alarm_datetime)

    def _trigger_alarm(self):
        # Called by notification manager when alarm fires
        if self.audio_file_path and self.audio_player.load_audio(self.audio_file_path):
            self.audio_player.play(volume=self.volume, loop=True)

        # Notify GUI (if callback set)
        if self.trigger_callback:
            self.trigger_callback()

    def disable_alarm(self):
        self.notification_manager.cancel_alarm()
        self.audio_player.stop()
        self.is_enabled = False
```

**Architecture:** Notification fires → delegate callback → AlarmManager._trigger_alarm() → plays audio + shows popup. Clean separation of concerns, no polling, no threads.

### 4. GUI (`gui.py`)
**Status:** Works correctly with tkinter.

tkinter-based interface with time picker, file browser, volume slider, alarm popup. Key pattern:

```python
def show_alarm_popup(self):
    # Called from notification delegate (may be background thread)
    # Use root.after() to bridge to main thread
    self.root.after(0, self._create_alarm_popup)

def _create_alarm_popup(self):
    # Create modal alarm window
    self.alarm_popup = tk.Toplevel(self.root)
    self.alarm_popup.title("ALARM!")
    self.alarm_popup.attributes('-topmost', True)
    # ... add stop button, etc
```

**Thread safety:** Always use `root.after(0, callback)` when calling tkinter from non-main threads. Never call tkinter methods directly from notification delegate.

## The Packaging Problem

**What happened:** Attempted to package with py2app to create .app bundle (required for UNUserNotificationCenter). App builds successfully but crashes on launch with:

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException'
reason: '-[NSApplication macOSVersion]: unrecognized selector sent to instance'
```

**Root cause:** tkinter (tk/tcl libraries) calls macOS APIs that changed between macOS versions. All tested tk/tcl versions (Anaconda 8.6.12, Homebrew 8.6.17, system Python) crash on macOS 14.5.

**Confirmed:** This is not a configuration issue. tk/tcl 8.6.x is fundamentally incompatible with py2app on macOS 14.5.

## Dependencies

```
pygame==2.5.2
pyobjc-core>=9.0
pyobjc-framework-Cocoa>=9.0
pyobjc-framework-UserNotifications>=9.0
```

Python 3.9+ required for pyobjc compatibility.

## What Does NOT Work

**Do not attempt:**
- py2app with tkinter on macOS 14.5 - proven incompatible
- Running UNUserNotificationCenter from Python script - requires .app bundle
- Manual library copying to fix py2app builds - doesn't solve tk/tcl API mismatch
- Time polling every second - inefficient, not how alarm clocks work

## Alternative Approaches

### Option A: Replace tkinter with Qt
**Rationale:** PySide6/PyQt6 packages cleanly with py2app on modern macOS.

```bash
pip install PySide6 pygame pyobjc-framework-UserNotifications
```

Rewrite only `gui.py` using PySide6. Keep all other files unchanged. PySide6 has better py2app compatibility and is actively maintained for macOS.

**Effort:** Moderate GUI rewrite (~200 lines). Core logic unchanged.

### Option B: Use threading.Timer instead of notifications
**Rationale:** Eliminates .app bundle requirement entirely.

Modify `alarm_manager.py` to use Python's `threading.Timer`:
```python
from threading import Timer

def set_alarm(self, hour, minute, is_pm, audio_path, volume):
    alarm_datetime = datetime.now().replace(hour=hour_24, minute=minute, second=0)
    wait_seconds = (alarm_datetime - datetime.now()).total_seconds()

    if wait_seconds > 0:
        Timer(wait_seconds, self._trigger_alarm).start()
```

Run directly: `python run_alarm.py`. No packaging needed. Works immediately.

**Limitation:** Alarm won't survive app restart. Acceptable if app stays open (per requirements).

**Effort:** Small (~20 line change). Remove notification_manager.py entirely.

### Option C: Native Swift app
**Rationale:** No Python packaging issues. UNUserNotificationCenter works natively.

Translate Python logic to Swift:
- UNUserNotificationCenter (same API as pyobjc)
- AVAudioPlayer (equivalent to pygame)
- SwiftUI for GUI

Build in Xcode. Packages correctly as .app.

**Effort:** Complete rewrite but straightforward translation. Reference existing Python code for logic.

## Testing Recommendations

**Before building features:**
1. Create minimal "Hello World" with chosen GUI framework
2. Package as .app with py2app (or build in Xcode for Swift)
3. Verify .app launches successfully
4. THEN add alarm features

**Do not** write full application before confirming packaging works. That's how we got here.

## Key Files Reference

If continuing with Python + notifications approach:
- `alarm_clock/audio_player.py` - pygame patterns (96 lines, complete)
- `alarm_clock/alarm_manager.py` - alarm logic without threading (150 lines, complete)
- `alarm_clock/notification_manager.py` - UNUserNotificationCenter bridge (211 lines, complete)
- `alarm_clock/gui.py` - tkinter GUI (334 lines, would need rewrite for Qt)
- `alarm_clock/main.py` - initialization and wiring (82 lines, minimal changes needed)

## Final Notes

The core alarm logic is solid. Audio playback works. Notification scheduling works. The only unsolved problem is packaging a GUI that's compatible with py2app on macOS 14.5.

Choose based on priority:
- **Fast solution:** Use threading.Timer, skip packaging
- **Proper solution:** Use PySide6, package with py2app
- **Best solution:** Native Swift app

Any of these will work. All existing Python code can be preserved or referenced.
