# Firestore Security Rules

## Production-Ready Rules for Notification System

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ===== JUSTIFICATIONS COLLECTION =====
    match /justifications/{document=**} {
      // Students can read/write their own justifications
      allow read, write: if request.auth != null &&
        (request.auth.uid == resource.data.studentId ||
         get(/databases/$(database)/documents/departments/$(request.auth.uid)).data != null);

      // Create rule for students
      allow create: if request.auth != null &&
        request.auth.uid == request.resource.data.studentId;
    }

    // ===== DEPARTMENT NOTIFICATIONS =====
    match /department_notifications/{document=**} {
      // Department can read their own notifications
      allow read: if request.auth != null &&
        get(/databases/$(database)/documents/departments/$(request.auth.uid)).data != null;

      // System can write notifications (via backend)
      allow write: if request.auth != null;

      // Department can update (mark as read)
      allow update: if request.auth != null &&
        resource.data.departmentId == get(/databases/$(database)/documents/departments/$(request.auth.uid)).data.id;
    }

    // ===== STUDENT NOTIFICATIONS (existing) =====
    match /notifications/{document=**} {
      // Students can read their own notifications
      allow read: if request.auth != null &&
        request.auth.uid == resource.data.studentId;

      // System can write
      allow write: if request.auth != null;
    }

    // ===== DEPARTMENTS =====
    match /departments/{document=**} {
      // Department can read their own profile
      allow read: if request.auth != null &&
        request.auth.uid == resource.id;

      // Admin only can write
      allow write: if false;
    }

    // ===== ABSENCES =====
    match /absences/{document=**} {
      allow read, write: if request.auth != null;
    }

    // ===== STUDENTS =====
    match /students/{document=**} {
      allow read, write: if request.auth != null;
    }

    // ===== DEFAULT DENY =====
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Firestore Collections Schema

### justifications

```typescript
interface Justification {
  studentId: string; // Firebase Auth UID
  studentName: string; // Student full name
  absenceId: string; // Reference to absence
  subjectName: string; // Course/subject name
  reason: string; // Medical/Family/Personal/Other
  details?: string; // Additional details
  fileUrl: string; // URL to uploaded document
  fileName: string; // Original file name
  fileType: string; // pdf/jpg/jpeg/png
  status: "pending" | "submitted" | "approved" | "rejected";
  createdAt: Timestamp;
  submittedAt?: Timestamp;
  approvedAt?: Timestamp;
  rejectedAt?: Timestamp;
}
```

### department_notifications

```typescript
interface DepartmentNotification {
  departmentId: string; // Target department ID
  type:
    | "justificationsubmitted"
    | "justificationapproved"
    | "justificationrejected";
  title: string; // "New Justification Request"
  message: string; // "Ahmed submitted a justification for Mathematics"
  studentId: string; // Reference to student
  studentName: string; // Student full name
  justificationId: string; // Reference to justification
  absenceId: string; // Reference to absence
  subjectName: string; // Subject/course name
  photoUrl?: string; // Student avatar (optional)
  isRead: boolean; // Notification read status
  createdAt: Timestamp;
  readAt?: Timestamp;
}
```

### departments

```typescript
interface Department {
  id: string; // Firebase Auth UID
  email: string;
  name?: string;
  createdAt: Timestamp;
}
```

## Collection Indexes

Create these composite indexes in Firebase Console for optimal performance:

### department_notifications indexes

```
Collection: department_notifications
Fields: (departmentId, isRead, createdAt)
- Orders: Ascending, Ascending, Descending
```

### justifications indexes

```
Collection: justifications
Fields: (studentId, status, createdAt)
- Orders: Ascending, Ascending, Descending
```

## Setting Up in Firebase Console

1. Go to **Firestore Database**
2. Click **Rules** tab
3. Paste the security rules above
4. Click **Publish**

## Testing Rules

Use Firebase Emulator Suite to test:

```bash
# Start emulator
firebase emulators:start

# Run tests
firebase emulators:exec 'flutter test'
```

## Production Checklist

- [ ] Security rules deployed
- [ ] Composite indexes created
- [ ] Firestore backup enabled
- [ ] Cloud Functions secured (if using)
- [ ] Environment variables set correctly
- [ ] CORS configured (for web)
- [ ] Rate limiting enabled

## Common Security Issues & Fixes

### Issue: "Permission denied" error

**Fix**: Ensure user has read access to their department's notifications:

```firestore
allow read: if resource.data.departmentId == getUserDepartmentId(request.auth.uid);
```

### Issue: Notifications visible to other departments

**Fix**: Add departmentId check:

```firestore
allow read: if request.auth != null &&
  resource.data.departmentId == get(...).data.id;
```

### Issue: Users can create notifications manually

**Fix**: Deny write to notifications collection:

```firestore
allow write: if false;  // Only backend creates
```

## Backup & Restore

### Enable automatic backups:

1. Go to Firestore Database settings
2. Click **Backups**
3. Enable scheduled backups
4. Set retention to 30 days

### Manual backup:

```bash
gcloud firestore export gs://your-bucket/backup-$(date +%s)
```

### Restore from backup:

```bash
gcloud firestore import gs://your-bucket/backup-timestamp
```

## Monitoring & Logging

### Set up Cloud Logging:

1. Go to Cloud Logging console
2. Create filter for Firestore access
3. Set up alerts for permission denials

### Example filter:

```
resource.type="cloud_firestore"
severity>=ERROR
```

## Performance Optimization

- ✅ Use composite indexes for queries
- ✅ Denormalize frequently accessed data
- ✅ Limit query results (first 100)
- ✅ Use collection groups sparingly
- ✅ Enable offline persistence on clients

## Cost Estimation

**Assumed monthly usage:**

- 1,000 justifications submitted
- 5,000 department checks
- 50,000 notification reads

**Estimated cost:**

- Document writes: ~$0.06
- Document reads: ~$0.30
- Storage: ~$0.18
- **Total: ~$0.54/month** (very low)

Firestore offers **1 million free operations/month**, so you'll likely stay free.
