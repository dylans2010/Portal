# Live Activity Implementation for Portal

## Overview
This implementation adds Live Activity support to Portal's download and installation pipeline, showing real-time progress in Dynamic Island and on the Lock Screen.

## Architecture

### Components

1. **LiveActivityCoordinator** (`Feather/Backend/Managers/LiveActivityManager.swift`)
   - Manages Activity lifecycle using a coordinator pattern
   - Separate classes for registry, performance tracking, and background work
   - Unique method names: `launchActivityForDownload()`, `updateActivityState()`, `terminateActivity()`

2. **InstallationActivityAttributes** (`Feather/Backend/Managers/InstallationActivityAttributes.swift`)
   - Defines static attributes (app name, icon, user preferences)
   - Defines dynamic state (progress, status, speed, ETA)
   - Includes 11 installation phases: preparing, downloading, unzipping, signing, rezipping, installing, verifying, completed, failed, paused, cancelled
   - Supports user customization: accentColor, material, font, iconSize, detailDensity, animationStyle

3. **InstallationLiveActivityWidget** (`Feather/Views/LiveActivity/LiveActivityView.swift`)
   - ActivityKit widget configuration
   - Lock Screen layout with customizable styling
   - Dynamic Island regions: expanded (leading, trailing, center, bottom), compact (leading, trailing), minimal
   - Helper views: IconRenderer, ProgressRenderer

4. **LiveActivitySettingsView** (`Feather/Views/LiveActivity/LiveActivitySettingsView.swift`)
   - User preferences for Live Activity appearance
   - Color picker with 8 preset colors
   - Settings for material, font, progress style, icon size, detail density, animation

5. **DownloadManager Integration** (`Feather/Backend/Observable/DownloadManager.swift`)
   - Launches Live Activity on download start
   - Updates activity during download progress
   - Updates during signing/processing phase
   - Terminates on completion, error, or cancellation
   - Requests background time for continuous updates

### User Customization
All stored in UserDefaults with keys:
- `liveActivityEnabled`: Boolean toggle
- `liveActivityAccentColor`: Hex color string
- `liveActivityBackgroundMaterial`: "regular", "thin", "thick", "ultraThin", "ultraThick"
- `liveActivityFontFamily`: "system", "rounded", "monospaced", "serif"
- `liveActivityFontWeight`: "regular", "medium", "semibold", "bold"
- `liveActivityProgressBarStyle`: "linear", "gradient", "circular"
- `liveActivityIconSize`: "small", "medium", "large"
- `liveActivityDetailDensity`: "minimal", "normal", "detailed"
- `liveActivityAnimationStyle`: "smooth", "spring", "instant"

## Integration Points

### Download Triggers
Live Activities start automatically when downloads begin from:
1. **SourcesView** → via DownloadButtonView → DownloadManager.startDownload()
2. **HomeView** → App updates → DownloadManager.startDownload()
3. **LibraryView** → URL/file imports → DownloadManager.startDownload() or startArchive()

### Progress Updates
- Real-time during URLSession download (didWriteData)
- Speed calculation using moving average
- ETA estimation based on current velocity
- Status transitions: preparing → downloading → signing → completed

### Background Execution
- Uses UIApplication.beginBackgroundTask()
- Coordinator manages background slots
- Activity updates continue when app is backgrounded

## Info.plist Configuration
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.portal.app.cleanup.background</string>
</array>
```

## BackgroundTaskManager
Updated to only handle cleanup tasks:
- Removes temporary files older than 24 hours
- No longer handles signing loop
- Identifier changed to "com.portal.app.cleanup.background"

## Files Modified
- `Feather/Resources/Info.plist` - Added Live Activity support
- `Feather/Backend/Managers/InstallationActivityAttributes.swift` - Enhanced with customization
- `Feather/Backend/Managers/BackgroundTaskManager.swift` - Cleanup-only
- `Feather/Backend/Observable/DownloadManager.swift` - Integrated Live Activity
- `Feather/Views/LiveActivity/LiveActivityView.swift` - ActivityKit widget
- `Feather/Views/LiveActivity/LiveActivitySettingsView.swift` - User settings

## Files Created
- `Feather/Backend/Managers/LiveActivityManager.swift` - Coordinator implementation
- `Feather/Extensions/Color+Hex.swift` - Hex color support
- `PortalWidgets/PortalWidgetsBundle.swift` - Widget bundle registration

## Testing Checklist
- [ ] Download from Sources view
- [ ] Download from Home view (app updates)
- [ ] Import from Library view (URL)
- [ ] Import from Library view (file)
- [ ] Dynamic Island appearance
- [ ] Lock Screen appearance
- [ ] Progress updates in real-time
- [ ] Speed and ETA display
- [ ] Background updates
- [ ] Color customization
- [ ] Font customization
- [ ] Material customization
- [ ] Cancel handling
- [ ] Error handling
- [ ] Success completion

## Requirements Met
✅ NSSupportsLiveActivities in Info.plist
✅ BGTaskSchedulerPermittedIdentifiers for cleanup only
✅ Activity.request() on download start
✅ Initial state with "Preparing" status
✅ Global activity ID storage
✅ Progress piping via await activity.update()
✅ Background task during app background
✅ activity.end() on success/error/cancel
✅ ActivityConfiguration widget
✅ DynamicIsland regions (all 7)
✅ LockScreen layout
✅ User customization binding
✅ Settings persistence
✅ Real-time UI updates
