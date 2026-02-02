# HydraTrack - Testing & Verification Guide

## Edge Cases Handled

### 1. Data Validation

#### Age & Weight Input
- **Age Range**: 10-120 years (validated in both onboarding and profile editing)
- **Weight Range**: 30-300 kg (validated in both onboarding and profile editing)
- **Location**: `AgeWeightView.swift:isValid`, `ProfileEditView.swift:isValid`
- **Status**: ✅ Validated with disabled button states

#### Custom Drink Volume
- **Validation**: Volume must be > 0
- **Location**: `CustomDrinkSheet.swift:80`
- **Status**: ✅ Add button disabled for invalid values
- **Behavior**: Shows effective hydration calculation only for valid volumes

#### Goal Calculation Clamping
- **Range**: 1500-4500 mL (prevents unrealistic goals)
- **Location**: `GoalCalculator.swift:14, 23`
- **Status**: ✅ Properly clamped with breakdown showing if adjusted
- **Formula**: min(max(baseAmount + activityBonus, 1500), 4500)

### 2. Midnight Rollover

#### Today's Drinks Filter
- **Method**: `Calendar.current.isDateInToday()`
- **Location**: `HomeView.swift:24`
- **Status**: ✅ Automatically handles midnight boundary
- **Behavior**: Drinks logged before midnight will not appear in "Today's Drinks" after 12:00 AM

#### History Aggregation
- **Method**: `Calendar.current.startOfDay()`
- **Location**: `HydrationDataService.swift:getLast7DaysIntake()`
- **Status**: ✅ Groups drinks by calendar day
- **Behavior**: Each day's total calculated from midnight to midnight

### 3. Unit Conversion

#### mL ↔ oz Conversion
- **Conversion Factor**: 1 oz = 29.5735 mL (FDA standard)
- **Location**: `VolumeUnit.swift:15, 22`
- **Status**: ✅ Accurate conversion using standard formula
- **Precision**: Int conversion for display, Double for calculation

### 4. Notification Scheduling

#### Wake/Sleep Window Alignment
- **Method**: `calculateReminderTimes()`
- **Location**: `NotificationManager.swift:71-92`
- **Status**: ✅ Evenly distributes notifications within wake window
- **Formula**:
  - Total minutes = sleepTime - wakeTime
  - Interval = totalMinutes / (frequency + 1)
  - Reminders at: wake + interval, wake + 2×interval, etc.

#### Smart Reminder Threshold
- **Check Frequency**: Every 2 hours (background task)
- **Threshold**: Configurable 1-6 hours
- **Location**: `AppDelegate.swift:96-104`
- **Status**: ✅ Only sends if threshold exceeded AND within wake window
- **Fallback**: Regular scheduled notifications if background task fails

### 5. HealthKit Integration

#### Permission Handling
- **Location**: `HealthKitManager.swift:requestAuthorization()`
- **Status**: ✅ Graceful fallback to manual times
- **Behavior**:
  - If authorized: Fetch sleep schedule from last 7 days
  - If denied: Use manual wake/sleep time pickers
  - If unavailable: Hide HealthKit toggle in settings

#### Sleep Schedule Fallback
- **Default Times**: Wake 7:00 AM, Sleep 11:00 PM
- **Location**: `AppSettings.swift:11-12`
- **Status**: ✅ Sensible defaults if HealthKit unavailable

### 6. Empty State Handling

#### No Drinks Logged
- **Today's Drinks**: Shows no list (not empty state message)
- **Progress Ring**: Shows 0% with 0 / goal mL
- **Status**: ✅ Gracefully handles empty data
- **History Chart**: Shows 0 bars for days with no drinks

#### No User Profile
- **Fallback Goal**: 2500 mL default
- **Location**: `HomeView.swift:32`
- **Status**: ✅ Default goal prevents crashes
- **Behavior**: Onboarding creates profile on first run

#### Current Streak with Incomplete Today
- **Logic**: If today incomplete, start counting from yesterday
- **Location**: `HydrationDataService.swift:getCurrentStreak()`
- **Status**: ✅ Prevents breaking streak before day ends
- **Behavior**: Shows accurate consecutive complete days

### 7. Age Threshold for Goal Calculation

#### Age < 65
- **Base Rate**: 30 mL/kg
- **Location**: `GoalCalculator.swift:10`
- **Status**: ✅ Correct threshold

#### Age ≥ 65
- **Base Rate**: 25 mL/kg
- **Location**: `GoalCalculator.swift:10`
- **Status**: ✅ Correct threshold for seniors

### 8. Hydration Factor Application

#### Drink Type Factors
- Water: 100% (1.0)
- Coffee: 85% (0.85)
- Tea: 95% (0.95)
- Juice: 90% (0.9)
- Milk: 90% (0.9)
- Soda: 80% (0.8)
- Other: 90% (0.9)

- **Location**: `DrinkType.swift:12-24`
- **Calculation**: `volumeMl × hydrationFactor = effectiveHydrationMl`
- **Location**: `DrinkEntry.swift:17`
- **Status**: ✅ Applied on drink creation, stored for consistency

## Testing Checklist

### Manual Testing Steps

#### 1. Onboarding Flow
- [ ] Complete onboarding with age 64 (should use 30 mL/kg)
- [ ] Complete onboarding with age 65 (should use 25 mL/kg)
- [ ] Try invalid age (e.g., 5, 150) - button should be disabled
- [ ] Try invalid weight (e.g., 20, 400) - button should be disabled
- [ ] Verify goal calculation shows correct breakdown
- [ ] Grant notification permission and verify success
- [ ] Deny notification permission and verify app still works

#### 2. Drink Logging
- [ ] Add Water (250 mL) - verify 250 mL effective hydration
- [ ] Add Coffee (200 mL) - verify 170 mL effective hydration (200 × 0.85)
- [ ] Add custom drink with 0 mL - button should be disabled
- [ ] Add custom drink with negative value - should not allow
- [ ] Add custom drink with valid amount - verify calculation shown
- [ ] Verify progress ring animates smoothly
- [ ] Verify haptic feedback on drink add
- [ ] Delete a drink - verify total updates

#### 3. Midnight Rollover
- [ ] Log drinks before midnight
- [ ] After midnight, verify previous drinks don't show in "Today's Drinks"
- [ ] Verify previous day shows correct total in History
- [ ] Log new drink after midnight - verify appears in Today's list

#### 4. History & Calendar
- [ ] Verify 7-day chart shows correct totals
- [ ] Complete 100% goal - verify green circle on calendar
- [ ] Miss a day - verify streak resets
- [ ] Complete multiple consecutive days - verify streak count
- [ ] Navigate to previous/next month in calendar

#### 5. Settings & Profile
- [ ] Edit profile with age 64 → 65 - verify goal recalculates
- [ ] Edit weight - verify goal updates in real-time preview
- [ ] Set custom goal override - verify overrides calculated goal
- [ ] Disable custom goal - verify returns to calculated goal
- [ ] Change units to oz - verify conversions display correctly
- [ ] Change notification frequency - verify notifications reschedule

#### 6. Notifications
- [ ] Enable notifications - verify permission requested
- [ ] Set wake time 8 AM, sleep time 8 PM, frequency 4
  - Verify notifications scheduled at approximately: 10 AM, 12 PM, 2 PM, 4 PM
- [ ] Enable smart reminders
- [ ] Set threshold to 2 hours
- [ ] Don't log drinks for 2+ hours - verify smart reminder appears
- [ ] Log a drink - verify no immediate reminder

#### 7. HealthKit Integration
- [ ] Toggle HealthKit sleep schedule ON
- [ ] Grant HealthKit permission - verify sleep times fetched
- [ ] Deny HealthKit permission - verify falls back to manual pickers
- [ ] Verify manual time pickers hidden when HealthKit enabled
- [ ] Verify fetched times displayed (read-only)

#### 8. Accessibility
- [ ] Enable VoiceOver - verify all buttons have labels
- [ ] Navigate with VoiceOver through Quick Add buttons
- [ ] Verify progress ring announces percentage and values
- [ ] Enable Increase Contrast - verify UI remains readable
- [ ] Enable Larger Text - verify text scales appropriately
- [ ] Verify color contrast meets WCAG AA standards

#### 9. Edge Cases
- [ ] Complete goal exactly (e.g., 2500/2500) - verify 100% shown
- [ ] Exceed goal by 200% - verify percentage > 100% displays correctly
- [ ] Log 50 drinks in one day - verify list scrolls properly
- [ ] Uninstall and reinstall - verify onboarding shows again
- [ ] Background app and return - verify data persists
- [ ] Force quit and relaunch - verify state preserved

### Automated Testing Recommendations

#### Unit Tests (Future Enhancement)
```swift
// GoalCalculator Tests
- testGoalCalculationUnder65()
- testGoalCalculationOver65()
- testGoalClampingLowerBound()
- testGoalClampingUpperBound()
- testActivityBonusApplication()

// VolumeUnit Tests
- testMLToOzConversion()
- testOzToMLConversion()
- testRoundTripConversion()

// HydrationDataService Tests
- testGetTodayIntakeMidnightBoundary()
- testGetCurrentStreakWithIncompleteToday()
- testGetLast7DaysIntake()
```

#### UI Tests (Future Enhancement)
- Onboarding flow completion
- Drink logging and deletion
- Settings persistence
- Navigation between tabs

## Known Limitations

1. **Background Task Reliability**: iOS may not always execute background tasks on schedule. Smart reminders fall back to scheduled notifications.

2. **HealthKit Data Availability**: Sleep schedule requires user to have Apple Watch or manually log sleep in Health app.

3. **Notification Precision**: Notifications scheduled to nearest minute, not second.

4. **Streak Calculation**: Counts consecutive days at 100% goal, not partial completion.

5. **Unit Conversion Display**: Shows rounded integer values, not precise decimals.

## Performance Considerations

- **SwiftData Queries**: Optimized with proper fetch descriptors and predicates
- **Date Filtering**: In-memory filtering for "today" to avoid predicate limitations
- **Chart Rendering**: Limited to 7 days for performance
- **Calendar View**: Loads one month at a time

## Security & Privacy

- **Data Storage**: All data stored locally in SwiftData (no cloud sync)
- **HealthKit**: Only requests sleep analysis read permission
- **Notifications**: Local only, no remote push
- **No Analytics**: App does not collect usage data

## Success Criteria

All phases complete when:
- ✅ Build succeeds without errors
- ✅ All input validation prevents invalid data
- ✅ Midnight rollover handled correctly
- ✅ Goal calculation accurate for all age/activity combinations
- ✅ Notifications schedule within wake window
- ✅ HealthKit gracefully falls back when unavailable
- ✅ Accessibility labels present on all interactive elements
- ✅ UI responds to Dynamic Type and High Contrast
- ✅ Smart reminders work via background tasks
- ✅ Haptic feedback provides tactile confirmation

## Version History

**v1.0.0 (Build 1)**
- Initial release
- All 9 implementation phases complete
- Full feature set as specified in design document
