import 'package:flutter/material.dart';

/// Main localization class with all translations
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _translations = {
    // ── General ──────────────────────────────────────────────────
    'appName': {'en': 'Hodoori', 'fr': 'Hodoori', 'ar': 'حضوري'},
    'save': {'en': 'Save', 'fr': 'Enregistrer', 'ar': 'حفظ'},
    'cancel': {'en': 'Cancel', 'fr': 'Annuler', 'ar': 'إلغاء'},
    'delete': {'en': 'Delete', 'fr': 'Supprimer', 'ar': 'حذف'},
    'edit': {'en': 'Edit', 'fr': 'Modifier', 'ar': 'تعديل'},
    'add': {'en': 'Add', 'fr': 'Ajouter', 'ar': 'إضافة'},
    'logout': {'en': 'Logout', 'fr': 'Déconnexion', 'ar': 'تسجيل الخروج'},
    'settings': {'en': 'Settings', 'fr': 'Paramètres', 'ar': 'الإعدادات'},
    'error': {'en': 'Error', 'fr': 'Erreur', 'ar': 'خطأ'},
    'success': {'en': 'Success', 'fr': 'Succès', 'ar': 'نجاح'},
    'loading': {
      'en': 'Loading...',
      'fr': 'Chargement...',
      'ar': 'جار التحميل...',
    },
    'noData': {
      'en': 'No data found.',
      'fr': 'Aucune donnée trouvée.',
      'ar': 'لا توجد بيانات.',
    },
    'confirm': {'en': 'Confirm', 'fr': 'Confirmer', 'ar': 'تأكيد'},
    'close': {'en': 'Close', 'fr': 'Fermer', 'ar': 'إغلاق'},
    'search': {'en': 'Search', 'fr': 'Rechercher', 'ar': 'بحث'},
    'notifications': {
      'en': 'Notifications',
      'fr': 'Notifications',
      'ar': 'الإشعارات',
    },

    // ── Navigation / Drawer ───────────────────────────────────────
    'home': {'en': 'Home', 'fr': 'Accueil', 'ar': 'الرئيسية'},
    'dashboard': {
      'en': 'Dashboard',
      'fr': 'Tableau de bord',
      'ar': 'لوحة التحكم',
    },
    'classes': {'en': 'Classes', 'fr': 'Classes', 'ar': 'الفصول'},
    'requests': {'en': 'Requests', 'fr': 'Demandes', 'ar': 'الطلبات'},
    'academicCurator': {
      'en': 'Academic Curator',
      'fr': 'Coordinateur Académique',
      'ar': 'المنسق الأكاديمي',
    },
    'departmentPortal': {
      'en': 'Department Portal',
      'fr': 'Portail du Département',
      'ar': 'بوابة القسم',
    },

    // ── Department Dashboard ──────────────────────────────────────
    'systemsOverview': {
      'en': 'Systems Overview',
      'fr': 'Vue d\'ensemble du système',
      'ar': 'نظرة عامة على النظام',
    },
    'generateReport': {
      'en': 'Generate Report',
      'fr': 'Générer un rapport',
      'ar': 'إنشاء تقرير',
    },
    'viewAuditLog': {
      'en': 'View Audit Log',
      'fr': 'Voir le journal d\'audit',
      'ar': 'عرض سجل التدقيق',
    },
    'weeklyTrends': {
      'en': 'Weekly Trends',
      'fr': 'Tendances hebdomadaires',
      'ar': 'الاتجاهات الأسبوعية',
    },
    'quickActions': {
      'en': 'Quick Actions',
      'fr': 'Actions rapides',
      'ar': 'إجراءات سريعة',
    },
    'students': {'en': 'Students', 'fr': 'Étudiants', 'ar': 'الطلاب'},
    'teachers': {'en': 'Teachers', 'fr': 'Enseignants', 'ar': 'الأساتذة'},
    'attendance': {'en': 'Attendance', 'fr': 'Présence', 'ar': 'الحضور'},

    // ── Student Management ────────────────────────────────────────
    'addStudent': {
      'en': 'Add Student',
      'fr': 'Ajouter un étudiant',
      'ar': 'إضافة طالب',
    },
    'viewStudents': {
      'en': 'View Students',
      'fr': 'Voir les étudiants',
      'ar': 'عرض الطلاب',
    },
    'addNewStudent': {
      'en': 'Add New Student',
      'fr': 'Ajouter un nouvel étudiant',
      'ar': 'إضافة طالب جديد',
    },
    'studentDetails': {
      'en': 'Student Details',
      'fr': 'Détails de l\'étudiant',
      'ar': 'تفاصيل الطالب',
    },
    'fullName': {'en': 'Full Name', 'fr': 'Nom complet', 'ar': 'الاسم الكامل'},
    'email': {'en': 'Email', 'fr': 'Email', 'ar': 'البريد الإلكتروني'},
    'password': {'en': 'Password', 'fr': 'Mot de passe', 'ar': 'كلمة المرور'},
    'confirmPassword': {
      'en': 'Confirm Password',
      'fr': 'Confirmer le mot de passe',
      'ar': 'تأكيد كلمة المرور',
    },
    'attendancePercent': {
      'en': 'Attendance %',
      'fr': 'Présence %',
      'ar': 'نسبة الحضور %',
    },
    'levelOfStudy': {
      'en': 'Level of Study',
      'fr': 'Niveau d\'étude',
      'ar': 'مستوى الدراسة',
    },
    'group': {'en': 'Group', 'fr': 'Groupe', 'ar': 'المجموعة'},
    'studentAddedSuccess': {
      'en': '✅ Student added successfully!',
      'fr': '✅ Étudiant ajouté avec succès!',
      'ar': '✅ تمت إضافة الطالب بنجاح!',
    },
    'studentDeletedSuccess': {
      'en': 'Student deleted successfully.',
      'fr': 'Étudiant supprimé avec succès.',
      'ar': 'تم حذف الطالب بنجاح.',
    },
    'studentUpdatedSuccess': {
      'en': 'Student updated successfully.',
      'fr': 'Étudiant mis à jour avec succès.',
      'ar': 'تم تحديث الطالب بنجاح.',
    },
    'deleteStudentConfirm': {
      'en': 'Delete student?',
      'fr': 'Supprimer l\'étudiant?',
      'ar': 'حذف الطالب؟',
    },
    'enterStudentInfo': {
      'en': 'Enter student information below',
      'fr': 'Entrez les informations de l\'étudiant ci-dessous',
      'ar': 'أدخل معلومات الطالب أدناه',
    },

    // ── Teacher Management ────────────────────────────────────────
    'addTeacher': {
      'en': 'Add Teacher',
      'fr': 'Ajouter un enseignant',
      'ar': 'إضافة أستاذ',
    },
    'viewTeachers': {
      'en': 'View Teachers',
      'fr': 'Voir les enseignants',
      'ar': 'عرض الأساتذة',
    },
    'addNewTeacher': {
      'en': 'Add New Teacher',
      'fr': 'Ajouter un nouvel enseignant',
      'ar': 'إضافة أستاذ جديد',
    },
    'teacherDetails': {
      'en': 'Teacher Details',
      'fr': 'Détails de l\'enseignant',
      'ar': 'تفاصيل الأستاذ',
    },
    'teacherAddedSuccess': {
      'en': 'Teacher added successfully!',
      'fr': 'Enseignant ajouté avec succès!',
      'ar': 'تمت إضافة الأستاذ بنجاح!',
    },
    'teacherDeletedSuccess': {
      'en': 'Teacher deleted successfully.',
      'fr': 'Enseignant supprimé avec succès.',
      'ar': 'تم حذف الأستاذ بنجاح.',
    },
    'teacherUpdatedSuccess': {
      'en': 'Teacher updated successfully.',
      'fr': 'Enseignant mis à jour avec succès.',
      'ar': 'تم تحديث الأستاذ بنجاح.',
    },
    'deleteTeacherConfirm': {
      'en': 'Delete teacher?',
      'fr': 'Supprimer l\'enseignant?',
      'ar': 'حذف الأستاذ؟',
    },
    'enterTeacherInfo': {
      'en': 'Enter teacher information below',
      'fr': 'Entrez les informations de l\'enseignant ci-dessous',
      'ar': 'أدخل معلومات الأستاذ أدناه',
    },
    'assignedGroups': {
      'en': 'Assigned Groups',
      'fr': 'Groupes assignés',
      'ar': 'المجموعات المعيّنة',
    },
    'subjects': {'en': 'Subjects', 'fr': 'Matières', 'ar': 'المواد'},

    // ── Subject Management ────────────────────────────────────────
    'addSubject': {
      'en': 'Add Subject',
      'fr': 'Ajouter une matière',
      'ar': 'إضافة مادة',
    },
    'viewSubjects': {
      'en': 'View Subjects',
      'fr': 'Voir les matières',
      'ar': 'عرض المواد',
    },
    'addNewSubject': {
      'en': 'Add New Subject',
      'fr': 'Ajouter une nouvelle matière',
      'ar': 'إضافة مادة جديدة',
    },
    'subjectDetails': {
      'en': 'Subject Details',
      'fr': 'Détails de la matière',
      'ar': 'تفاصيل المادة',
    },
    'subjectName': {
      'en': 'Subject Name',
      'fr': 'Nom de la matière',
      'ar': 'اسم المادة',
    },
    'subjectAddedSuccess': {
      'en': 'Subject created successfully!',
      'fr': 'Matière créée avec succès!',
      'ar': 'تم إنشاء المادة بنجاح!',
    },
    'subjectDeletedSuccess': {
      'en': 'Subject deleted successfully.',
      'fr': 'Matière supprimée avec succès.',
      'ar': 'تم حذف المادة بنجاح.',
    },
    'subjectUpdatedSuccess': {
      'en': 'Subject updated successfully.',
      'fr': 'Matière mise à jour avec succès.',
      'ar': 'تم تحديث المادة بنجاح.',
    },
    'deleteSubjectConfirm': {
      'en': 'Delete subject?',
      'fr': 'Supprimer la matière?',
      'ar': 'حذف المادة؟',
    },
    'assignTeacher': {
      'en': 'Assign Teacher (Optional)',
      'fr': 'Assigner un enseignant (Optionnel)',
      'ar': 'تعيين أستاذ (اختياري)',
    },
    'levels': {'en': 'Levels', 'fr': 'Niveaux', 'ar': 'المستويات'},

    // ── Groups ────────────────────────────────────────────────────
    'groups': {'en': 'Groups', 'fr': 'Groupes', 'ar': 'المجموعات'},
    'addGroup': {
      'en': 'Add Group',
      'fr': 'Ajouter un groupe',
      'ar': 'إضافة مجموعة',
    },
    'groupAddedSuccess': {
      'en': 'Group added successfully.',
      'fr': 'Groupe ajouté avec succès.',
      'ar': 'تمت إضافة المجموعة بنجاح.',
    },
    'groupName': {
      'en': 'Group name',
      'fr': 'Nom du groupe',
      'ar': 'اسم المجموعة',
    },
    'tapToViewStudents': {
      'en': 'Tap to view students',
      'fr': 'Appuyez pour voir les étudiants',
      'ar': 'اضغط لعرض الطلاب',
    },
    'tapToViewGroups': {
      'en': 'Tap to view available groups',
      'fr': 'Appuyez pour voir les groupes disponibles',
      'ar': 'اضغط لعرض المجموعات المتاحة',
    },

    // ── Justifications ────────────────────────────────────────────
    'viewJustification': {
      'en': 'View Justification',
      'fr': 'Voir la justification',
      'ar': 'عرض التبريرات',
    },
    'justificationRequests': {
      'en': 'Justification Requests',
      'fr': 'Demandes de justification',
      'ar': 'طلبات التبرير',
    },
    'approve': {'en': 'Approve', 'fr': 'Approuver', 'ar': 'قبول'},
    'reject': {'en': 'Reject', 'fr': 'Rejeter', 'ar': 'رفض'},
    'pending': {'en': 'PENDING', 'fr': 'EN ATTENTE', 'ar': 'قيد الانتظار'},
    'approved': {'en': 'APPROVED', 'fr': 'APPROUVÉ', 'ar': 'مقبول'},
    'rejected': {'en': 'REJECTED', 'fr': 'REJETÉ', 'ar': 'مرفوض'},
    'pendingRequests': {
      'en': 'pending requests',
      'fr': 'demandes en attente',
      'ar': 'طلبات معلقة',
    },
    'reason': {'en': 'Reason', 'fr': 'Raison', 'ar': 'السبب'},
    'attachment': {'en': 'Attachment', 'fr': 'Pièce jointe', 'ar': 'المرفق'},
    'viewFile': {'en': 'View file', 'fr': 'Voir le fichier', 'ar': 'عرض الملف'},
    'rejectionReason': {
      'en': 'Rejection reason (optional)',
      'fr': 'Raison du rejet (optionnel)',
      'ar': 'سبب الرفض (اختياري)',
    },
    'absenceDate': {'en': 'Absence', 'fr': 'Absence', 'ar': 'الغياب'},
    'submitted': {'en': 'Submitted', 'fr': 'Soumis', 'ar': 'تم الإرسال'},

    // ── Settings ──────────────────────────────────────────────────
    'accountSettings': {
      'en': 'Account Settings',
      'fr': 'Paramètres du compte',
      'ar': 'إعدادات الحساب',
    },
    'appSettings': {
      'en': 'App Settings',
      'fr': 'Paramètres de l\'application',
      'ar': 'إعدادات التطبيق',
    },
    'departmentSettings': {
      'en': 'Department Settings',
      'fr': 'Paramètres du département',
      'ar': 'إعدادات القسم',
    },
    'displayName': {
      'en': 'Display Name',
      'fr': 'Nom d\'affichage',
      'ar': 'اسم العرض',
    },
    'changeEmail': {
      'en': 'Change Email',
      'fr': 'Changer l\'email',
      'ar': 'تغيير البريد الإلكتروني',
    },
    'changePassword': {
      'en': 'Change Password',
      'fr': 'Changer le mot de passe',
      'ar': 'تغيير كلمة المرور',
    },
    'saveProfile': {
      'en': 'Save Profile',
      'fr': 'Enregistrer le profil',
      'ar': 'حفظ الملف الشخصي',
    },
    'language': {'en': 'Language', 'fr': 'Langue', 'ar': 'اللغة'},
    'darkMode': {'en': 'Dark Mode', 'fr': 'Mode sombre', 'ar': 'الوضع الداكن'},
    'switchToDarkTheme': {
      'en': 'Switch to dark theme',
      'fr': 'Passer au thème sombre',
      'ar': 'التبديل إلى الوضع الداكن',
    },
    'receiveAlerts': {
      'en': 'Receive alerts and updates',
      'fr': 'Recevoir des alertes et mises à jour',
      'ar': 'تلقي التنبيهات والتحديثات',
    },
    'universityName': {
      'en': 'University Name',
      'fr': 'Nom de l\'université',
      'ar': 'اسم الجامعة',
    },
    'academicYear': {
      'en': 'Academic Year',
      'fr': 'Année académique',
      'ar': 'السنة الدراسية',
    },
    'semester': {'en': 'Semester', 'fr': 'Semestre', 'ar': 'الفصل الدراسي'},
    'saveDepartmentSettings': {
      'en': 'Save Department Settings',
      'fr': 'Enregistrer les paramètres du département',
      'ar': 'حفظ إعدادات القسم',
    },
    'about': {'en': 'About', 'fr': 'À propos', 'ar': 'حول'},
    'appVersion': {
      'en': 'App Version',
      'fr': 'Version de l\'application',
      'ar': 'إصدار التطبيق',
    },
    'build': {'en': 'Build', 'fr': 'Version', 'ar': 'البنية'},
    'developer': {'en': 'Developer', 'fr': 'Développeur', 'ar': 'المطور'},
    'profileSavedSuccess': {
      'en': 'Profile saved successfully!',
      'fr': 'Profil enregistré avec succès!',
      'ar': 'تم حفظ الملف الشخصي بنجاح!',
    },
    'departmentSettingsSaved': {
      'en': 'Department settings saved!',
      'fr': 'Paramètres du département enregistrés!',
      'ar': 'تم حفظ إعدادات القسم!',
    },
    'passwordChangedSuccess': {
      'en': 'Password changed successfully!',
      'fr': 'Mot de passe changé avec succès!',
      'ar': 'تم تغيير كلمة المرور بنجاح!',
    },
    'verificationEmailSent': {
      'en': 'Verification link sent! Check your new email inbox.',
      'fr': 'Lien de vérification envoyé! Vérifiez votre nouvelle boîte mail.',
      'ar': 'تم إرسال رابط التحقق! تحقق من صندوق البريد الجديد.',
    },
    'currentPassword': {
      'en': 'Current Password',
      'fr': 'Mot de passe actuel',
      'ar': 'كلمة المرور الحالية',
    },
    'newPassword': {
      'en': 'New Password',
      'fr': 'Nouveau mot de passe',
      'ar': 'كلمة المرور الجديدة',
    },
    'newEmail': {
      'en': 'New Email',
      'fr': 'Nouvel email',
      'ar': 'البريد الإلكتروني الجديد',
    },
    'enterDisplayName': {
      'en': 'Enter your display name',
      'fr': 'Entrez votre nom d\'affichage',
      'ar': 'أدخل اسم العرض',
    },
    'enterUniversityName': {
      'en': 'Enter university name',
      'fr': 'Entrez le nom de l\'université',
      'ar': 'أدخل اسم الجامعة',
    },
    'settingsNotImplemented': {
      'en': 'Settings not implemented yet',
      'fr': 'Paramètres pas encore implémentés',
      'ar': 'الإعدادات غير مطبقة بعد',
    },

    // ── Student Management - Levels ───────────────────────────────
    'studentManagementLevels': {
      'en': 'Student Management - Levels',
      'fr': 'Gestion des étudiants - Niveaux',
      'ar': 'إدارة الطلاب - المستويات',
    },
    'chooseLevelToExplore': {
      'en': 'Choose a level to explore groups and students',
      'fr': 'Choisissez un niveau pour explorer les groupes et les étudiants',
      'ar': 'اختر مستوى لاستكشاف المجموعات والطلاب',
    },
    'noLevelsFound': {
      'en': 'No levels found yet.',
      'fr': 'Aucun niveau trouvé.',
      'ar': 'لم يتم العثور على مستويات.',
    },
    'couldNotLoadLevels': {
      'en': 'Could not load levels. Please check your connection.',
      'fr': 'Impossible de charger les niveaux. Vérifiez votre connexion.',
      'ar': 'تعذر تحميل المستويات. يرجى التحقق من اتصالك.',
    },
    'selectGroupIn': {
      'en': 'Select a group in',
      'fr': 'Sélectionnez un groupe dans',
      'ar': 'اختر مجموعة في',
    },
    'studentsFound': {
      'en': 'students found',
      'fr': 'étudiants trouvés',
      'ar': 'طلاب تم العثور عليهم',
    },
    'noGroupsFound': {
      'en': 'No groups found. Add one using + button.',
      'fr': 'Aucun groupe trouvé. Ajoutez-en un avec le bouton +.',
      'ar': 'لا توجد مجموعات. أضف واحدة باستخدام زر +.',
    },
    'noStudentsInGroup': {
      'en': 'No students in this group yet. Tap + to add one.',
      'fr': 'Aucun étudiant dans ce groupe. Appuyez sur + pour en ajouter.',
      'ar': 'لا يوجد طلاب في هذه المجموعة. اضغط + لإضافة طالب.',
    },
    'invalidLevelData': {
      'en': 'Unable to open groups: invalid level data.',
      'fr': 'Impossible d\'ouvrir les groupes: données de niveau invalides.',
      'ar': 'تعذر فتح المجموعات: بيانات المستوى غير صالحة.',
    },
    'invalidGroupData': {
      'en': 'Unable to open students: invalid group data.',
      'fr': 'Impossible d\'ouvrir les étudiants: données de groupe invalides.',
      'ar': 'تعذر فتح الطلاب: بيانات المجموعة غير صالحة.',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _translations[key]?[langCode] ?? _translations[key]?['en'] ?? key;
  }

  // ── Shorthand getters ─────────────────────────────────────────

  // General
  String get appName => translate('appName');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get logout => translate('logout');
  String get settings => translate('settings');
  String get error => translate('error');
  String get success => translate('success');
  String get loading => translate('loading');
  String get noData => translate('noData');
  String get confirm => translate('confirm');
  String get close => translate('close');
  String get search => translate('search');
  String get notifications => translate('notifications');

  // Navigation
  String get home => translate('home');
  String get dashboard => translate('dashboard');
  String get classes => translate('classes');
  String get requests => translate('requests');
  String get academicCurator => translate('academicCurator');
  String get departmentPortal => translate('departmentPortal');

  // Dashboard
  String get systemsOverview => translate('systemsOverview');
  String get generateReport => translate('generateReport');
  String get viewAuditLog => translate('viewAuditLog');
  String get weeklyTrends => translate('weeklyTrends');
  String get quickActions => translate('quickActions');
  String get students => translate('students');
  String get teachers => translate('teachers');
  String get attendance => translate('attendance');

  // Students
  String get addStudent => translate('addStudent');
  String get viewStudents => translate('viewStudents');
  String get addNewStudent => translate('addNewStudent');
  String get studentDetails => translate('studentDetails');
  String get fullName => translate('fullName');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get attendancePercent => translate('attendancePercent');
  String get levelOfStudy => translate('levelOfStudy');
  String get group => translate('group');
  String get studentAddedSuccess => translate('studentAddedSuccess');
  String get studentDeletedSuccess => translate('studentDeletedSuccess');
  String get studentUpdatedSuccess => translate('studentUpdatedSuccess');
  String get deleteStudentConfirm => translate('deleteStudentConfirm');
  String get enterStudentInfo => translate('enterStudentInfo');

  // Teachers
  String get addTeacher => translate('addTeacher');
  String get viewTeachers => translate('viewTeachers');
  String get addNewTeacher => translate('addNewTeacher');
  String get teacherDetails => translate('teacherDetails');
  String get teacherAddedSuccess => translate('teacherAddedSuccess');
  String get teacherDeletedSuccess => translate('teacherDeletedSuccess');
  String get teacherUpdatedSuccess => translate('teacherUpdatedSuccess');
  String get deleteTeacherConfirm => translate('deleteTeacherConfirm');
  String get enterTeacherInfo => translate('enterTeacherInfo');
  String get assignedGroups => translate('assignedGroups');
  String get subjects => translate('subjects');

  // Subjects
  String get addSubject => translate('addSubject');
  String get viewSubjects => translate('viewSubjects');
  String get addNewSubject => translate('addNewSubject');
  String get subjectDetails => translate('subjectDetails');
  String get subjectName => translate('subjectName');
  String get subjectAddedSuccess => translate('subjectAddedSuccess');
  String get subjectDeletedSuccess => translate('subjectDeletedSuccess');
  String get subjectUpdatedSuccess => translate('subjectUpdatedSuccess');
  String get deleteSubjectConfirm => translate('deleteSubjectConfirm');
  String get assignTeacher => translate('assignTeacher');
  String get levels => translate('levels');

  // Groups
  String get groups => translate('groups');
  String get addGroup => translate('addGroup');
  String get groupAddedSuccess => translate('groupAddedSuccess');
  String get groupName => translate('groupName');
  String get tapToViewStudents => translate('tapToViewStudents');
  String get tapToViewGroups => translate('tapToViewGroups');

  // Justifications
  String get viewJustification => translate('viewJustification');
  String get justificationRequests => translate('justificationRequests');
  String get approve => translate('approve');
  String get reject => translate('reject');
  String get pending => translate('pending');
  String get approved => translate('approved');
  String get rejected => translate('rejected');
  String get pendingRequests => translate('pendingRequests');
  String get reason => translate('reason');
  String get attachment => translate('attachment');
  String get viewFile => translate('viewFile');
  String get rejectionReason => translate('rejectionReason');
  String get absenceDate => translate('absenceDate');
  String get submitted => translate('submitted');

  // Settings
  String get accountSettings => translate('accountSettings');
  String get appSettings => translate('appSettings');
  String get departmentSettings => translate('departmentSettings');
  String get displayName => translate('displayName');
  String get changeEmail => translate('changeEmail');
  String get changePassword => translate('changePassword');
  String get saveProfile => translate('saveProfile');
  String get language => translate('language');
  String get darkMode => translate('darkMode');
  String get switchToDarkTheme => translate('switchToDarkTheme');
  String get receiveAlerts => translate('receiveAlerts');
  String get universityName => translate('universityName');
  String get academicYear => translate('academicYear');
  String get semester => translate('semester');
  String get saveDepartmentSettings => translate('saveDepartmentSettings');
  String get about => translate('about');
  String get appVersion => translate('appVersion');
  String get build => translate('build');
  String get developer => translate('developer');
  String get profileSavedSuccess => translate('profileSavedSuccess');
  String get departmentSettingsSaved => translate('departmentSettingsSaved');
  String get passwordChangedSuccess => translate('passwordChangedSuccess');
  String get verificationEmailSent => translate('verificationEmailSent');
  String get currentPassword => translate('currentPassword');
  String get newPassword => translate('newPassword');
  String get newEmail => translate('newEmail');
  String get enterDisplayName => translate('enterDisplayName');
  String get enterUniversityName => translate('enterUniversityName');
  String get settingsNotImplemented => translate('settingsNotImplemented');

  // Levels & Groups
  String get studentManagementLevels => translate('studentManagementLevels');
  String get chooseLevelToExplore => translate('chooseLevelToExplore');
  String get noLevelsFound => translate('noLevelsFound');
  String get couldNotLoadLevels => translate('couldNotLoadLevels');
  String get selectGroupIn => translate('selectGroupIn');
  String get studentsFound => translate('studentsFound');
  String get noGroupsFound => translate('noGroupsFound');
  String get noStudentsInGroup => translate('noStudentsInGroup');
  String get invalidLevelData => translate('invalidLevelData');
  String get invalidGroupData => translate('invalidGroupData');
}

/// Localizations delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => true;
}
