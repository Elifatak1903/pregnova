// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PregNova';

  @override
  String get home => 'Home';

  @override
  String get messages => 'Messages';

  @override
  String get message => 'Message';

  @override
  String get account => 'Account';

  @override
  String get accountSettingsSubtitle =>
      'You can manage your account settings here';

  @override
  String get accountShort => 'Account';

  @override
  String get logout => 'Logout';

  @override
  String get logoutAction => 'Log Out';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get loading => 'Loading...';

  @override
  String get searchExpert => 'Find Expert';

  @override
  String get diet => 'Diet';

  @override
  String get clients => 'Clients';

  @override
  String get requests => 'Requests';

  @override
  String get changePassword => 'Change Password';

  @override
  String get editInfo => 'Edit Information';

  @override
  String get expertiseInfo => 'Professional Information';

  @override
  String get expertiseArea => 'Specialty';

  @override
  String get experience => 'Experience';

  @override
  String get institution => 'Institution';

  @override
  String get licenseNumber => 'License No';

  @override
  String get diplomaDocuments => 'Diploma / Documents';

  @override
  String get diplomaUploaded => 'Diploma uploaded';

  @override
  String get noDiplomaAdded => 'No diploma has been added yet';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get turkish => 'Turkish';

  @override
  String get english => 'English';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get pregnancyInfoTitle => 'Pregnancy Information';

  @override
  String get pregnancyInfoPrompt =>
      'Would you like to fill in your pregnancy information?\n\nThis helps us provide more accurate recommendations for you.';

  @override
  String get later => 'Later';

  @override
  String get fillNow => 'Fill Now';

  @override
  String weeklyInfoTitle(int week) {
    return 'Week $week Information';
  }

  @override
  String get weeklyInfoMessage =>
      'Your need for iron and protein increases this week. Pay attention to your nutrition.';

  @override
  String get welcomeMother => 'Welcome, mom';

  @override
  String get pregnantHomeSubtitle =>
      'You can easily track your health and nutrition.';

  @override
  String get current => 'Current';

  @override
  String pregnancyWeek(Object week) {
    return 'Week $week';
  }

  @override
  String get riskMeasurement => 'Risk Measurement';

  @override
  String get nutritionAnalysis => 'Nutrition Analysis';

  @override
  String get lastMeasurementHistory => 'Measurement History';

  @override
  String get nutritionSupplementHistory => 'Nutrition & Supplement History';

  @override
  String get latestRiskStatus => 'Latest Risk Status';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get riskTrackingForm => 'Risk Tracking Form';

  @override
  String get riskResult => 'Risk Result';

  @override
  String get ok => 'OK';

  @override
  String get saved => 'Saved';

  @override
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get diastolicMustBeLower =>
      'Diastolic pressure must be lower than systolic pressure';

  @override
  String get riskDataSaved => 'Risk data saved';

  @override
  String get currentWeightKg => 'Current Weight (kg)';

  @override
  String get preeklampsiTracking => 'Preeclampsia Tracking';

  @override
  String get systolicExample => 'Systolic (Example: 120)';

  @override
  String get diastolicExample => 'Diastolic (Example: 80)';

  @override
  String get severeHeadache => 'Severe headache';

  @override
  String get visionProblem => 'Vision problem';

  @override
  String get handFaceSwelling => 'Hand/face swelling';

  @override
  String get gestationalDiabetes => 'Gestational Diabetes';

  @override
  String get fastingBloodSugar => 'Fasting blood sugar';

  @override
  String get postMealBloodSugar => 'Post-meal blood sugar';

  @override
  String get excessiveThirst => 'Excessive thirst';

  @override
  String get frequentUrination => 'Frequent urination';

  @override
  String get pretermRisk => 'Preterm Risk';

  @override
  String get contraction => 'Abdominal contraction';

  @override
  String get increasedDischarge => 'Increased discharge';

  @override
  String get backPain => 'Back pain';

  @override
  String get stressLevel => 'Stress Level';

  @override
  String get requiredField => 'This field cannot be empty';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String enterValidValueExample(Object example) {
    return 'Enter a valid value (example: $example)';
  }

  @override
  String get riskHistory => 'Risk History';

  @override
  String get noRiskRecordYet => 'No risk record yet';

  @override
  String get bloodPressure => 'Blood Pressure';

  @override
  String get riskOutcome => 'Risk Result';

  @override
  String get fasting => 'Fasting';

  @override
  String get postMeal => 'Post-meal';

  @override
  String get preterm => 'Preterm';

  @override
  String get stress => 'Stress';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get nutritionSupplementAnalysis => 'Nutrition and Supplement Analysis';

  @override
  String get foodEntry => 'Food Entry';

  @override
  String get foodName => 'Food Name';

  @override
  String get amount => 'Amount';

  @override
  String get addFood => 'Add Food';

  @override
  String get supplementEntry => 'Supplement Entry';

  @override
  String get supplementName => 'Supplement Name';

  @override
  String get addSupplement => 'Add Supplement';

  @override
  String get enteredFoods => 'Entered Foods';

  @override
  String get enteredSupplements => 'Entered Supplements';

  @override
  String get saveDay => 'Save Day';

  @override
  String get noDietitianAssigned => 'No dietitian has been assigned yet';

  @override
  String get consumedNutrients => 'Consumed Nutrients';

  @override
  String get missingNutrients => 'Missing Nutrients';

  @override
  String get excessNutrients => 'Excess Nutrients';

  @override
  String get noItemsYet => 'No items added yet';

  @override
  String get noRecordYet => 'No records yet';

  @override
  String get dailyTotalAnalysisResult => 'Daily Total Analysis Result';

  @override
  String totalCalories(Object calories) {
    return 'Total Calories: $calories kcal';
  }

  @override
  String analysisWithTime(int index, String time) {
    return '$index. Analysis - $time';
  }

  @override
  String calories(Object calories) {
    return 'Calories: $calories kcal';
  }

  @override
  String get profileInfo => 'Profile Information';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get age => 'Age';

  @override
  String get ageRangeValidation => 'Enter an age between 15 and 50';

  @override
  String get pregnancyWeekInput => 'Pregnancy Week';

  @override
  String get pregnancyWeekRangeValidation => 'Enter a week between 1 and 42';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get allergies => 'Allergies';

  @override
  String get allergiesExample => 'Allergies (e.g. peanuts, milk)';

  @override
  String get riskFactors => 'Risk Factors';

  @override
  String get chronicRiskFactors => 'Chronic / Risk Factors';

  @override
  String get chronicHypertension => 'Chronic Hypertension';

  @override
  String get thyroidDisease => 'Thyroid Disease';

  @override
  String get previousPretermBirth => 'Previous Preterm Birth';

  @override
  String get previousPreterm => 'Previous Preterm';

  @override
  String get multiplePregnancy => 'Multiple Pregnancy';

  @override
  String get multiplePregnancyDetail => 'Multiple Pregnancy (twins, etc.)';

  @override
  String get smoking => 'Smoking';

  @override
  String get smokingUse => 'Smoking';

  @override
  String get saveAndContinue => 'Save and Continue';

  @override
  String get infoUpdated => 'Information updated';

  @override
  String errorOccurredWithMessage(Object message) {
    return 'An error occurred: $message';
  }

  @override
  String get dataNotFound => 'Data not found';

  @override
  String get exists => 'Yes';

  @override
  String get notExists => 'No';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get chooseSuitableExpert => 'Choose the expert that fits you';

  @override
  String get searchNameHint => 'Search by name...';

  @override
  String get all => 'All';

  @override
  String get dietitian => 'Dietitian';

  @override
  String get gynecologist => 'Gynecologist';

  @override
  String get expert => 'Expert';

  @override
  String get noInstitutionInfo => 'No institution information';

  @override
  String get assignedClient => 'Client';

  @override
  String get pending => 'Pending';

  @override
  String get request => 'Request';

  @override
  String get requestSent => 'Request sent';

  @override
  String get noExpertYet => 'No expert assigned yet';

  @override
  String get doctor => 'Doctor';

  @override
  String get writeMessage => 'Write a message...';

  @override
  String get notifications => 'Notifications';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String secondsAgo(int count) {
    return '$count sec ago';
  }

  @override
  String get selectClient => 'Select Client';

  @override
  String get noClientFound => 'No client found';

  @override
  String get recentAnalyses => 'Recent Analyses';

  @override
  String get noAnalysisLast7Days => 'No analyses in the last 7 days';

  @override
  String get recentMeasurements => 'Recent Measurements';

  @override
  String get noRecords => 'No records';

  @override
  String get detailedReview => 'Review Details';

  @override
  String get noData => 'No data';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get pendingRequest => 'Pending Request';

  @override
  String get patientId => 'Patient ID';

  @override
  String get requestId => 'Request ID';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get heightWeight => 'Height/Weight';

  @override
  String get bmi => 'BMI';

  @override
  String get risk => 'Risk';

  @override
  String get allergy => 'Allergy';

  @override
  String weekLabel(Object week) {
    return 'Week $week';
  }

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get welcomeTitle => 'Welcome to PregNova';

  @override
  String get welcomeSubtitle =>
      'Track your pregnancy journey with confidence.\nHealth, nutrition, and exercise in one place';

  @override
  String get getStarted => 'Get Started';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Register';

  @override
  String get emailField => 'Email';

  @override
  String get password => 'Password';

  @override
  String get noAccountRegister => 'Don\'t have an account? Register';

  @override
  String get loginError => 'Login error';

  @override
  String get fullName => 'Full Name';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get emailAlreadyInUse => 'This email is already registered';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get weakPassword => 'Password is too weak';

  @override
  String get registerFailed => 'Registration failed';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get gynecologistPanel => 'Gynecologist Panel';

  @override
  String get highRisk => 'High Risk';

  @override
  String get mediumRisk => 'Medium Risk';

  @override
  String get normalRisk => 'Normal';

  @override
  String get riskStatus => 'Risk Status';

  @override
  String get highRiskPatientWarning => 'High-risk patient alert';

  @override
  String highRiskPatientCount(Object count) {
    return 'High risk detected in $count patient(s).';
  }

  @override
  String get review => 'Review';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String activeThisWeekSummary(Object measurements, Object patients) {
    return '$measurements measurement(s)\n$patients patient(s)';
  }

  @override
  String get consultationRequests => 'Consultation Requests';

  @override
  String get recentActivities => 'Recent Activities';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String newMeasurementSent(String name) {
    return '$name sent a new measurement';
  }

  @override
  String get noClientsYet => 'No clients yet';

  @override
  String get riskDistribution => 'Risk Distribution';

  @override
  String get documentPreviewUnavailable =>
      'Document preview is unavailable. If the file is a PDF, it can be opened as a link from the web panel.';

  @override
  String get dietitianPanel => 'Dietitian Panel';

  @override
  String get activeLast7Days => 'Active Last 7 Days';

  @override
  String get nutritionModule => 'Nutrition Module';

  @override
  String get open => 'Open';

  @override
  String newAnalysisSent(String name) {
    return '$name sent a new analysis';
  }

  @override
  String get noDate => 'No date';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'New Password (Confirm)';

  @override
  String get enterCurrentPassword => 'Enter your current password';

  @override
  String get enterNewPassword => 'Enter your new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordUpdated => 'Password updated successfully';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get genericError => 'An error occurred.';

  @override
  String get wrongCurrentPassword => 'Current password is incorrect.';

  @override
  String get newPasswordWeak => 'New password is too weak.';

  @override
  String get recentLoginRequired => 'Please log in again.';

  @override
  String get expertApplication => 'Expert Application';

  @override
  String get uploadDocumentPrompt => 'Please upload a document';

  @override
  String get applicationAlreadyPending =>
      'Your application is already under review';

  @override
  String get alreadyExpert => 'You are already an expert!';

  @override
  String get expertApplicationReceivedTitle => 'Expert Application Received';

  @override
  String get expertApplicationReceivedMessage =>
      'Your application has been received. Waiting for admin approval';

  @override
  String get applicationReceived => 'Your application has been received';

  @override
  String get applicationPendingStatus => 'Your application is under review...';

  @override
  String get applicationApprovedStatus => 'You are already an expert!';

  @override
  String get applicationRejectedStatus =>
      'Your application was rejected. You can try again.';

  @override
  String get licenseRegistryNumber => 'License / Registry No';

  @override
  String get city => 'City';

  @override
  String get uploadDocument => 'Upload Document';

  @override
  String selectedFileName(String fileName) {
    return 'Selected file: $fileName';
  }

  @override
  String get submitApplication => 'Submit Application';

  @override
  String get expertApplications => 'Expert Applications';

  @override
  String get applicationDetail => 'Application Detail';

  @override
  String get viewDiploma => 'View Diploma';

  @override
  String get diploma => 'Diploma';

  @override
  String get noDiplomaDocument => 'No diploma/document found';

  @override
  String get approve => 'Approve';

  @override
  String get applicationRejected => 'Application rejected';

  @override
  String get expertApproved => 'Expert approved';

  @override
  String get applicationApprovedNotificationTitle =>
      'Your Application Was Approved';

  @override
  String get applicationApprovedNotificationMessage =>
      'You can now log in to PregNova as an expert.';

  @override
  String get noApplicationFound => 'No application found';

  @override
  String noApplicationsWithStatus(String status) {
    return 'No $status applications';
  }

  @override
  String get approvedStatus => 'Approved';

  @override
  String get rejectedStatus => 'Rejected';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get role => 'Role';

  @override
  String get status => 'Status';

  @override
  String get applicationApproved => 'Application approved';

  @override
  String get applicationRejectedShort => 'Application rejected';

  @override
  String get applicationPending => 'Application pending';

  @override
  String approvalError(Object message) {
    return 'Approval error: $message';
  }

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get welcomeAdmin => 'Welcome, Admin';

  @override
  String get systemTrackingApprovalManagement =>
      'System tracking and approval management';

  @override
  String get pendingApplication => 'Pending\nApplication';

  @override
  String get totalUsers => 'Total\nUsers';

  @override
  String get activeExpert => 'Active\nExperts';

  @override
  String get systemReports => 'System\nReports';

  @override
  String get adminActions => 'Admin Actions';

  @override
  String get expertApplicationsActionSubtitle =>
      'Approve or reject expert applications';

  @override
  String get userManagement => 'User Management';

  @override
  String get viewAllUsers => 'View all users';

  @override
  String get users => 'Users';

  @override
  String get searchUser => 'Search users...';

  @override
  String get pregnantRole => 'Pregnant';

  @override
  String get doctorRole => 'Doctor';

  @override
  String get userFallback => 'User';

  @override
  String get createdAt => 'Created At';

  @override
  String get refresh => 'Refresh';

  @override
  String get systemSummary => 'System Summary';

  @override
  String get noRiskData => 'No risk data';

  @override
  String get riskRateNeedsAttention => 'High-risk rate requires attention.';

  @override
  String get riskRateIncreasing => 'An increase in risk rate is observed.';

  @override
  String get systemStable => 'The system is stable.';

  @override
  String get totalRiskMeasurements => 'Total risk measurements';

  @override
  String get totalNutritionAnalyses => 'Total nutrition analyses';

  @override
  String get pendingExpertApplications => 'Pending expert applications';

  @override
  String get approvedExpertApplications => 'Approved expert applications';

  @override
  String get rejectedExpertApplications => 'Rejected expert applications';

  @override
  String get lowRisk => 'Low Risk';

  @override
  String get systemInsight => 'System Insight';

  @override
  String highRiskPercent(String percent) {
    return 'High-risk rate: $percent%';
  }

  @override
  String get createDietPlan => 'Create Diet Plan';

  @override
  String get dietPlanSaved => 'Diet plan saved';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get snack1 => 'Snack 1';

  @override
  String get lunch => 'Lunch';

  @override
  String get snack2 => 'Snack 2';

  @override
  String get dinner => 'Dinner';

  @override
  String get nightSnack => 'Night Snack';

  @override
  String get notes => 'Notes';

  @override
  String writeFieldHint(String field) {
    return 'Write $field...';
  }

  @override
  String get patientDetail => 'Patient Detail';

  @override
  String get clientDetail => 'Client Detail';

  @override
  String get last7DaysMeasurementCharts => 'Last 7 Days Measurement Charts';

  @override
  String get noMeasurementFound => 'No measurements found';

  @override
  String get viewDetailedClinicalAnalysis => 'View Detailed Clinical Analysis';

  @override
  String get bloodPressureChartSystolic => 'Blood Pressure Chart (Systolic)';

  @override
  String get bloodSugarFastingPostMeal => 'Blood Sugar (Fasting / Post-meal)';

  @override
  String get weightChangeChart => 'Weight Change Chart';

  @override
  String get personalHealthInfo => 'Personal Health Information';

  @override
  String get chronicDisease => 'Chronic Disease';

  @override
  String get hypertension => 'Hypertension';

  @override
  String get swelling => 'Swelling';

  @override
  String get discharge => 'Discharge';

  @override
  String get weightChart => 'Weight Chart';

  @override
  String get calorieChart => 'Calorie Chart';

  @override
  String get analysisHistory => 'Analysis History';

  @override
  String get noAnalysisYet => 'No analysis yet';

  @override
  String get dataCouldNotBeLoaded => 'Data could not be loaded';

  @override
  String dailyTotalCalories(Object calories) {
    return 'Daily Total: $calories kcal';
  }

  @override
  String get supplements => 'Supplements';

  @override
  String get nutritionAnalysisDetail => 'Nutrition Analysis Detail';

  @override
  String get analysisNotFound => 'Analysis not found';

  @override
  String get consumedFoods => 'Consumed Foods';

  @override
  String get noDietPlanYet => 'You do not have a diet plan yet';

  @override
  String get myDietPlan => 'My Diet Plan';

  @override
  String get viewCurrentDietPlan => 'View your current diet plan';

  @override
  String viewDietPlanButton(String date) {
    return '$date - View Diet';
  }

  @override
  String dietDetailWithDate(String date) {
    return 'Diet Detail - $date';
  }

  @override
  String get uploadDiploma => 'Upload Diploma';

  @override
  String get uploadError => 'Upload failed';

  @override
  String enterFieldHint(String field) {
    return 'Enter $field...';
  }

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get enterWeekInfo => 'Enter Week Information';

  @override
  String get whichPregnancyWeek => 'Which pregnancy week are you in?';

  @override
  String get pregnancyStart => 'Pregnancy Start';

  @override
  String welcomeUser(String user) {
    return 'Welcome, $user';
  }

  @override
  String get welcomeExpert => 'Welcome';

  @override
  String get missingNutrition => 'Missing Nutrition';

  @override
  String get riskyPatient => 'Risky Patient';

  @override
  String clientUid(String uid) {
    return 'Client UID: $uid';
  }
}
