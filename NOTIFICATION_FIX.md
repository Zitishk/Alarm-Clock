# Fixing Notification Permissions

## The Issue
You're seeing this error:
```
Failed to request notification permission: Error Domain=UNErrorDomain Code=1
"Notifications are not allowed for this application"
```

## Solution

### Option 1: Grant Permissions Manually (Recommended)

1. Open **System Settings** (⚙️ in your Dock)
2. Click **Notifications**
3. Scroll down and find **"AlarmClock"** or **"Kshitiz.AlarmClock"** in the list
4. Click on it
5. Toggle **"Allow Notifications"** to **ON**
6. Make sure these are enabled:
   - ✅ Alerts
   - ✅ Sound
   - ✅ Badges

### Option 2: Reset and Allow on App Launch

1. Quit the AlarmClock app completely
2. Run this command in Terminal to reset permissions:
   ```bash
   tccutil reset UserNotifications Kshitiz.AlarmClock
   ```
3. Launch the app again from Xcode
4. You should see a permission dialog - click **"Allow"**

## Why This Happened

On first launch, macOS should have shown a permission dialog. If you:
- Accidentally clicked "Don't Allow"
- Or the dialog didn't appear (rare Xcode bug)

Then you need to manually enable it in System Settings.

## How to Test If It's Fixed

1. Enable notifications using Option 1 above
2. In the app, set an alarm for 1-2 minutes in the future
3. Click "Set Alarm"
4. Look at the Xcode console - you should see:
   ```
   Notification permission granted: true
   Notification scheduled successfully for X:XX
   ```
5. Wait for the alarm time
6. The alarm should trigger! 🎉

## Note

Even without notification permissions, the **app still works** - you can test the audio player and UI. But the scheduled alarm won't fire until you grant permissions.
