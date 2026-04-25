# 🎓 Teacher Profile Tab - Quick Reference

## 📱 What Users See

```
Profile Tab (Tab 3)
├─ 👤 Avatar with initials
├─ 📝 Teacher name (centered, large)
├─ 📧 Email (gray, small)
├─ 📚 My Subjects (chips)
├─ 👥 My Groups (numbered list)
├─ 🔐 Change Password button
└─ 🚪 Logout button
```

---

## 🔐 Password Change

### Correct Flow ✅
```
User enters password correctly
    ↓
Firebase validates (reauthentication)
    ↓
✅ "Password changed successfully" (green)
    ↓
Dialog closes
```

### Error Cases ❌
```
❌ Wrong current password
   → "Current password is incorrect"

❌ Passwords don't match
   → "New passwords do not match"

❌ Password too short (< 6)
   → "Password must be at least 6 characters"

❌ Firebase error
   → Specific error from Firebase
```

---

## 👥 Groups Display

### What's Shown
```
Number │ Group Name │ Level
───────┼────────────┼──────
  1    │ Group A    │ 1A
  2    │ Group B    │ 1B
  3    │ Group C    │ 2A
```

### Styling
- Number: Blue badge (#1565C0)
- Name: Bold black text
- Level: Gray secondary text
- Separator: Light gray divider

---

## 📊 Data Sources

| Element | Source | Update |
|---------|--------|--------|
| Avatar | Name initials | Real-time |
| Name | dashboard.teacher.fullName | Real-time |
| Email | dashboard.teacher.email | Real-time |
| Subjects | dashboard.subjects[] | Real-time |
| Groups | dashboard.groups[] | Real-time |

---

## 🔧 Developer Notes

### Firestore Collections Required
```
✅ teachers/{teacherId}
   ├─ fullName: string
   ├─ email: string
   ├─ groups: array of group objects
   └─ subjects: array of subject objects

✅ groups/{groupId}
   ├─ name: string
   └─ levelId: string

✅ subjects/{subjectId}
   └─ name: string
```

### Firebase Auth Required
```
✅ User must be authenticated
✅ User email must match Firestore
✅ User must have password (not OAuth-only)
```

### State Variables
```dart
_isChangingPassword: bool     // Tracks password change state
_selectedNavIndex: int        // Current tab (3 = Profile)
_auth: FirebaseAuth          // Firebase instance
_service: TeachersFirestoreService  // Data service
_authService: DepartmentAuthService // Auth service
```

---

## 🔒 Firebase Auth Integration

### Password Update Process
```
Step 1: Validate inputs
  ✓ All fields required
  ✓ Password min 6 chars
  ✓ Passwords match

Step 2: Get current user
  ✓ firebase_auth.currentUser

Step 3: Reauthenticate
  ✓ EmailAuthProvider with current password
  ✓ user.reauthenticateWithCredential()

Step 4: Update password
  ✓ user.updatePassword(newPassword)

Step 5: Show result
  ✓ Success: green snackbar
  ✓ Error: error-specific snackbar
```

### Error Codes
```dart
'wrong-password' → "Current password is incorrect"
'weak-password' → "New password is too weak"
'requires-recent-login' → "Please logout and login again"
'user-mismatch' → "User account mismatch"
Other → Firebase error message
```

---

## 🎯 Key Methods

### `_changePassword()`
- Opens password change dialog
- Handles validation
- Calls Firebase Auth
- Shows success/error

**Called by:** "Change Password" button

### `_logout()`
- Signs out from Firebase
- Clears auth service
- Navigates to login

**Called by:** "Logout" button

### `_getInitials(String name)`
- Extracts first letter of first and last name
- Returns uppercase string
- Used for avatar text

**Example:** "John Doe" → "JD"

### `_showErrorMessage(String message)`
- Shows error snackbar
- Red background
- 3 second duration

**Used for:** Password validation errors

---

## 🎨 Colors

```
Primary Blue:    #1565C0    ← Buttons, badges
Light Blue:      #E8F0FE    ← Subject chips
Dark Blue:       #0D47A1    ← Avatar gradient
Text:            #1F1F1F    ← Primary
Secondary:       #666666    ← Level, email
Gray Background: #F5F5F5    ← Cards
Light Gray:      #CCCCCC    ← Dividers
Success Green:   #27AE60    ← Success message
Error Red:       #D32F2F    ← Error/logout
```

---

## 📐 Spacing

```
Page padding:     20px
Section margin:   24px
Item spacing:     12px
Button height:    48px (min)
Avatar size:      100x100
Badge size:       40x40
```

---

## 🧪 Quick Test Checklist

```
☐ Profile page loads
☐ Avatar shows
☐ Name displays
☐ Email displays
☐ Subjects show (if assigned)
☐ Groups show (if assigned)
☐ Groups have correct format (number, name, level)
☐ "Change Password" button opens dialog
☐ Password validation works
☐ Successful password change shows success
☐ Wrong password shows error
☐ "Logout" button works
☐ Tab switching works
☐ Error state displays properly
☐ Loading state displays
```

---

## 🚨 Common Issues & Solutions

### Issue: Groups not showing
**Solution:** Check if groups exist in Firestore
```
Path: /teachers/{teacherId}
Field: groups (array)
```

### Issue: Password change fails
**Solution:** Check Firebase Auth rules and user status
```
✓ User must be logged in
✓ Email must match Firebase Auth user
✓ User must have password (not OAuth-only)
```

### Issue: Cannot reauthenticate
**Solution:** User may need to log out and log in again
```
Error: 'requires-recent-login'
Action: Show message "Please logout and login again"
```

### Issue: Dialog doesn't close
**Solution:** Check error handling in password update
```
If error occurs:
  → Keep dialog open
  → Show error message
  → Let user retry
```

---

## 📝 Logging Output

### Successful Password Change
```
[TeacherProfile] 🔐 Attempting password change for teacher@email.com
[TeacherProfile] Step 1: Reauthenticating...
[TeacherProfile] ✅ Reauthentication successful
[TeacherProfile] Step 2: Updating password...
[TeacherProfile] ✅ Password updated successfully
```

### Failed Password Change
```
[TeacherProfile] 🔐 Attempting password change for teacher@email.com
[TeacherProfile] Step 1: Reauthenticating...
[TeacherProfile] ❌ Firebase Auth Error: wrong-password - The password is invalid or the user does not have a password.
```

---

## 💾 Data Persistence

✅ **Real-time updates**
- StreamBuilder fetches data from Firestore
- Changes appear immediately
- No manual refresh needed

✅ **State preservation**
- Tab switching preserves profile data
- Groups/subjects stay loaded
- Scroll position maintained

✅ **Error recovery**
- Error state shown to user
- Retry available (tab switch)
- No data loss on error

---

## 🔄 Firestore Integration

### Watch Stream
```dart
StreamBuilder<TeacherDashboardData?>(
  stream: _service.watchTeacherDashboard(
    teacherId: widget.teacherId,
    teacherEmail: widget.teacherEmail,
  ),
  ...
)
```

### Real-time Updates
```
Firestore document changes
    ↓
watchTeacherDashboard() emits new data
    ↓
StreamBuilder rebuilds
    ↓
UI shows updated groups/subjects
```

---

## 📋 Component Breakdown

### Section: Avatar
```dart
Container(
  width: 100,
  height: 100,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(...),
  ),
  child: Text(initials),
)
```

### Section: Groups
```dart
ListView.separated(
  itemCount: groups.length,
  itemBuilder: (_, i) => Row(
    children: [
      Badge(number: i+1),
      Column(
        children: [
          Text(group.name),
          Text('Level: ${group.levelId}'),
        ],
      ),
    ],
  ),
)
```

### Dialog: Password
```dart
AlertDialog(
  title: Text('Change Password'),
  content: Column(
    children: [
      TextField(label: 'Current Password'),
      TextField(label: 'New Password'),
      TextField(label: 'Confirm Password'),
    ],
  ),
  actions: [
    TextButton(label: 'Cancel'),
    ElevatedButton(label: 'Update Password'),
  ],
)
```

---

## 🎯 Summary

✅ **Profile Page Displays:**
- Teacher info (name, email)
- Subjects list
- Groups list (with level)

✅ **Password Change:**
- Proper Firebase Auth integration
- Specific error handling
- User-friendly messages

✅ **Code Quality:**
- Error handling
- Loading states
- Real-time updates
- Professional UI

**Status:** ✅ Production Ready
