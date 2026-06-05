import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SETTINGS'**
  String get accountSettings;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile:'**
  String get errorUpdatingProfile;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToAccess.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your medical reports'**
  String get signInToAccess;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinUsToOrganize.
  ///
  /// In en, this message translates to:
  /// **'Join us to organize your medical records'**
  String get joinUsToOrganize;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @pleaseEnterAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age'**
  String get pleaseEnterAge;

  /// No description provided for @medicalLicenseId.
  ///
  /// In en, this message translates to:
  /// **'Medical License ID'**
  String get medicalLicenseId;

  /// No description provided for @licenseIdRequired.
  ///
  /// In en, this message translates to:
  /// **'License ID is required'**
  String get licenseIdRequired;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty (e.g. Optometrist)'**
  String get specialty;

  /// No description provided for @specialtyRequired.
  ///
  /// In en, this message translates to:
  /// **'Specialty is required'**
  String get specialtyRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @atLeast6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters required'**
  String get atLeast6Chars;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @registerAsPatient.
  ///
  /// In en, this message translates to:
  /// **'Register as Patient'**
  String get registerAsPatient;

  /// No description provided for @registerAsDoctor.
  ///
  /// In en, this message translates to:
  /// **'Register as Doctor'**
  String get registerAsDoctor;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @loginHere.
  ///
  /// In en, this message translates to:
  /// **'Login here'**
  String get loginHere;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed'**
  String get registrationFailed;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @unknownErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownErrorOccurred;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'USER PROFILE'**
  String get userProfile;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get notLoggedIn;

  /// No description provided for @patientRecord.
  ///
  /// In en, this message translates to:
  /// **'Patient Record'**
  String get patientRecord;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATION PREFERENCES'**
  String get notificationPreferences;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get security;

  /// No description provided for @reportsHistory.
  ///
  /// In en, this message translates to:
  /// **'REPORTS HISTORY'**
  String get reportsHistory;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get logOut;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE: ARABIC'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE: ENGLISH'**
  String get languageEnglish;

  /// No description provided for @uploadNewReport.
  ///
  /// In en, this message translates to:
  /// **'UPLOAD NEW REPORT'**
  String get uploadNewReport;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'REPORT DETAILS'**
  String get reportDetails;

  /// No description provided for @reportDate.
  ///
  /// In en, this message translates to:
  /// **'Report Date'**
  String get reportDate;

  /// No description provided for @assignedDoctor.
  ///
  /// In en, this message translates to:
  /// **'Assigned Doctor'**
  String get assignedDoctor;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @fileUpload.
  ///
  /// In en, this message translates to:
  /// **'FILE UPLOAD'**
  String get fileUpload;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @cropReportMargin.
  ///
  /// In en, this message translates to:
  /// **'Crop Report Margin'**
  String get cropReportMargin;

  /// No description provided for @startUpload.
  ///
  /// In en, this message translates to:
  /// **'START UPLOAD'**
  String get startUpload;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload Failed'**
  String get uploadFailed;

  /// No description provided for @serverReturnedError.
  ///
  /// In en, this message translates to:
  /// **'The server returned an error:'**
  String get serverReturnedError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// No description provided for @couldNotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the analysis server.\n\nPlease check your internet connection.\n\nDetails:'**
  String get couldNotReachServer;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get cameraPermissionDenied;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navDrRec.
  ///
  /// In en, this message translates to:
  /// **'Dr Rec'**
  String get navDrRec;

  /// No description provided for @doctorRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Doctor Recommendations'**
  String get doctorRecommendations;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @analyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'ANALYTICS DASHBOARD'**
  String get analyticsDashboard;

  /// No description provided for @pleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in.'**
  String get pleaseLogIn;

  /// No description provided for @noDataScanFirst.
  ///
  /// In en, this message translates to:
  /// **'No data available. Scan a report first.'**
  String get noDataScanFirst;

  /// No description provided for @lastScan.
  ///
  /// In en, this message translates to:
  /// **'Last Scan:'**
  String get lastScan;

  /// No description provided for @aiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'AI Recommendations'**
  String get aiRecommendations;

  /// No description provided for @aiInsight.
  ///
  /// In en, this message translates to:
  /// **'AI Insight'**
  String get aiInsight;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tapToRead.
  ///
  /// In en, this message translates to:
  /// **'Tap to read'**
  String get tapToRead;

  /// No description provided for @aiSummaryRecorded.
  ///
  /// In en, this message translates to:
  /// **'AI Summary Recorded'**
  String get aiSummaryRecorded;

  /// No description provided for @biomarkerStability.
  ///
  /// In en, this message translates to:
  /// **'Biomarker Stability'**
  String get biomarkerStability;

  /// No description provided for @excellentStatus.
  ///
  /// In en, this message translates to:
  /// **'Excellent Status'**
  String get excellentStatus;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get needsAttention;

  /// No description provided for @outOf.
  ///
  /// In en, this message translates to:
  /// **'out of'**
  String get outOf;

  /// No description provided for @trackedMarkersNormal.
  ///
  /// In en, this message translates to:
  /// **'tracked markers are within normal reference ranges.'**
  String get trackedMarkersNormal;

  /// No description provided for @flaggedMarkers.
  ///
  /// In en, this message translates to:
  /// **'Flagged Markers'**
  String get flaggedMarkers;

  /// No description provided for @allMarkersNormal.
  ///
  /// In en, this message translates to:
  /// **'All tested markers are within normal limits.'**
  String get allMarkersNormal;

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'years ago'**
  String get yearsAgo;

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'months ago'**
  String get monthsAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @oneDayAgo.
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get oneDayAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutesAgo;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @reportAnalysis.
  ///
  /// In en, this message translates to:
  /// **'REPORT\nANALYSIS'**
  String get reportAnalysis;

  /// No description provided for @needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs Review.'**
  String get needsReview;

  /// No description provided for @highlyAccurate.
  ///
  /// In en, this message translates to:
  /// **'Highly Accurate.'**
  String get highlyAccurate;

  /// No description provided for @detectedValues.
  ///
  /// In en, this message translates to:
  /// **'Detected Values'**
  String get detectedValues;

  /// No description provided for @normalStatus.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalStatus;

  /// No description provided for @flaggedStatus.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get flaggedStatus;

  /// No description provided for @refRange.
  ///
  /// In en, this message translates to:
  /// **'Ref:'**
  String get refRange;

  /// No description provided for @aiClinicalSummary.
  ///
  /// In en, this message translates to:
  /// **'AI Clinical Summary'**
  String get aiClinicalSummary;

  /// No description provided for @readSummary.
  ///
  /// In en, this message translates to:
  /// **'Read Summary'**
  String get readSummary;

  /// No description provided for @noResultsReceived.
  ///
  /// In en, this message translates to:
  /// **'No results received from OCR.'**
  String get noResultsReceived;

  /// No description provided for @deleteReport.
  ///
  /// In en, this message translates to:
  /// **'Delete Report'**
  String get deleteReport;

  /// No description provided for @confirmDeleteReport.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this lab report permanently?'**
  String get confirmDeleteReport;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @reportDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report deleted successfully.'**
  String get reportDeletedSuccess;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete:'**
  String get failedToDelete;

  /// No description provided for @labResults.
  ///
  /// In en, this message translates to:
  /// **'LAB RESULTS'**
  String get labResults;

  /// No description provided for @errorFetchingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error fetching history'**
  String get errorFetchingHistory;

  /// No description provided for @noLabResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No Lab Results Found'**
  String get noLabResultsFound;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time:'**
  String get timeLabel;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get hello;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @readyToCheckHealth.
  ///
  /// In en, this message translates to:
  /// **'Ready to check your health?'**
  String get readyToCheckHealth;

  /// No description provided for @tapPlusToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button below to scan a new report.'**
  String get tapPlusToScan;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsTitle;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @alertsNewPredictions.
  ///
  /// In en, this message translates to:
  /// **'Alerts for new predictions'**
  String get alertsNewPredictions;

  /// No description provided for @soundVibration.
  ///
  /// In en, this message translates to:
  /// **'Sound & Vibration'**
  String get soundVibration;

  /// No description provided for @emailUpdates.
  ///
  /// In en, this message translates to:
  /// **'Email Updates'**
  String get emailUpdates;

  /// No description provided for @weeklySummaries.
  ///
  /// In en, this message translates to:
  /// **'Weekly account summaries'**
  String get weeklySummaries;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent!'**
  String get passwordResetSent;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get errorPrefix;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get securityTitle;

  /// No description provided for @authentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authentication;

  /// No description provided for @needChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Need to change your password?'**
  String get needChangePassword;

  /// No description provided for @sendPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Send Password Reset Email'**
  String get sendPasswordReset;

  /// No description provided for @dataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data Privacy'**
  String get dataPrivacy;

  /// No description provided for @dataSecured.
  ///
  /// In en, this message translates to:
  /// **'Your data is secured'**
  String get dataSecured;

  /// No description provided for @dataLocalized.
  ///
  /// In en, this message translates to:
  /// **'Data is localized on Firebase.'**
  String get dataLocalized;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
