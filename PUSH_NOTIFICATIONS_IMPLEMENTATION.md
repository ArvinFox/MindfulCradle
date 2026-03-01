# Push Notifications Implementation

## Overview

MindfulCradle now includes a comprehensive push notification system that sends personalized reminders to users for:

- **Meditation Videos**: Encourage users to watch relaxation content
- **AI Companion Chat**: Remind users they can talk if feeling alone
- **Wellness Activities**: Prompt health check-ins and tracking
- **Questionnaires**: Remind users to complete mental health assessments
- **Hydration**: Remind users to stay hydrated

## Architecture

### Key Components

#### 1. NotificationService (`lib/services/notification_service.dart`)

- **Firebase Cloud Messaging (FCM)**: Handles remote push notifications
- **Local Notifications**: Scheduled reminders using `flutter_local_notifications`
- **Timezone Support**: Daily repeating notifications at specific times
- **Bilingual Templates**: Messages in English and Sinhala

##### Key Methods:

```dart
// Initialize the service
await NotificationService().initialize();

// Schedule specific reminders
await NotificationService().scheduleMeditationReminder(
  language: 'en',
  hourOfDay: 8,
  minute: 0,
);

// Setup default reminders (recommended times)
await NotificationService().setupDefaultReminders('en');

// Cancel specific reminder
await NotificationService().cancelReminder('meditation');

// Cancel all reminders
await NotificationService().cancelAllReminders();

// Get saved schedules
Map<String, dynamic> schedules = await NotificationService().getSchedules();
```

#### 2. NotificationSettingsScreen (`lib/screens/profile/notification_settings_screen.dart`)

A user-friendly UI for managing notification preferences:

- **Setup Default Reminders**: One-click setup of recommended times
- **Customize Each Reminder**: Set specific times for each notification type
- **Visual Feedback**: Shows scheduled times and status
- **Easy Management**: Cancel individual or all reminders

#### 3. Localization (`languages/notifications.json`)

All notification-related text in English and Sinhala:

- Settings labels
- Success/error messages
- Button text
- Notification content templates

## Notification Types

### 1. Meditation Reminders (🧘‍♀️)

**Purpose**: Encourage users to watch meditation videos for relaxation
**Recommended Time**: 8:00 AM (Morning)
**Sample Messages**:

- "Meditation Time - Watch a meditation video to relax your mind and body"
- "භාවනා කාලය - ඔබේ මනස සහ ශරීරය සනීප කර ගැනීමට භාවනා වීඩියෝවක් නරඹන්න"

### 2. Companion Chat Reminders (💬)

**Purpose**: Remind users the AI companion is available for emotional support
**Recommended Time**: 2:00 PM (Afternoon)
**Sample Messages**:

- "Your Companion is Here - Feeling alone? Chat with your Mindful Cradle companion"
- "ඔබේ සහායකයා මෙහි සිටී - තනිව හැඟෙනවාද? ඔබේ Mindful Cradle සහායකයා සමඟ කතා කරන්න"

### 3. Wellness Reminders (🌟)

**Purpose**: Prompt daily wellness tracking and health check-ins
**Recommended Time**: 7:00 PM (Evening)
**Sample Messages**:

- "Wellness Tip - Check your daily wellness activities for today"
- "සෞඛ්‍ය උපදෙස් - අද සඳහා ඔබේ දෛනික සෞඛ්‍ය ක්‍රියාකාරකම් පරීක්ෂා කරන්න"

### 4. Questionnaires Reminders (📋)

**Purpose**: Remind users to complete mental health assessments
**Recommended Time**: User-defined
**Sample Messages**:

- "Mental Health Check - Complete a questionnaire to assess your mental wellbeing"
- "මානසික සෞඛ්‍ය පරීක්ෂාව - ඔබේ මානසික යහපැවැත්ම පරීක්ෂා කිරීමට ප්‍රශ්නාවලියක් සම්පූර්ණ කරන්න"

### 5. Hydration Reminders (💧)

**Purpose**: Remind users to stay hydrated during pregnancy
**Recommended Time**: 10:00 AM
**Sample Messages**:

- "Stay Hydrated - Don't forget to drink water to keep yourself healthy"
- "ජලය පානය කරන්න - ඔබේ ශරීරය සෞඛ්‍යයෙන් තබා ගැනීමට ජලය පානය කිරීමට අමතක නොකරන්න"

## Setup & Configuration

### Android Configuration

#### Permissions Added to AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

#### FCM Configuration:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="mindful_cradle_reminders" />
```

#### Boot Receiver (Reschedules notifications after device restart):

```xml
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

### iOS Configuration (Future Enhancement)

- Add notification permissions to `Info.plist`
- Configure APNs (Apple Push Notification service)
- Handle notification permissions in iOS 14+

## Dependencies

### Added to pubspec.yaml:

```yaml
dependencies:
  firebase_messaging: ^15.1.6
  flutter_local_notifications: ^18.0.1
  timezone: ^0.10.1
```

## User Flow

### First Time Setup:

1. User navigates to Profile → Notification Settings
2. Sees description of notification benefits
3. Taps "Setup Default Reminders" button
4. All reminders scheduled at recommended times
5. Success message displayed

### Customizing Reminders:

1. User opens Notification Settings
2. Taps clock icon next to any reminder type
3. Selects preferred time using time picker
4. Reminder scheduled at chosen time
5. Time displayed on reminder card

### Disabling Reminders:

1. User can tap × icon on individual reminders
2. Or tap "Disable All Notifications" button
3. Confirmation dialog shown
4. Reminders cancelled

## Technical Details

### Notification Storage

- Schedules saved to `SharedPreferences` under key `notification_schedules`
- Format: JSON map with reminder type as key
- Example:

```json
{
  "meditation": { "hour": 8, "minute": 0, "enabled": true },
  "companion": { "hour": 14, "minute": 0, "enabled": true },
  "wellness": { "hour": 19, "minute": 0, "enabled": true }
}
```

### FCM Token Management

- Token retrieved on initialization
- Automatically refreshes when needed
- Stored in NotificationService instance
- Can be accessed via `NotificationService().fcmToken`

### Background Execution

- Background message handler registered: `_firebaseMessagingBackgroundHandler`
- Must be top-level function (not class method)
- Handles notifications when app is terminated

### Notification Channels

- **Channel ID**: `mindful_cradle_reminders`
- **Channel Name**: "Mindful Cradle Reminders"
- **Importance**: High
- **Features**: Vibration, Sound, Badges

## Testing

### Testing Local Notifications:

```dart
// Schedule a test notification for 1 minute from now
await NotificationService().scheduleMeditationReminder(
  language: 'en',
  hourOfDay: DateTime.now().hour,
  minute: DateTime.now().minute + 1,
);
```

### Testing FCM:

1. Get FCM token: `String? token = NotificationService().fcmToken;`
2. Use Firebase Console to send test notification
3. Target device using the token

## Future Enhancements

### Potential Improvements:

1. **Smart Scheduling**: AI-based optimal notification times
2. **Notification History**: Log of sent/received notifications
3. **Notification Frequency**: Daily, weekly, custom intervals
4. **Rich Notifications**: Images, action buttons, inline replies
5. **Notification Analytics**: Track engagement rates
6. **Geo-fencing**: Location-based reminders (e.g., near hospital)
7. **Conditional Notifications**: Based on user behavior/mood
8. **Notification Sounds**: Custom sounds for each reminder type
9. **Silent Hours**: Do not disturb during sleep hours
10. **Milestone Notifications**: Pregnancy week updates

### Integration Opportunities:

- **Questionnaire Results**: Notify when results are ready
- **Achievement Unlocked**: Congratulate on milestones
- **Content Updates**: New meditation videos available
- **Chat Summary**: Weekly AI companion conversation insights
- **Health Alerts**: From wearable device integration

## Troubleshooting

### Notifications Not Showing:

1. Check Android/iOS notification permissions
2. Verify notification channel is created
3. Ensure exact alarm permission granted (Android 12+)
4. Check device battery optimization settings
5. Verify timezone initialization

### FCM Token Not Generated:

1. Check google-services.json is present
2. Verify Firebase project configuration
3. Ensure internet connectivity
4. Check Firebase Console for project status

### Scheduled Notifications Not Repeating:

1. Verify timezone is initialized: `tz.initializeTimeZones()`
2. Check `matchDateTimeComponents: DateTimeComponents.time`
3. Ensure boot receiver is registered for persistence

## Localization Keys

All notification-related translations in `languages/notifications.json`:

- `notifications` - Screen title
- `notificationSettings` - Settings page title
- `meditationReminders` - Meditation reminder label
- `companionChatReminders` - Companion chat label
- `wellnessReminders` - Wellness reminder label
- `questionnairesReminders` - Questionnaires label
- `hydrationReminders` - Hydration label
- `setupDefaultReminders` - Setup button text
- `defaultRemindersSet` - Success message
- `reminderScheduled` - Individual schedule success
- `reminderCancelled` - Cancel success message
- `notificationDescription` - Feature description

## Summary

The push notification system provides a complete solution for engaging users with timely, personalized reminders. It combines:

- **Firebase Cloud Messaging** for remote notifications
- **Local scheduled notifications** for daily reminders
- **Bilingual support** for English and Sinhala
- **User-friendly UI** for easy management
- **Flexible scheduling** with time picker
- **Persistent storage** that survives app restarts

This feature significantly enhances user retention and engagement by keeping MindfulCradle top-of-mind during the pregnancy journey.
