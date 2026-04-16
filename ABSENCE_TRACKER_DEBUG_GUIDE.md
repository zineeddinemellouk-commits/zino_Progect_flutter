# Absence Tracker - Firestore Query Debugging Guide

## 🎯 Problem Statement
Absences are being created in Firestore, but NOT appearing in the Student Absence Tracker Page.

---

## 🔍 Root Cause Analysis

This is typically a **studentId mismatch** issue. The problem occurs when:

1. **Firebase Auth UID** (currentUser?.uid) doesn't match **Firestore studentId** field
2. **Whitespace differences** in studentId (trailing spaces, etc.)
3. **Case sensitivity** issues
4. **Firestore security rules** blocking reads
5. **Documents created without studentId** field

---

## 🧪 Step-by-Step Debugging

### Phase 1: Check Console Logs (REQUIRED)

Run the app and open debug console:

```bash
flutter run -v 2>&1
```

Look for these logs in the output:

#### A. Check Auth UID Logging:
```
[DEBUG] ===== AbsenceTrackerPage Build =====
[DEBUG] currentUser?.uid: "YOUR_AUTH_UID_HERE"
[DEBUG] currentUser?.email: "student@example.com"
[DEBUG] widget.studentId: "null"
[DEBUG] Final studentId: "YOUR_AUTH_UID_HERE"
[DEBUG] studentId is empty: false
```

**What to verify:**
- ✅ `currentUser?.uid` should NOT be empty
- ✅ It should be a string like `"abc123def456xyz789"`
- ✅ Email should show student's email

#### B. Check Firestore Query Logging:
```
[DEBUG] watchAbsencesByStudent called with: rawId="abc123def456xyz789", normalized="abc123def456xyz789", length=20
[StudentsFirestoreService] watchAbsencesByStudent: studentId=abc123def456xyz789, docCount=0
```

**⚠️ CRITICAL:**
- If `docCount=0`, the WHERE filter found NO documents
- This means either:
  - a) Absences don't exist for this studentId
  - b) StudentId in Firestore doesn't match Auth UID

#### C. Check Firestore Document Dump:
```
[DEBUG] ===== PAGE LOADED - DUMPING FIRESTORE STATE =====
[DEBUG] ===== FIRESTORE ABSENCES COLLECTION DEBUG =====
[DEBUG] Total absence documents: 3
[DEBUG] Document 0: id=absence_001
[DEBUG]   studentId: "abc123def456xyz789"
[DEBUG]   teacherName: "Mr. Ahmed"
[DEBUG]   subjectName: "Mathematics"
[DEBUG]   status: "pending"
[DEBUG]   createdAt: Timestamp(...)
```

**What to verify:**
- ✅ See total documents (should be > 0)
- ✅ Check if studentId matches your Auth UID
- ✅ Look for mismatch in capitalization, spacing, or characters

---

### Phase 2: Identify the Exact Problem

#### SCENARIO 1: docCount=0 BUT documents exist in collection

**Diagnosis:** StudentId mismatch

**Steps:**
1. Note the Auth UID from logs: `abc123def456xyz789`
2. Check the Firestore debug dump
3. Compare studentId values in printed documents
4. Look for differences:
   - Trailing spaces: `"abc123def456xyz789 "` (notice space)
   - Different case: `"ABC123def456XYZ789"` vs `"abc123def456xyz789"`
   - Wrong UID: Document has teacher's UID instead of student's UID

**Solution:**
- Fix the studentId being stored when creating absences
- Use: `studentId: studentId.trim()` (remove spaces)
- Ensure you're storing the STUDENT's Auth UID, not teacher's

#### SCENARIO 2: docCount > 0 BUT StreamBuilder shows empty list

**Diagnosis:** Query works, but data not being mapped

**Steps:**
1. Check logs for: `StreamBuilder received: X absences`
2. If 0 but docCount was > 0, there's a parsing error
3. Look for: `AbsenceFeatureModel.fromMap()` errors

**Solution:**
- Check AbsenceModel parsing
- Verify all required fields exist in Firestore

#### SCENARIO 3: No documents exist at all (docCount=0 AND total=0)

**Diagnosis:** Absences not being created

**Steps:**
1. Check if submitGroupAttendance() is being called
2. Verify teacher is creating absences
3. Check Firestore console manually

**Solution:**
- Teacher needs to mark students as absent
- Check teacher attendance submission logs

---

### Phase 3: Manual Verification in Firestore Console

Go to Firebase Console → Firestore Database:

1. Click on `absences` collection
2. Click on any document
3. Verify it has these fields:
   ```
   studentId: "auth-uid-12345"  ← Should match Firebase Auth UID
   teacherName: "Mr. Ahmed"
   subjectName: "Mathematics"
   createdAt: Timestamp(...)
   deadlineAt: Timestamp(...)
   status: "pending"
   ```

4. Copy the studentId value
5. Go to Firebase Console → Authentication
6. Find your student and check their UID
7. **COMPARE**: Do they match exactly?

If they DON'T match → This is your problem!

---

## 🔧 Common Fixes

### Fix 1: StudentId Has Trailing Whitespace

**In teachers_firestore_service.dart:**
```dart
batch.set(absenceRef, {
  'studentId': studentId.trim(),  // ← ADD .trim()
  // ... other fields
});
```

### Fix 2: Using Wrong UID

Ensure you're fetching the CORRECT student's UID:

**WRONG:**
```dart
final studentId = teacherId;  // ❌ Using teacher UID
```

**CORRECT:**
```dart
final studentId = student.id;  // ✅ Using student's actual UID
```

### Fix 3: Auth Not Initialized

**In absence_tracker_page.dart:**
```dart
final currentUser = FirebaseAuth.instance.currentUser;  // ✅ Correct
final studentId = currentUser?.uid ?? '';

if (studentId.isEmpty) {
  // User not logged in
  return errorWidget();
}
```

---

## 📊 Debug Output Checklist

When troubleshooting, collect these logs:

- [ ] Auth UID from `[DEBUG] currentUser?.uid`
- [ ] docCount from `[StudentsFirestoreService] watchAbsencesByStudent`
- [ ] First 3 documentsstudentId values from `[DEBUG] FIRESTORE ABSENCES ... Document`
- [ ] Firestore console manual UID verification
- [ ] Check if studentId in Firestore matches Auth UID exactly

---

## 🧹 Quick Fix Checklist

Run through this before asking for help:

1. **Check Auth UID is not empty** → Console logs should show it
2. **Compare studentId values** → Should match exactly (including spacing)
3. **Verify absences exist in Firestore** → Use manual console check
4. **Test without WHERE filter** → See if ANY absences appear
5. **Check Firestore security rules** → Ensure student can read absences

---

## 🚀 Testing Steps

### Test 1: Verify Firestore has documents
```
Expected logs:
[DEBUG] Total absence documents: X (X > 0)
```

### Test 2: Verify Auth UID matches
```
Compare these:
[DEBUG] currentUser?.uid: "???"
[DEBUG]   studentId: "???" (from Firestore dump)
Result: They should be IDENTICAL
```

### Test 3: Verify StreamBuilder gets data
```
Expected logs:
[DEBUG] StreamBuilder received: N absences
[DEBUG]   - Subject1 (pending)
[DEBUG]   - Subject2 (justified)
```

### Test 4: Check final UI display
If logs show data but UI is empty → UI bug (not Firestore issue)

---

## 📞 When Everything Fails

If nothing works, try this nuclear option:

1. **Manually remove WHERE filter** (temporary debug):
   ```dart
   // Replace this:
   .where('studentId', isEqualTo: normalizedStudentId)
   .snapshots()
   
   // With this (TEMPORARY):
   .snapshots()
   ```

2. **Run app and check logs:**
   - Does ANY data appear?
   - If YES → StudentId mismatch (fix coming below)
   - If NO → Documents don't exist or permission denied

3. **When you see data:**
   - Check the printed studentId values
   - Add logic to filter manually:
   ```dart
   final filtered = items.where((a) => a.studentId == normalizedStudentId).toList();
   ```

4. **Compare the filters:**
   - StudentId from database: `studentId: "user-123"` (from debug print)
   - Your Auth UID: `uid: "user-123"` (from currentUser?)
   - Are they identical or different?

---

## 💾 Log Collection Template

Save these logs for diagnosis:

```
=== AUTH INFO ===
UID: [paste from currentUser?.uid log]
Email: [paste from currentUser?.email log]

=== FIRESTORE QUERY RESULT ===
docCount: [paste number]
Matching studentIds: [list first 3]

=== COMPARISON ===
Auth UID: ____________
Firestore studentId: ____________
Do they match exactly? [ ] Yes [ ] No

=== DATABASE CONTENT ===
Total absences in collection: ___
Sample studentIds: ...
```

---

## ✅ Success Indicators

When fixed, you should see:

✅ `[DEBUG] docCount=X` (X > 0)
✅ `[DEBUG] StreamBuilder received: X absences`
✅ Absence cards visible in UI
✅ Timer counting down
✅ Subject/teacher names displaying

---

**Last Updated**: April 15, 2026
**Debugging Tool Version**: v1.0
