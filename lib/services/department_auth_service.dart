import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test/firebase_options.dart';
import 'package:test/models/app_user_profile.dart';

class DepartmentAuthService {
  DepartmentAuthService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _secondaryAppName = 'department_user_management';
  static const String _profilesCollection = 'user_profiles';

  final FirebaseFirestore _firestore;
  static Future<FirebaseAuth>? _secondaryAuthFuture;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection(_profilesCollection);

  String _linkedCollectionForRole(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return 'students';
      case 'teacher':
        return 'teachers';
      case 'department':
        return 'department_admins';
      default:
        return 'users';
    }
  }

  Future<FirebaseAuth> _secondaryAuth() async {
    final existingFuture = _secondaryAuthFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final future = () async {
      FirebaseApp? existingApp;
      for (final app in Firebase.apps) {
        if (app.name == _secondaryAppName) {
          existingApp = app;
          break;
        }
      }

      final app =
          existingApp ??
          await Firebase.initializeApp(
            name: _secondaryAppName,
            options: DefaultFirebaseOptions.currentPlatform,
          );
      return FirebaseAuth.instanceFor(app: app);
    }();

    _secondaryAuthFuture = future;
    try {
      return await future;
    } catch (_) {
      _secondaryAuthFuture = null;
      rethrow;
    }
  }

  Future<String> createManagedAccount({
    required String email,
    required String password,
  }) async {
    final auth = await _secondaryAuth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Unable to create authentication account.',
      );
    }
    return user.uid;
  }

  Future<void> saveUserProfile(AppUserProfile profile) async {
    await _profiles.doc(profile.uid).set({
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createDepartmentAccount({
    required String email,
    required String password,
    String displayName = 'Department Admin',
  }) async {
    final authUid = await createManagedAccount(
      email: email,
      password: password,
    );
    try {
      await saveUserProfile(
        AppUserProfile(
          uid: authUid,
          email: email,
          role: 'Department',
          displayName: displayName,
          linkedCollection: 'department_admins',
          linkedDocumentId: authUid,
        ),
      );


     // fix her 

      await signOutManagedAccount();


    } catch (_) {
      
      await deletePendingManagedAccount();
      rethrow;
    }
  }

  Future<void> ensureDepartmentProfileForCredentials({
    required String email,
    required String password,
    String displayName = 'Department Admin',
  }) async {
    final auth = FirebaseAuth.instance;
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to find account for this email.',
      );
    }

    final snapshot = await _profiles.doc(user.uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      await saveUserProfile(
        AppUserProfile(
          uid: user.uid,
          email: email,
          role: 'Department',
          displayName: displayName,
          linkedCollection: 'department_admins',
          linkedDocumentId: user.uid,
        ),
      );
    }
  }

  Future<AppUserProfile> signInWithRole({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    final auth = FirebaseAuth.instance;
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to sign in.',
      );
    }

    var snapshot = await _profiles.doc(user.uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      final role = expectedRole.trim();
      await saveUserProfile(
        AppUserProfile(
          uid: user.uid,
          email: user.email?.trim() ?? email.trim(),
          role: role,
          displayName: role == 'Department' ? 'Department Admin' : role,
          linkedCollection: _linkedCollectionForRole(role),
          linkedDocumentId: user.uid,
        ),
      );
      snapshot = await _profiles.doc(user.uid).get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw FirebaseAuthException(
          code: 'profile-not-found',
          message: 'No role profile was found for this account.',
        );
      }
    }

    final profile = AppUserProfile.fromMap(user.uid, snapshot.data()!);
    if (profile.role.toLowerCase() != expectedRole.toLowerCase()) {
      if (expectedRole.trim().toLowerCase() == 'department') {
        final repaired = AppUserProfile(
          uid: profile.uid,
          email: profile.email.isNotEmpty
              ? profile.email
              : (user.email?.trim() ?? email.trim()),
          role: 'Department',
          displayName: profile.displayName.isNotEmpty
              ? profile.displayName
              : 'Department Admin',
          linkedCollection: 'department_admins',
          linkedDocumentId: profile.linkedDocumentId.isNotEmpty
              ? profile.linkedDocumentId
              : user.uid,
        );
        await saveUserProfile(repaired);
        return repaired;
      }
      await auth.signOut();
      throw FirebaseAuthException(
        code: 'wrong-role',
        message: 'This account is registered as ${profile.role}.',
      );
    }

    return profile;
  }

  Future<void> deletePendingManagedAccount() async {
    final auth = await _secondaryAuth();
    final user = auth.currentUser;
    if (user != null) {
      await user.delete();
    }
    await auth.signOut();
  }

  Future<void> signOutManagedAccount() async {
    final auth = await _secondaryAuth();
    await auth.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
