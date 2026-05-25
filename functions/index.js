const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp();
const db = admin.firestore();

async function getStudentTokens(studentId) {
  const normalized = String(studentId || '').trim();
  if (!normalized) return [];

  const candidates = [];

  const directDoc = await db.collection('students').doc(normalized).get();
  if (directDoc.exists) {
    const data = directDoc.data() || {};
    if (Array.isArray(data.fcmTokens)) candidates.push(...data.fcmTokens);
    if (typeof data.fcmToken === 'string') candidates.push(data.fcmToken);
  }

  const byAuthUid = await db
    .collection('students')
    .where('authUid', '==', normalized)
    .limit(10)
    .get();

  for (const doc of byAuthUid.docs) {
    const data = doc.data() || {};
    if (Array.isArray(data.fcmTokens)) candidates.push(...data.fcmTokens);
    if (typeof data.fcmToken === 'string') candidates.push(data.fcmToken);
  }

  return [...new Set(candidates.map((token) => String(token || '').trim()).filter(Boolean))];
}

async function sendPushToStudent(studentId, payload) {
  const tokens = await getStudentTokens(studentId);
  if (!tokens.length) {
    console.log(`[push] No FCM tokens found for student ${studentId}`);
    return;
  }

  const message = {
    tokens,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: Object.fromEntries(
      Object.entries(payload.data || {}).map(([key, value]) => [key, String(value)]),
    ),
    android: {
      priority: 'high',
      notification: {
        channelId: 'hodoori_notifications',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);
  console.log(
    `[push] Sent to student ${studentId}: success=${response.successCount}, failure=${response.failureCount}`,
  );
}

function formatDateParts(value) {
  const date = value instanceof admin.firestore.Timestamp
    ? value.toDate()
    : value instanceof Date
      ? value
      : new Date();

  return {
    date: date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    }),
    time: date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
    }),
    iso: date.toISOString(),
  };
}

exports.onAbsenceCreated = functions.firestore
  .document('absences/{absenceId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const studentId = String(data.studentId || '').trim();
    if (!studentId) {
      console.log(
        `[absence] Skipping notification creation for absence ${context.params.absenceId}: missing studentId`,
      );
      return;
    }

    const subjectName = String(data.subjectName || data.courseName || 'your subject').trim();
    const teacherName = String(data.teacherName || 'your teacher').trim();
    const groupName = String(data.groupName || data.groupId || 'your group').trim();
    const teacherId = String(data.teacherId || '').trim();
    const subjectId = String(data.subjectId || '').trim();
    const groupId = String(data.groupId || '').trim();
    const absenceDate = data.createdAt || data.absenceDate || snap.createTime;
    const when = formatDateParts(absenceDate);
    const reminder = data.deadlineAt
      ? 'Please submit a justification before the 72-hour deadline.'
      : 'Please submit a justification if this absence is incorrect.';

    await db.collection('notifications').add({
      studentId,
      receiverId: studentId,
      receiverType: 'student',
      senderId: teacherId,
      teacherId,
      teacherName,
      subjectId,
      subjectName,
      groupId,
      groupName,
      absenceStatus: 'absent',
      type: 'absencerecorded',
      title: 'Absence Recorded',
      message:
        `You were marked absent in ${subjectName} by ${teacherName} for ${groupName} on ${when.date} at ${when.time}. ${reminder}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      occurrenceAtIso: when.iso,
      isRead: false,
      relatedAbsenceId: context.params.absenceId,
      notificationSource: 'absence_created',
    });
  });

exports.onNotificationCreated = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const studentId = data.studentId || '';
    const title = data.title || 'Notification';
    const body = data.message || '';

    await sendPushToStudent(studentId, {
      title,
      body,
      data: {
        type: data.type || 'other',
        notificationId: context.params.notificationId,
        studentId,
        relatedAbsenceId: data.relatedAbsenceId || '',
        relatedJustificationId: data.relatedJustificationId || '',
        relatedExclusionId: data.relatedExclusionId || '',
      },
    });
  });
