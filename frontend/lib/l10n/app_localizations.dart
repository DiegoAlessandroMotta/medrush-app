import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@medrush.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @capsLockActive.
  ///
  /// In en, this message translates to:
  /// **'Caps Lock is active'**
  String get capsLockActive;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @sessionExpiredWarning.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please login again.'**
  String get sessionExpiredWarning;

  /// No description provided for @downloadApkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download Android APP (APK)'**
  String get downloadApkTooltip;

  /// No description provided for @checkingConnection.
  ///
  /// In en, this message translates to:
  /// **'Checking server connection...'**
  String get checkingConnection;

  /// No description provided for @serverConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server'**
  String get serverConnectionError;

  /// No description provided for @deliveriesTab.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveriesTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @routeTab.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @searchOrders.
  ///
  /// In en, this message translates to:
  /// **'Search orders...'**
  String get searchOrders;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @deliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get deliver;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @noActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'You have no active orders'**
  String get noActiveOrders;

  /// No description provided for @activeOrdersDescription.
  ///
  /// In en, this message translates to:
  /// **'Assigned, picked up, and en-route orders will appear here'**
  String get activeOrdersDescription;

  /// No description provided for @cannotOpenNavigation.
  ///
  /// In en, this message translates to:
  /// **'Cannot open navigation'**
  String get cannotOpenNavigation;

  /// No description provided for @clientPhoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Client phone not available'**
  String get clientPhoneNotAvailable;

  /// No description provided for @cannotMakeCall.
  ///
  /// In en, this message translates to:
  /// **'Cannot make the call'**
  String get cannotMakeCall;

  /// No description provided for @infoCopied.
  ///
  /// In en, this message translates to:
  /// **'Information copied to clipboard'**
  String get infoCopied;

  /// No description provided for @errorCopyingInfo.
  ///
  /// In en, this message translates to:
  /// **'Error copying information'**
  String get errorCopyingInfo;

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error loading orders'**
  String get errorLoadingOrders;

  /// No description provided for @processingDelivery.
  ///
  /// In en, this message translates to:
  /// **'Processing delivery...'**
  String get processingDelivery;

  /// No description provided for @deliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery Details'**
  String get deliveryDetails;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID: '**
  String get orderIdLabel;

  /// No description provided for @clientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client: '**
  String get clientLabel;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String productsCount(num count);

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @proofOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Proof of Delivery'**
  String get proofOfDelivery;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noPhotoTaken.
  ///
  /// In en, this message translates to:
  /// **'No photo taken yet'**
  String get noPhotoTaken;

  /// No description provided for @takePhotoInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please take a photo of the delivered package.'**
  String get takePhotoInstruction;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signAndDeliver.
  ///
  /// In en, this message translates to:
  /// **'Sign and Deliver'**
  String get signAndDeliver;

  /// No description provided for @errorTakingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error taking photo: {error}'**
  String errorTakingPhoto(Object error);

  /// No description provided for @confirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get confirmDelivery;

  /// No description provided for @confirmDeliveryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm the delivery of this order?'**
  String get confirmDeliveryQuestion;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @deliverySuccess.
  ///
  /// In en, this message translates to:
  /// **'Order delivered successfully'**
  String get deliverySuccess;

  /// No description provided for @deliveryError.
  ///
  /// In en, this message translates to:
  /// **'Error delivering order: {error}'**
  String deliveryError(Object error);

  /// No description provided for @editDeliverySignature.
  ///
  /// In en, this message translates to:
  /// **'Edit Delivery Signature'**
  String get editDeliverySignature;

  /// No description provided for @deliverySignature.
  ///
  /// In en, this message translates to:
  /// **'Delivery Signature'**
  String get deliverySignature;

  /// No description provided for @sampleSignature.
  ///
  /// In en, this message translates to:
  /// **'Sample Signature'**
  String get sampleSignature;

  /// No description provided for @mustSignBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'You must sign before saving'**
  String get mustSignBeforeSaving;

  /// No description provided for @signatureSuccess.
  ///
  /// In en, this message translates to:
  /// **'{type, select, delivery{Delivery signature generated successfully} sample{Sample signature generated successfully} other{Signature generated successfully}}'**
  String signatureSuccess(String type);

  /// No description provided for @errorSavingSignature.
  ///
  /// In en, this message translates to:
  /// **'Error saving signature'**
  String get errorSavingSignature;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @professionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Professional Information'**
  String get professionalInfo;

  /// No description provided for @systemStatus.
  ///
  /// In en, this message translates to:
  /// **'System Status'**
  String get systemStatus;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

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

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deletePhoto;

  /// No description provided for @photoUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get photoUpdateSuccess;

  /// No description provided for @photoUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating photo'**
  String get photoUpdateError;

  /// No description provided for @photoSelectError.
  ///
  /// In en, this message translates to:
  /// **'Error selecting photo'**
  String get photoSelectError;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and the new password:'**
  String get changePasswordInstruction;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @minCharacters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get minCharacters;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the new password'**
  String get enterNewPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'The new password must be at least 8 characters long'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current one'**
  String get passwordMustBeDifferent;

  /// No description provided for @passwordUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdateSuccess;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @driverLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get driverLicense;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @driverStatus.
  ///
  /// In en, this message translates to:
  /// **'Driver Status'**
  String get driverStatus;

  /// No description provided for @activeUser.
  ///
  /// In en, this message translates to:
  /// **'Active User'**
  String get activeUser;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssigned;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @pharmaciesTab.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies'**
  String get pharmaciesTab;

  /// No description provided for @driversTab.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get driversTab;

  /// No description provided for @routesTab.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routesTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @registerDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Registration'**
  String get registerDriverTitle;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully. Please sign in.'**
  String get accountCreatedSuccess;

  /// No description provided for @errorRegistering.
  ///
  /// In en, this message translates to:
  /// **'Error registering: {error}'**
  String errorRegistering(Object error);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noUserAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'No user authenticated'**
  String get noUserAuthenticated;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry connection'**
  String get retryConnection;

  /// No description provided for @verifyConnectionAgain.
  ///
  /// In en, this message translates to:
  /// **'Verify connection again'**
  String get verifyConnectionAgain;

  /// No description provided for @connectedToServer.
  ///
  /// In en, this message translates to:
  /// **'Connected to server: {url}'**
  String connectedToServer(Object url);

  /// No description provided for @obtainingDownloadLink.
  ///
  /// In en, this message translates to:
  /// **'Obtaining download link...'**
  String get obtainingDownloadLink;

  /// No description provided for @couldNotGetDownloadLink.
  ///
  /// In en, this message translates to:
  /// **'Could not get download link'**
  String get couldNotGetDownloadLink;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started successfully'**
  String get downloadStarted;

  /// No description provided for @couldNotOpenDownloadLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open download link'**
  String get couldNotOpenDownloadLink;

  /// No description provided for @errorDownloadingApk.
  ///
  /// In en, this message translates to:
  /// **'Error downloading APK: {error}'**
  String errorDownloadingApk(Object error);

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error: {error}'**
  String connectionError(Object error);

  /// No description provided for @errorLoadingOrdersWithError.
  ///
  /// In en, this message translates to:
  /// **'Error loading orders: {error}'**
  String errorLoadingOrdersWithError(Object error);

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @callClient.
  ///
  /// In en, this message translates to:
  /// **'Call Client'**
  String get callClient;

  /// No description provided for @navigateToPickup.
  ///
  /// In en, this message translates to:
  /// **'Navigate to pickup'**
  String get navigateToPickup;

  /// No description provided for @navigateToDelivery.
  ///
  /// In en, this message translates to:
  /// **'Navigate to delivery'**
  String get navigateToDelivery;

  /// No description provided for @deliverWithoutSignature.
  ///
  /// In en, this message translates to:
  /// **'Deliver without signature'**
  String get deliverWithoutSignature;

  /// No description provided for @allOrdersLoaded.
  ///
  /// In en, this message translates to:
  /// **'All orders loaded'**
  String get allOrdersLoaded;

  /// No description provided for @loadingPage.
  ///
  /// In en, this message translates to:
  /// **'Loading page {current} of {total}...'**
  String loadingPage(Object current, Object total);

  /// No description provided for @errorDeletingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error deleting photo'**
  String get errorDeletingPhoto;

  /// No description provided for @errorLoadingHistoryWithError.
  ///
  /// In en, this message translates to:
  /// **'Error loading history: {error}'**
  String errorLoadingHistoryWithError(Object error);

  /// No description provided for @orderIdShort.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderIdShort;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2'**
  String get addressLine2;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// No description provided for @accessCode.
  ///
  /// In en, this message translates to:
  /// **'Access Code'**
  String get accessCode;

  /// No description provided for @buildingCode.
  ///
  /// In en, this message translates to:
  /// **'Building Code'**
  String get buildingCode;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @requiresSpecialSignature.
  ///
  /// In en, this message translates to:
  /// **'Requires special signature'**
  String get requiresSpecialSignature;

  /// No description provided for @assignmentDate.
  ///
  /// In en, this message translates to:
  /// **'Assignment Date'**
  String get assignmentDate;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @detailedLocation.
  ///
  /// In en, this message translates to:
  /// **'Detailed Location'**
  String get detailedLocation;

  /// No description provided for @pharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacy;

  /// No description provided for @pharmacyLocation.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy location'**
  String get pharmacyLocation;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @datesAndProgress.
  ///
  /// In en, this message translates to:
  /// **'Dates and Progress'**
  String get datesAndProgress;

  /// No description provided for @pickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup Date'**
  String get pickupDate;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery Date'**
  String get deliveryDate;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdate;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTime;

  /// No description provided for @estimatedDistance.
  ///
  /// In en, this message translates to:
  /// **'Estimated Distance'**
  String get estimatedDistance;

  /// No description provided for @observations.
  ///
  /// In en, this message translates to:
  /// **'Observations'**
  String get observations;

  /// No description provided for @deliveryProof.
  ///
  /// In en, this message translates to:
  /// **'Delivery Proof'**
  String get deliveryProof;

  /// No description provided for @deliveryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Delivery Photo'**
  String get deliveryPhoto;

  /// No description provided for @clientSignature.
  ///
  /// In en, this message translates to:
  /// **'Client Signature'**
  String get clientSignature;

  /// No description provided for @consentDocument.
  ///
  /// In en, this message translates to:
  /// **'Consent Document'**
  String get consentDocument;

  /// No description provided for @failureInfo.
  ///
  /// In en, this message translates to:
  /// **'Failure Information'**
  String get failureInfo;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @barcodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeTooltip;

  /// No description provided for @couldNotOpenDocument.
  ///
  /// In en, this message translates to:
  /// **'Could not open document'**
  String get couldNotOpenDocument;

  /// No description provided for @barcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeTitle;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderNumber;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @noOrdersToShow.
  ///
  /// In en, this message translates to:
  /// **'No orders to show'**
  String get noOrdersToShow;

  /// No description provided for @assignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver'**
  String get assignDriver;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @markAsFailed.
  ///
  /// In en, this message translates to:
  /// **'Mark as Failed'**
  String get markAsFailed;

  /// No description provided for @generateBarcode.
  ///
  /// In en, this message translates to:
  /// **'Generate Barcode'**
  String get generateBarcode;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @confirmDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery'**
  String get confirmDeliveryTitle;

  /// No description provided for @captureSignature.
  ///
  /// In en, this message translates to:
  /// **'Capture signature'**
  String get captureSignature;

  /// No description provided for @phoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone copied to clipboard'**
  String get phoneCopied;

  /// No description provided for @emailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email copied to clipboard'**
  String get emailCopied;

  /// No description provided for @clientHasNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Client has no email registered'**
  String get clientHasNoEmail;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps'**
  String get couldNotOpenMaps;

  /// No description provided for @deliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivery Status'**
  String get deliveryStatus;

  /// No description provided for @scheduledDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Scheduled deliveries'**
  String get scheduledDeliveries;

  /// No description provided for @navigateToPickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Navigate to pickup point'**
  String get navigateToPickupPoint;

  /// No description provided for @navigateToDeliveryPoint.
  ///
  /// In en, this message translates to:
  /// **'Navigate to delivery point'**
  String get navigateToDeliveryPoint;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: '**
  String get statusLabel;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @confirmDeliveryWithSignature.
  ///
  /// In en, this message translates to:
  /// **'Do you want to capture the client signature before marking as delivered?'**
  String get confirmDeliveryWithSignature;

  /// No description provided for @errorUpdatingState.
  ///
  /// In en, this message translates to:
  /// **'Error updating state: {error}'**
  String errorUpdatingState(Object error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @adminProfile.
  ///
  /// In en, this message translates to:
  /// **'Admin Profile'**
  String get adminProfile;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @passwordUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Password update available after backend integration.'**
  String get passwordUpdateAvailable;

  /// No description provided for @couldNotLoadUserInfo.
  ///
  /// In en, this message translates to:
  /// **'Could not load user information'**
  String get couldNotLoadUserInfo;

  /// No description provided for @updateProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfileButton;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @assignOrder.
  ///
  /// In en, this message translates to:
  /// **'Assign Order'**
  String get assignOrder;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @assignOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Assign this order to your delivery list?'**
  String get assignOrderConfirm;

  /// No description provided for @couldNotGetDriverInfo.
  ///
  /// In en, this message translates to:
  /// **'Could not get driver information'**
  String get couldNotGetDriverInfo;

  /// No description provided for @noOrderWithBarcode.
  ///
  /// In en, this message translates to:
  /// **'No order found with this barcode'**
  String get noOrderWithBarcode;

  /// No description provided for @errorProcessingBarcode.
  ///
  /// In en, this message translates to:
  /// **'Error processing barcode'**
  String get errorProcessingBarcode;

  /// No description provided for @processingBarcode.
  ///
  /// In en, this message translates to:
  /// **'Processing barcode...'**
  String get processingBarcode;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to: '**
  String get assignedTo;

  /// No description provided for @loadingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Loading routes...'**
  String get loadingRoutes;

  /// No description provided for @allRoutes.
  ///
  /// In en, this message translates to:
  /// **'All routes'**
  String get allRoutes;

  /// No description provided for @activeRoutes.
  ///
  /// In en, this message translates to:
  /// **'Active routes'**
  String get activeRoutes;

  /// No description provided for @completedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Completed routes'**
  String get completedRoutes;

  /// No description provided for @allDrivers.
  ///
  /// In en, this message translates to:
  /// **'All drivers'**
  String get allDrivers;

  /// No description provided for @unknownDriver.
  ///
  /// In en, this message translates to:
  /// **'Unknown driver'**
  String get unknownDriver;

  /// No description provided for @errorLoadingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Error loading routes'**
  String get errorLoadingRoutes;

  /// No description provided for @searchPharmacies.
  ///
  /// In en, this message translates to:
  /// **'Search pharmacies...'**
  String get searchPharmacies;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @inReview.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get inReview;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @pharmacySavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy saved successfully'**
  String get pharmacySavedSuccess;

  /// No description provided for @pharmacyUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy updated successfully'**
  String get pharmacyUpdatedSuccess;

  /// No description provided for @errorReloadPharmacies.
  ///
  /// In en, this message translates to:
  /// **'Error reloading pharmacies'**
  String get errorReloadPharmacies;

  /// No description provided for @pharmacySavedButErrorReload.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy saved but error updating list'**
  String get pharmacySavedButErrorReload;

  /// No description provided for @pharmacyDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy \"{name}\" deleted successfully'**
  String pharmacyDeletedSuccess(Object name);

  /// No description provided for @errorDeletePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Error deleting pharmacy: {error}'**
  String errorDeletePharmacy(Object error);

  /// No description provided for @noPharmaciesFound.
  ///
  /// In en, this message translates to:
  /// **'No pharmacies found'**
  String get noPharmaciesFound;

  /// No description provided for @errorLoadingPharmacies.
  ///
  /// In en, this message translates to:
  /// **'Error loading pharmacies'**
  String get errorLoadingPharmacies;

  /// No description provided for @errorLoadingPharmaciesUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error loading pharmacies'**
  String get errorLoadingPharmaciesUnknown;

  /// No description provided for @errorLoadingOrdersUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error loading orders'**
  String get errorLoadingOrdersUnknown;

  /// No description provided for @printShippingLabelsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Print Shipping Labels'**
  String get printShippingLabelsTooltip;

  /// No description provided for @uploadCsvTooltip.
  ///
  /// In en, this message translates to:
  /// **'Upload CSV'**
  String get uploadCsvTooltip;

  /// No description provided for @addOrderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Order'**
  String get addOrderTooltip;

  /// No description provided for @searchOrdersByClientCodePhone.
  ///
  /// In en, this message translates to:
  /// **'Search by client, code, phone...'**
  String get searchOrdersByClientCodePhone;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @statesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} states'**
  String statesCount(Object count);

  /// No description provided for @noDeliveriesFound.
  ///
  /// In en, this message translates to:
  /// **'No deliveries found'**
  String get noDeliveriesFound;

  /// No description provided for @noOrdersMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No orders match the applied filters'**
  String get noOrdersMatchFilters;

  /// No description provided for @showingXOfYOrders.
  ///
  /// In en, this message translates to:
  /// **'Showing {showing} of {total} orders'**
  String showingXOfYOrders(Object showing, Object total);

  /// No description provided for @pageXOfY.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageXOfY(Object current, Object total);

  /// No description provided for @orderBarcodeCaption.
  ///
  /// In en, this message translates to:
  /// **'Order barcode'**
  String get orderBarcodeCaption;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeletion;

  /// No description provided for @confirmDeleteOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete order #{id}?'**
  String confirmDeleteOrderQuestion(Object id);

  /// No description provided for @deleteOrderIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The order will be permanently deleted.'**
  String get deleteOrderIrreversible;

  /// No description provided for @orderDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order #{id} deleted successfully'**
  String orderDeletedSuccess(Object id);

  /// No description provided for @errorDeleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Error deleting order: {error}'**
  String errorDeleteOrder(Object error);

  /// No description provided for @errorLoadingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Error loading drivers: {detail}'**
  String errorLoadingDrivers(String detail);

  /// No description provided for @selectDriverForOrder.
  ///
  /// In en, this message translates to:
  /// **'Select a driver for the order of {name}'**
  String selectDriverForOrder(Object name);

  /// No description provided for @noDriversAvailable.
  ///
  /// In en, this message translates to:
  /// **'No drivers available'**
  String get noDriversAvailable;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code: '**
  String get codeLabel;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorUnknown;

  /// No description provided for @confirmCancelOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel order #{id}?'**
  String confirmCancelOrderQuestion(Object id);

  /// No description provided for @errorLoadingDriversUnknown.
  ///
  /// In en, this message translates to:
  /// **'Could not load drivers list'**
  String get errorLoadingDriversUnknown;

  /// No description provided for @driverCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver created successfully'**
  String get driverCreatedSuccess;

  /// No description provided for @driverUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver updated successfully'**
  String get driverUpdatedSuccess;

  /// No description provided for @driverDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver \"{name}\" deleted successfully'**
  String driverDeletedSuccess(Object name);

  /// No description provided for @errorDeleteDriver.
  ///
  /// In en, this message translates to:
  /// **'Error deleting driver: {error}'**
  String errorDeleteDriver(Object error);

  /// No description provided for @searchDrivers.
  ///
  /// In en, this message translates to:
  /// **'Search drivers...'**
  String get searchDrivers;

  /// No description provided for @noDriversMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No drivers found with the applied filters'**
  String get noDriversMatchFilters;

  /// No description provided for @noDriversRegistered.
  ///
  /// In en, this message translates to:
  /// **'No drivers registered'**
  String get noDriversRegistered;

  /// No description provided for @addDriver.
  ///
  /// In en, this message translates to:
  /// **'Add Driver'**
  String get addDriver;

  /// No description provided for @deactivatedDriversCount.
  ///
  /// In en, this message translates to:
  /// **'Deactivated drivers ({count})'**
  String deactivatedDriversCount(Object count);

  /// No description provided for @driverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverLabel;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: '**
  String get idLabel;

  /// No description provided for @driverPhoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Driver phone not available'**
  String get driverPhoneNotAvailable;

  /// No description provided for @errorMakingCall.
  ///
  /// In en, this message translates to:
  /// **'Error making call'**
  String get errorMakingCall;

  /// No description provided for @lastActivityNoActivity.
  ///
  /// In en, this message translates to:
  /// **'no activity'**
  String get lastActivityNoActivity;

  /// No description provided for @lastActivityJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get lastActivityJustNow;

  /// No description provided for @lastActivityMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String lastActivityMinutesAgo(Object count);

  /// No description provided for @lastActivityHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String lastActivityHoursAgo(Object count);

  /// No description provided for @lastActivityDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String lastActivityDaysAgo(Object count);

  /// No description provided for @enterValidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name.'**
  String get enterValidName;

  /// No description provided for @nameMinLength3.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters.'**
  String get nameMinLength3;

  /// No description provided for @enterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address.'**
  String get enterEmailAddress;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email.'**
  String get invalidEmail;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get enterValidPhone;

  /// No description provided for @repeatNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat the new password'**
  String get repeatNewPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm the new password.'**
  String get confirmPasswordRequired;

  /// No description provided for @newPasswordMin12.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters.'**
  String get newPasswordMin12;

  /// No description provided for @passwordMustIncludeComplexity.
  ///
  /// In en, this message translates to:
  /// **'Must include uppercase, lowercase and numbers.'**
  String get passwordMustIncludeComplexity;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @tableHeaderPhoto.
  ///
  /// In en, this message translates to:
  /// **'PHOTO'**
  String get tableHeaderPhoto;

  /// No description provided for @tableHeaderName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get tableHeaderName;

  /// No description provided for @tableHeaderEmail.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get tableHeaderEmail;

  /// No description provided for @tableHeaderPhone.
  ///
  /// In en, this message translates to:
  /// **'PHONE'**
  String get tableHeaderPhone;

  /// No description provided for @tableHeaderVehicle.
  ///
  /// In en, this message translates to:
  /// **'VEHICLE'**
  String get tableHeaderVehicle;

  /// No description provided for @tableHeaderLastActivity.
  ///
  /// In en, this message translates to:
  /// **'LAST ACTIVITY'**
  String get tableHeaderLastActivity;

  /// No description provided for @noDriversToShow.
  ///
  /// In en, this message translates to:
  /// **'No drivers to show'**
  String get noDriversToShow;

  /// No description provided for @viewDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetailsTooltip;

  /// No description provided for @copyEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy Email'**
  String get copyEmail;

  /// No description provided for @confirmDeleteDriverQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete driver \"{name}\"?'**
  String confirmDeleteDriverQuestion(Object name);

  /// No description provided for @deleteDriverIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The driver will be permanently deleted.'**
  String get deleteDriverIrreversible;

  /// No description provided for @cannotOpenCallApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open phone app'**
  String get cannotOpenCallApp;

  /// No description provided for @errorMakingCallWithError.
  ///
  /// In en, this message translates to:
  /// **'Error making call: {error}'**
  String errorMakingCallWithError(Object error);

  /// No description provided for @noEmailAvailable.
  ///
  /// In en, this message translates to:
  /// **'No email available'**
  String get noEmailAvailable;

  /// No description provided for @errorCopyingEmail.
  ///
  /// In en, this message translates to:
  /// **'Error copying email: {error}'**
  String errorCopyingEmail(Object error);

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @min6Characters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get min6Characters;

  /// No description provided for @passwordsDoNotMatchShort.
  ///
  /// In en, this message translates to:
  /// **'Do not match'**
  String get passwordsDoNotMatchShort;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @couldNotUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Could not update password'**
  String get couldNotUpdatePassword;

  /// No description provided for @errorSavingDriver.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSavingDriver(Object error);

  /// No description provided for @errorSavingDriverUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error saving driver'**
  String get errorSavingDriverUnknown;

  /// No description provided for @selectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Select expiry date'**
  String get selectExpiryDate;

  /// No description provided for @errorSelectingDate.
  ///
  /// In en, this message translates to:
  /// **'Error selecting date: {error}'**
  String errorSelectingDate(Object error);

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneMustBe10Digits.
  ///
  /// In en, this message translates to:
  /// **'Phone must be exactly 10 digits'**
  String get phoneMustBe10Digits;

  /// No description provided for @editDriver.
  ///
  /// In en, this message translates to:
  /// **'Edit Driver'**
  String get editDriver;

  /// No description provided for @newDriver.
  ///
  /// In en, this message translates to:
  /// **'New Driver'**
  String get newDriver;

  /// No description provided for @modifyingDriver.
  ///
  /// In en, this message translates to:
  /// **'Modifying driver'**
  String get modifyingDriver;

  /// No description provided for @creatingDriver.
  ///
  /// In en, this message translates to:
  /// **'Creating new driver'**
  String get creatingDriver;

  /// No description provided for @sectionPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get sectionPersonalInfo;

  /// No description provided for @sectionLicenseInfo.
  ///
  /// In en, this message translates to:
  /// **'License Information'**
  String get sectionLicenseInfo;

  /// No description provided for @sectionVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get sectionVehicleInfo;

  /// No description provided for @sectionDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents and Photos'**
  String get sectionDocuments;

  /// No description provided for @sectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get sectionSettings;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullNameRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @countryDefaultUSA.
  ///
  /// In en, this message translates to:
  /// **'Will be sent as USA by default'**
  String get countryDefaultUSA;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMin6Chars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMin6Chars;

  /// No description provided for @idDriverLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'ID (Driver\'s License or State ID)'**
  String get idDriverLicenseLabel;

  /// No description provided for @idHelper.
  ///
  /// In en, this message translates to:
  /// **'Letters and numbers; no spaces or hyphens'**
  String get idHelper;

  /// No description provided for @idMin5Chars.
  ///
  /// In en, this message translates to:
  /// **'ID must be at least 5 characters'**
  String get idMin5Chars;

  /// No description provided for @alphanumericOnly.
  ///
  /// In en, this message translates to:
  /// **'Letters and numbers only'**
  String get alphanumericOnly;

  /// No description provided for @licenseNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumberLabel;

  /// No description provided for @licenseFormatHelper.
  ///
  /// In en, this message translates to:
  /// **'Format: Letters and numbers'**
  String get licenseFormatHelper;

  /// No description provided for @licenseMin5Chars.
  ///
  /// In en, this message translates to:
  /// **'License number must be at least 5 characters'**
  String get licenseMin5Chars;

  /// No description provided for @uppercaseAndNumbersOnly.
  ///
  /// In en, this message translates to:
  /// **'Uppercase letters and numbers only'**
  String get uppercaseAndNumbersOnly;

  /// No description provided for @licenseExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'License Expiry'**
  String get licenseExpiryLabel;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @vehiclePlateLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Plate'**
  String get vehiclePlateLabel;

  /// No description provided for @vehiclePlateFormat.
  ///
  /// In en, this message translates to:
  /// **'Format: ABC-123 or ABC123'**
  String get vehiclePlateFormat;

  /// No description provided for @plateMin4Chars.
  ///
  /// In en, this message translates to:
  /// **'Plate must be at least 4 characters'**
  String get plateMin4Chars;

  /// No description provided for @uppercaseNumbersDashes.
  ///
  /// In en, this message translates to:
  /// **'Uppercase letters, numbers and hyphens only'**
  String get uppercaseNumbersDashes;

  /// No description provided for @vehicleBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Brand'**
  String get vehicleBrandLabel;

  /// No description provided for @vehicleBrandHelper.
  ///
  /// In en, this message translates to:
  /// **'E.g.: Toyota, Honda, Ford'**
  String get vehicleBrandHelper;

  /// No description provided for @brandMin2Chars.
  ///
  /// In en, this message translates to:
  /// **'Brand must be at least 2 characters'**
  String get brandMin2Chars;

  /// No description provided for @lettersAndSpacesOnly.
  ///
  /// In en, this message translates to:
  /// **'Letters and spaces only'**
  String get lettersAndSpacesOnly;

  /// No description provided for @vehicleModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Model'**
  String get vehicleModelLabel;

  /// No description provided for @vehicleModelHelper.
  ///
  /// In en, this message translates to:
  /// **'E.g.: Corolla, Civic, Focus'**
  String get vehicleModelHelper;

  /// No description provided for @modelMin2Chars.
  ///
  /// In en, this message translates to:
  /// **'Model must be at least 2 characters'**
  String get modelMin2Chars;

  /// No description provided for @alphanumericSpacesDashes.
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers, spaces and hyphens only'**
  String get alphanumericSpacesDashes;

  /// No description provided for @vehicleRegistrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration Code'**
  String get vehicleRegistrationLabel;

  /// No description provided for @vehicleRegistrationHelper.
  ///
  /// In en, this message translates to:
  /// **'Alphanumeric; e.g.: ABC123456'**
  String get vehicleRegistrationHelper;

  /// No description provided for @min5Characters.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 5 characters'**
  String get min5Characters;

  /// No description provided for @photoLicenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License Photo'**
  String get photoLicenseTitle;

  /// No description provided for @photoLicenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Valid driver\'s license'**
  String get photoLicenseSubtitle;

  /// No description provided for @photoLicenseOrIdOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License / ID (optional)'**
  String get photoLicenseOrIdOptionalLabel;

  /// No description provided for @licenseOrIdNumberOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'License / ID (optional)'**
  String get licenseOrIdNumberOptionalLabel;

  /// No description provided for @photoInsuranceTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Insurance Photo'**
  String get photoInsuranceTitle;

  /// No description provided for @photoInsuranceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Valid policy'**
  String get photoInsuranceSubtitle;

  /// No description provided for @stateRequired.
  ///
  /// In en, this message translates to:
  /// **'Status *'**
  String get stateRequired;

  /// No description provided for @userTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'User Type'**
  String get userTypeLabel;

  /// No description provided for @verifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabel;

  /// No description provided for @documentsSection.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsSection;

  /// No description provided for @loadingPharmacyInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading pharmacy information...'**
  String get loadingPharmacyInfo;

  /// No description provided for @notAssignedToAnyPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to any pharmacy'**
  String get notAssignedToAnyPharmacy;

  /// No description provided for @profilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhotoTitle;

  /// No description provided for @documentTitle.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentTitle;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminRole;

  /// No description provided for @driverRole.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverRole;

  /// No description provided for @pharmacyAssignmentSection.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Assignment'**
  String get pharmacyAssignmentSection;

  /// No description provided for @systemInfoSection.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get systemInfoSection;

  /// No description provided for @registrationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration Date'**
  String get registrationDateLabel;

  /// No description provided for @lastActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Activity'**
  String get lastActivityLabel;

  /// No description provided for @expiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiryLabel;

  /// No description provided for @photoLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'License Photo'**
  String get photoLicenseLabel;

  /// No description provided for @digitalSignatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Digital Signature'**
  String get digitalSignatureLabel;

  /// No description provided for @pharmacyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Detail'**
  String get pharmacyDetailTitle;

  /// No description provided for @generalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get generalInfoTitle;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationTitle;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactTitle;

  /// No description provided for @additionalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInfoTitle;

  /// No description provided for @responsibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Responsible'**
  String get responsibleLabel;

  /// No description provided for @responsiblePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Responsible Phone'**
  String get responsiblePhoneLabel;

  /// No description provided for @latitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitudeLabel;

  /// No description provided for @longitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitudeLabel;

  /// No description provided for @scheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleLabel;

  /// No description provided for @delivery24hLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery 24h'**
  String get delivery24hLabel;

  /// No description provided for @registrationDateShort.
  ///
  /// In en, this message translates to:
  /// **'Registration Date'**
  String get registrationDateShort;

  /// No description provided for @pharmacyLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location of {name}'**
  String pharmacyLocationTitle(Object name);

  /// No description provided for @idShort.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idShort;

  /// No description provided for @razonSocialLabel.
  ///
  /// In en, this message translates to:
  /// **'Legal Name'**
  String get razonSocialLabel;

  /// No description provided for @rucLabel.
  ///
  /// In en, this message translates to:
  /// **'EIN'**
  String get rucLabel;

  /// No description provided for @cadenaLabel.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get cadenaLabel;

  /// No description provided for @stateRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateRegionLabel;

  /// No description provided for @zipCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'ZIP'**
  String get zipCodeLabel;

  /// No description provided for @lastUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdateLabel;

  /// No description provided for @statusShort.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusShort;

  /// No description provided for @selectPharmacyLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Pharmacy Location'**
  String get selectPharmacyLocationTitle;

  /// No description provided for @updatingPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Updating pharmacy...'**
  String get updatingPharmacy;

  /// No description provided for @creatingPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Creating pharmacy...'**
  String get creatingPharmacy;

  /// No description provided for @errorUpdatingPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Error updating pharmacy'**
  String get errorUpdatingPharmacy;

  /// No description provided for @errorCreatingPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Error creating pharmacy'**
  String get errorCreatingPharmacy;

  /// No description provided for @errorDeletingPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Error deleting pharmacy'**
  String get errorDeletingPharmacy;

  /// No description provided for @pleaseEnterPharmacyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the pharmacy name'**
  String get pleaseEnterPharmacyName;

  /// No description provided for @pleaseEnterResponsible.
  ///
  /// In en, this message translates to:
  /// **'Please enter the responsible person'**
  String get pleaseEnterResponsible;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter the phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterRuc.
  ///
  /// In en, this message translates to:
  /// **'Please enter the RUC'**
  String get pleaseEnterRuc;

  /// No description provided for @pharmacyStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Status'**
  String get pharmacyStatusTitle;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @pleaseEnterCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter the city'**
  String get pleaseEnterCity;

  /// No description provided for @editPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Edit Pharmacy'**
  String get editPharmacy;

  /// No description provided for @newPharmacy.
  ///
  /// In en, this message translates to:
  /// **'New Pharmacy'**
  String get newPharmacy;

  /// No description provided for @mapLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Map location'**
  String get mapLocationTitle;

  /// No description provided for @geocodingErrorMap.
  ///
  /// In en, this message translates to:
  /// **'Geocoding error on small map'**
  String get geocodingErrorMap;

  /// No description provided for @pleaseEnterLatitude.
  ///
  /// In en, this message translates to:
  /// **'Please enter the latitude'**
  String get pleaseEnterLatitude;

  /// No description provided for @pleaseEnterValidLatitude.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid latitude'**
  String get pleaseEnterValidLatitude;

  /// No description provided for @pleaseEnterLongitude.
  ///
  /// In en, this message translates to:
  /// **'Please enter the longitude'**
  String get pleaseEnterLongitude;

  /// No description provided for @pleaseEnterValidLongitude.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid longitude'**
  String get pleaseEnterValidLongitude;

  /// No description provided for @updatePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Update Pharmacy'**
  String get updatePharmacy;

  /// No description provided for @createPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Create Pharmacy'**
  String get createPharmacy;

  /// No description provided for @confirmDeletePharmacyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete pharmacy \"{name}\"?\n\nThis action cannot be undone.'**
  String confirmDeletePharmacyQuestion(Object name);

  /// No description provided for @pharmacyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Name *'**
  String get pharmacyNameLabel;

  /// No description provided for @chainOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Chain (optional)'**
  String get chainOptionalLabel;

  /// No description provided for @responsibleRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Responsible *'**
  String get responsibleRequiredLabel;

  /// No description provided for @responsiblePhoneOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Responsible Phone (optional)'**
  String get responsiblePhoneOptionalLabel;

  /// No description provided for @phoneRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone *'**
  String get phoneRequiredLabel;

  /// No description provided for @emailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptionalLabel;

  /// No description provided for @rucRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'RUC *'**
  String get rucRequiredLabel;

  /// No description provided for @rucEinOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'EIN (optional)'**
  String get rucEinOptionalLabel;

  /// No description provided for @cityRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'City *'**
  String get cityRequiredLabel;

  /// No description provided for @zipOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code (optional)'**
  String get zipOptionalLabel;

  /// No description provided for @scheduleOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule (optional)'**
  String get scheduleOptionalLabel;

  /// No description provided for @delivery24hHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery 24 hours'**
  String get delivery24hHoursLabel;

  /// No description provided for @addressLine1RequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1 *'**
  String get addressLine1RequiredLabel;

  /// No description provided for @addressLine2OptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 (optional)'**
  String get addressLine2OptionalLabel;

  /// No description provided for @pleaseEnterAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Please enter address line 1'**
  String get pleaseEnterAddressLine1;

  /// No description provided for @addressLine1HelperText.
  ///
  /// In en, this message translates to:
  /// **'Street, avenue, etc.'**
  String get addressLine1HelperText;

  /// No description provided for @addressLine2HelperText.
  ///
  /// In en, this message translates to:
  /// **'Floor, apartment, reference, etc.'**
  String get addressLine2HelperText;

  /// No description provided for @deletePharmacyIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The pharmacy will be permanently deleted.'**
  String get deletePharmacyIrreversible;

  /// No description provided for @confirmDeletePharmacyQuestionShort.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete pharmacy \"{name}\"?'**
  String confirmDeletePharmacyQuestionShort(Object name);

  /// No description provided for @latitudeRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude *'**
  String get latitudeRequiredLabel;

  /// No description provided for @longitudeRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude *'**
  String get longitudeRequiredLabel;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @assignDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver'**
  String get assignDriverTitle;

  /// No description provided for @noActiveDrivers.
  ///
  /// In en, this message translates to:
  /// **'No active drivers'**
  String get noActiveDrivers;

  /// No description provided for @confirmAssignment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Assignment'**
  String get confirmAssignment;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrderTitle;

  /// No description provided for @confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get confirmCancellation;

  /// No description provided for @markAsFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as Failed'**
  String get markAsFailedTitle;

  /// No description provided for @failureReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Failure reason'**
  String get failureReasonLabel;

  /// No description provided for @observationsOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Observations (optional)'**
  String get observationsOptionalLabel;

  /// No description provided for @failureDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Additional details about the failure...'**
  String get failureDetailsHint;

  /// No description provided for @confirmFailure.
  ///
  /// In en, this message translates to:
  /// **'Confirm Failure'**
  String get confirmFailure;

  /// No description provided for @barcodeOrderDescription.
  ///
  /// In en, this message translates to:
  /// **'Order barcode'**
  String get barcodeOrderDescription;

  /// No description provided for @errorDeletingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error deleting order'**
  String get errorDeletingOrder;

  /// No description provided for @orderCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order #{id} cancelled successfully'**
  String orderCancelledSuccess(Object id);

  /// No description provided for @errorCancellingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling order'**
  String get errorCancellingOrder;

  /// No description provided for @cancelOrderIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action will change the order status to \"Cancelled\" and cannot be undone.'**
  String get cancelOrderIrreversible;

  /// No description provided for @selectFailureReasonForOrder.
  ///
  /// In en, this message translates to:
  /// **'Select the failure reason for order #{id}'**
  String selectFailureReasonForOrder(Object id);

  /// No description provided for @markAsFailedIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action will change the order status to \"Failed\" and will record the current location.'**
  String get markAsFailedIrreversible;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'5551234567'**
  String get phoneHint;

  /// No description provided for @stateOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'State (optional)'**
  String get stateOptionalLabel;

  /// No description provided for @districtRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'District *'**
  String get districtRequiredLabel;

  /// No description provided for @postalCodeOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Postal Code (optional)'**
  String get postalCodeOptionalLabel;

  /// No description provided for @deliveryAddressLine1Label.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address Line 1 *'**
  String get deliveryAddressLine1Label;

  /// No description provided for @deliveryAddressLine2OptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address Line 2 (optional)'**
  String get deliveryAddressLine2OptionalLabel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @driverOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver (optional)'**
  String get driverOptionalLabel;

  /// No description provided for @loadingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Loading drivers...'**
  String get loadingDrivers;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @pharmacyRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy *'**
  String get pharmacyRequiredLabel;

  /// No description provided for @loadingPharmacies.
  ///
  /// In en, this message translates to:
  /// **'Loading pharmacies...'**
  String get loadingPharmacies;

  /// No description provided for @clientNameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Client Name *'**
  String get clientNameRequiredLabel;

  /// No description provided for @buildingAccessCodeOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Building Access Code (optional)'**
  String get buildingAccessCodeOptionalLabel;

  /// No description provided for @orderTypeRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Type *'**
  String get orderTypeRequiredLabel;

  /// No description provided for @addMedicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedicationTitle;

  /// No description provided for @medicationNameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication Name *'**
  String get medicationNameRequiredLabel;

  /// No description provided for @quantityRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity *'**
  String get quantityRequiredLabel;

  /// No description provided for @selectDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Driver'**
  String get selectDriverTitle;

  /// No description provided for @searchDriverHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone or email...'**
  String get searchDriverHint;

  /// No description provided for @unassignDriverOption.
  ///
  /// In en, this message translates to:
  /// **'Do not assign driver to this order'**
  String get unassignDriverOption;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectDeliveryLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Delivery Location'**
  String get selectDeliveryLocationTitle;

  /// No description provided for @noMedicationsAddedHint.
  ///
  /// In en, this message translates to:
  /// **'No medications added. Press \"Add\" to add medications.'**
  String get noMedicationsAddedHint;

  /// No description provided for @routeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Details'**
  String get routeDetailsTitle;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceLabel;

  /// No description provided for @estimatedTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTimeLabel;

  /// No description provided for @additionalDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional details'**
  String get additionalDetailsLabel;

  /// No description provided for @startPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Point'**
  String get startPointLabel;

  /// No description provided for @endPointLabel.
  ///
  /// In en, this message translates to:
  /// **'End Point'**
  String get endPointLabel;

  /// No description provided for @creationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Creation Date'**
  String get creationDateLabel;

  /// No description provided for @routeOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Orders'**
  String get routeOrdersTitle;

  /// No description provided for @refreshOrdersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh orders'**
  String get refreshOrdersTooltip;

  /// No description provided for @clientNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Client not specified'**
  String get clientNotSpecified;

  /// No description provided for @oldOrdersCleanupTitle.
  ///
  /// In en, this message translates to:
  /// **'Old Orders File Cleanup'**
  String get oldOrdersCleanupTitle;

  /// No description provided for @oldOrdersCleanupDescription.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete only multimedia files (delivery photos and digital signatures) from orders delivered more than the selected time ago. Order data will remain intact.'**
  String get oldOrdersCleanupDescription;

  /// No description provided for @weeksBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Weeks back'**
  String get weeksBackLabel;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @saveConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Save Configuration'**
  String get saveConfiguration;

  /// No description provided for @confirmCleanup.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cleanup'**
  String get confirmCleanup;

  /// No description provided for @confirmCleanupDescription.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete only multimedia files (photos and signatures). Order data will remain intact.'**
  String get confirmCleanupDescription;

  /// No description provided for @cleanupStartedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Multimedia file cleanup for old orders has been started successfully'**
  String get cleanupStartedSuccess;

  /// No description provided for @errorStartingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Error starting cleanup'**
  String get errorStartingCleanup;

  /// No description provided for @googleApiUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Google API Usage'**
  String get googleApiUsageTitle;

  /// No description provided for @refreshMetricsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh metrics'**
  String get refreshMetricsTooltip;

  /// No description provided for @apiCallsLast30Days.
  ///
  /// In en, this message translates to:
  /// **'API Calls (Last 30 days)'**
  String get apiCallsLast30Days;

  /// No description provided for @errorLoadingMetrics.
  ///
  /// In en, this message translates to:
  /// **'Error loading metrics'**
  String get errorLoadingMetrics;

  /// No description provided for @requestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsLabel;

  /// No description provided for @servicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesLabel;

  /// No description provided for @costPerRequest.
  ///
  /// In en, this message translates to:
  /// **'Cost per request'**
  String get costPerRequest;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get totalCost;

  /// No description provided for @noUsageDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No usage data available'**
  String get noUsageDataAvailable;

  /// No description provided for @metricsWillAppearWhenRequests.
  ///
  /// In en, this message translates to:
  /// **'Metrics will appear when API requests are made'**
  String get metricsWillAppearWhenRequests;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get periodLabel;

  /// No description provided for @weekLabel.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get weekLabel;

  /// No description provided for @weeksLabel.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeksLabel;

  /// No description provided for @confirmCleanupWeeksQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete only multimedia files (photos and signatures) from orders delivered more than {count} {weeksLabel} ago?'**
  String confirmCleanupWeeksQuestion(Object count, Object weeksLabel);

  /// No description provided for @selectPharmacyRequired.
  ///
  /// In en, this message translates to:
  /// **'You must select a pharmacy'**
  String get selectPharmacyRequired;

  /// No description provided for @noCsvDataToUpload.
  ///
  /// In en, this message translates to:
  /// **'No CSV data to upload'**
  String get noCsvDataToUpload;

  /// No description provided for @csvUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'CSV uploaded successfully. You will receive a notification when processing is complete.'**
  String get csvUploadSuccess;

  /// No description provided for @errorUploadingCsv.
  ///
  /// In en, this message translates to:
  /// **'Error uploading CSV'**
  String get errorUploadingCsv;

  /// No description provided for @csvTemplateReady.
  ///
  /// In en, this message translates to:
  /// **'CSV template generated and ready to download.'**
  String get csvTemplateReady;

  /// No description provided for @errorDownloadingTemplate.
  ///
  /// In en, this message translates to:
  /// **'Error downloading template'**
  String get errorDownloadingTemplate;

  /// No description provided for @generatePdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get generatePdfTitle;

  /// No description provided for @filterByNameAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by name, address'**
  String get filterByNameAddressHint;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @selectAllOrders.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAllOrders;

  /// No description provided for @errorLoadingPage.
  ///
  /// In en, this message translates to:
  /// **'Error loading page'**
  String get errorLoadingPage;

  /// No description provided for @noDriverInfoAvailable.
  ///
  /// In en, this message translates to:
  /// **'No driver information available'**
  String get noDriverInfoAvailable;

  /// No description provided for @errorLoadingRouteDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load route details'**
  String get errorLoadingRouteDetails;

  /// No description provided for @errorLoadingRouteDetailsWithError.
  ///
  /// In en, this message translates to:
  /// **'Error loading details'**
  String get errorLoadingRouteDetailsWithError;

  /// No description provided for @driverDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Details'**
  String get driverDetailsTitle;

  /// No description provided for @currentRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Route'**
  String get currentRouteLabel;

  /// No description provided for @routeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Route ID'**
  String get routeIdLabel;

  /// No description provided for @routeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Route Name'**
  String get routeNameLabel;

  /// No description provided for @totalDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Distance'**
  String get totalDistanceLabel;

  /// No description provided for @assignedOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned Orders'**
  String get assignedOrdersLabel;

  /// No description provided for @calculationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculation Date'**
  String get calculationDateLabel;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// No description provided for @completedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed Date'**
  String get completedDateLabel;

  /// No description provided for @viewRoute.
  ///
  /// In en, this message translates to:
  /// **'View Route'**
  String get viewRoute;

  /// No description provided for @ordersInOptimizedOrderCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders in optimized order'**
  String ordersInOptimizedOrderCount(Object count);

  /// No description provided for @pickupLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocationLabel;

  /// No description provided for @deliveryLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocationLabel;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @ordersUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Orders updated successfully'**
  String get ordersUpdatedSuccess;

  /// No description provided for @errorUpdatingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error updating orders'**
  String get errorUpdatingOrders;

  /// No description provided for @lessThanOneMonth.
  ///
  /// In en, this message translates to:
  /// **'less than 1 month'**
  String get lessThanOneMonth;

  /// No description provided for @aboutOneMonth.
  ///
  /// In en, this message translates to:
  /// **'~1 month'**
  String get aboutOneMonth;

  /// No description provided for @aboutMonthsCount.
  ///
  /// In en, this message translates to:
  /// **'~{count} months'**
  String aboutMonthsCount(Object count);

  /// No description provided for @weeksBackDisplay.
  ///
  /// In en, this message translates to:
  /// **'{count} {weeksLabel} ago'**
  String weeksBackDisplay(Object count, Object weeksLabel);

  /// No description provided for @weekShortLabel.
  ///
  /// In en, this message translates to:
  /// **'wk'**
  String get weekShortLabel;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @csvValidationErrorsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Errors found in CSV:'**
  String get csvValidationErrorsPrefix;

  /// No description provided for @errorChangingItemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'Error changing items per page'**
  String get errorChangingItemsPerPage;

  /// No description provided for @copyData.
  ///
  /// In en, this message translates to:
  /// **'Copy Data'**
  String get copyData;

  /// No description provided for @generatingPdf.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF...'**
  String get generatingPdf;

  /// No description provided for @loadingOrdersForPdf.
  ///
  /// In en, this message translates to:
  /// **'Loading orders for PDF...'**
  String get loadingOrdersForPdf;

  /// No description provided for @noPendingOrdersForPdf.
  ///
  /// In en, this message translates to:
  /// **'No pending orders to generate PDF'**
  String get noPendingOrdersForPdf;

  /// No description provided for @pendingOrdersPdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Pending orders will appear here to generate shipping labels'**
  String get pendingOrdersPdfDescription;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateDayBeforeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Day before yesterday'**
  String get dateDayBeforeYesterday;

  /// No description provided for @dateThreeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'3 days ago'**
  String get dateThreeDaysAgo;

  /// No description provided for @ordersCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order} other{{count} orders}}'**
  String ordersCountLabel(num count);

  /// No description provided for @pdfDownloadUrlNotReceived.
  ///
  /// In en, this message translates to:
  /// **'PDF download URL was not received'**
  String get pdfDownloadUrlNotReceived;

  /// No description provided for @unknownErrorGeneratingPdf.
  ///
  /// In en, this message translates to:
  /// **'Unknown error generating PDF'**
  String get unknownErrorGeneratingPdf;

  /// No description provided for @errorGeneratingPdf.
  ///
  /// In en, this message translates to:
  /// **'Error generating PDF'**
  String get errorGeneratingPdf;

  /// No description provided for @errorGeneratingPdfWithError.
  ///
  /// In en, this message translates to:
  /// **'Error generating PDF: {error}'**
  String errorGeneratingPdfWithError(Object error);

  /// No description provided for @pdfGenerationTimeout.
  ///
  /// In en, this message translates to:
  /// **'PDF generation took too long. Try with fewer labels.'**
  String get pdfGenerationTimeout;

  /// No description provided for @onlyPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Only'**
  String get onlyPending;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @csvHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help - Upload CSV'**
  String get csvHelpTitle;

  /// No description provided for @csvHelpHowToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use this tool:'**
  String get csvHelpHowToUse;

  /// No description provided for @csvHelpStep1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Download template'**
  String get csvHelpStep1Title;

  /// No description provided for @csvHelpStep1Description.
  ///
  /// In en, this message translates to:
  /// **'Click the download icon to get the CSV template with the required columns.'**
  String get csvHelpStep1Description;

  /// No description provided for @csvHelpStep2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Fill in data'**
  String get csvHelpStep2Title;

  /// No description provided for @csvHelpStep2Description.
  ///
  /// In en, this message translates to:
  /// **'Complete the template with order data. Coordinates must be in \"latitude, longitude\" format.'**
  String get csvHelpStep2Description;

  /// No description provided for @csvHelpStep3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Upload file'**
  String get csvHelpStep3Title;

  /// No description provided for @csvHelpStep3Description.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop your CSV file or click to select it.'**
  String get csvHelpStep3Description;

  /// No description provided for @csvHelpStep4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Select pharmacy'**
  String get csvHelpStep4Title;

  /// No description provided for @csvHelpStep4Description.
  ///
  /// In en, this message translates to:
  /// **'Choose the pharmacy to which the orders will be assigned.'**
  String get csvHelpStep4Description;

  /// No description provided for @csvHelpStep5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Process'**
  String get csvHelpStep5Title;

  /// No description provided for @csvHelpStep5Description.
  ///
  /// In en, this message translates to:
  /// **'Click \"Process\" to upload the orders to the system.'**
  String get csvHelpStep5Description;

  /// No description provided for @csvHelpTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Important tip:'**
  String get csvHelpTipTitle;

  /// No description provided for @csvHelpTipCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates must be in decimal format: \"26.037737, -80.179550\" for USA.'**
  String get csvHelpTipCoordinates;

  /// No description provided for @orderAssignedToName.
  ///
  /// In en, this message translates to:
  /// **'Order assigned to {name}'**
  String orderAssignedToName(Object name);

  /// No description provided for @errorAssigningOrder.
  ///
  /// In en, this message translates to:
  /// **'Error assigning'**
  String get errorAssigningOrder;

  /// No description provided for @dateOfType.
  ///
  /// In en, this message translates to:
  /// **'Date of {type}'**
  String dateOfType(Object type);

  /// No description provided for @noPharmaciesToShow.
  ///
  /// In en, this message translates to:
  /// **'No pharmacies to show'**
  String get noPharmaciesToShow;

  /// No description provided for @noResponsible.
  ///
  /// In en, this message translates to:
  /// **'No responsible'**
  String get noResponsible;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get noPhone;

  /// No description provided for @noCity.
  ///
  /// In en, this message translates to:
  /// **'No city'**
  String get noCity;

  /// No description provided for @tableHeaderAddress.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get tableHeaderAddress;

  /// No description provided for @tableHeaderResponsible.
  ///
  /// In en, this message translates to:
  /// **'RESPONSIBLE'**
  String get tableHeaderResponsible;

  /// No description provided for @tableHeaderCity.
  ///
  /// In en, this message translates to:
  /// **'CITY'**
  String get tableHeaderCity;

  /// No description provided for @tableHeaderLocation.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get tableHeaderLocation;

  /// No description provided for @errorLoadingPharmaciesForForm.
  ///
  /// In en, this message translates to:
  /// **'Error loading pharmacies for form'**
  String get errorLoadingPharmaciesForForm;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String errorLoadingData(Object error);

  /// No description provided for @selectLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'You must select a location on the map'**
  String get selectLocationOnMap;

  /// No description provided for @orderUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order updated successfully'**
  String get orderUpdatedSuccess;

  /// No description provided for @orderCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order created successfully'**
  String get orderCreatedSuccess;

  /// No description provided for @errorUpdatingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error updating order'**
  String get errorUpdatingOrder;

  /// No description provided for @errorCreatingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error creating order'**
  String get errorCreatingOrder;

  /// No description provided for @errorSavingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSavingOrder(Object error);

  /// No description provided for @editDelivery.
  ///
  /// In en, this message translates to:
  /// **'Edit Delivery'**
  String get editDelivery;

  /// No description provided for @newDelivery.
  ///
  /// In en, this message translates to:
  /// **'New Delivery'**
  String get newDelivery;

  /// No description provided for @creatingNewDelivery.
  ///
  /// In en, this message translates to:
  /// **'Creating new delivery'**
  String get creatingNewDelivery;

  /// No description provided for @saveDelivery.
  ///
  /// In en, this message translates to:
  /// **'Save Delivery'**
  String get saveDelivery;

  /// No description provided for @districtRequired.
  ///
  /// In en, this message translates to:
  /// **'District is required'**
  String get districtRequired;

  /// No description provided for @deliveryAddressLine1Required.
  ///
  /// In en, this message translates to:
  /// **'Delivery address line 1 is required'**
  String get deliveryAddressLine1Required;

  /// No description provided for @orderStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatusLabel;

  /// No description provided for @quantityLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {count}'**
  String quantityLabelShort(Object count);

  /// No description provided for @medicationDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medicationDefaultName;

  /// No description provided for @selectDriverForOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Select a driver to assign to the order'**
  String get selectDriverForOrderHint;

  /// No description provided for @driversAvailableTapToSearch.
  ///
  /// In en, this message translates to:
  /// **'{count} drivers available - Tap to search'**
  String driversAvailableTapToSearch(Object count);

  /// No description provided for @driversAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String driversAvailableCount(Object count);

  /// No description provided for @buildingAccessCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Code to access building or condominium'**
  String get buildingAccessCodeHelper;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneRequired;

  /// No description provided for @errorUnassigningDriver.
  ///
  /// In en, this message translates to:
  /// **'Error unassigning driver'**
  String get errorUnassigningDriver;

  /// No description provided for @errorAssigningDriver.
  ///
  /// In en, this message translates to:
  /// **'Error assigning driver: {detail}'**
  String errorAssigningDriver(String detail);

  /// No description provided for @errorFetchingUpdatedData.
  ///
  /// In en, this message translates to:
  /// **'Error fetching updated data'**
  String get errorFetchingUpdatedData;

  /// No description provided for @clientNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Client name is required'**
  String get clientNameRequired;

  /// No description provided for @medicationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get medicationNameRequired;

  /// No description provided for @medicationQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Quantity is required'**
  String get medicationQuantityRequired;

  /// No description provided for @phoneLengthBetween.
  ///
  /// In en, this message translates to:
  /// **'Phone must be between 10 and 12 digits'**
  String get phoneLengthBetween;

  /// No description provided for @errorChangingDriver.
  ///
  /// In en, this message translates to:
  /// **'Error changing driver: {error}'**
  String errorChangingDriver(Object error);

  /// No description provided for @errorRefreshingData.
  ///
  /// In en, this message translates to:
  /// **'Error refreshing data: {error}'**
  String errorRefreshingData(Object error);

  /// No description provided for @enterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get enterValidQuantity;

  /// No description provided for @uploadOrdersFromCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Orders from CSV'**
  String get uploadOrdersFromCsvTitle;

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @downloadCsvTemplateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download CSV template'**
  String get downloadCsvTemplateTooltip;

  /// No description provided for @helpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTooltip;

  /// No description provided for @validationProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Validation Progress'**
  String get validationProgressTitle;

  /// No description provided for @allRecordsHaveValidCoordinates.
  ///
  /// In en, this message translates to:
  /// **'All records have valid coordinates'**
  String get allRecordsHaveValidCoordinates;

  /// No description provided for @dragDropCsvHere.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop your CSV file here'**
  String get dragDropCsvHere;

  /// No description provided for @orClickToSelectFile.
  ///
  /// In en, this message translates to:
  /// **'or click to select a file'**
  String get orClickToSelectFile;

  /// No description provided for @fileInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'File information'**
  String get fileInfoTitle;

  /// No description provided for @fileSizeFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Max size: 10MB • Format: CSV • Encoding: UTF-8'**
  String get fileSizeFormatHint;

  /// No description provided for @csvFileLabel.
  ///
  /// In en, this message translates to:
  /// **'CSV file'**
  String get csvFileLabel;

  /// No description provided for @recordsLoadComplete.
  ///
  /// In en, this message translates to:
  /// **'{fileName} - {count} records - Load complete'**
  String recordsLoadComplete(Object count, Object fileName);

  /// No description provided for @selectPharmacyToAssignOrders.
  ///
  /// In en, this message translates to:
  /// **'Select Pharmacy to assign orders'**
  String get selectPharmacyToAssignOrders;

  /// No description provided for @noDataToShow.
  ///
  /// In en, this message translates to:
  /// **'No data to show'**
  String get noDataToShow;

  /// No description provided for @selectCsvFileToPreview.
  ///
  /// In en, this message translates to:
  /// **'Select a CSV file to preview the data'**
  String get selectCsvFileToPreview;

  /// No description provided for @noLocation.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get noLocation;

  /// No description provided for @emptyField.
  ///
  /// In en, this message translates to:
  /// **'Empty field'**
  String get emptyField;

  /// No description provided for @processButton.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get processButton;

  /// No description provided for @errorLoadingPharmaciesForExport.
  ///
  /// In en, this message translates to:
  /// **'Error loading pharmacies for export'**
  String get errorLoadingPharmaciesForExport;

  /// No description provided for @recordsValidCount.
  ///
  /// In en, this message translates to:
  /// **'{valid}/{total} valid'**
  String recordsValidCount(Object total, Object valid);

  /// No description provided for @recordsNeedValidCoordinates.
  ///
  /// In en, this message translates to:
  /// **'{count} records need valid coordinates'**
  String recordsNeedValidCoordinates(Object count);

  /// No description provided for @userCanAccessSystem.
  ///
  /// In en, this message translates to:
  /// **'User can access the system'**
  String get userCanAccessSystem;

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'User disabled'**
  String get userDisabled;

  /// No description provided for @couldNotUpdateActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not update active status'**
  String get couldNotUpdateActiveStatus;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// No description provided for @createDriver.
  ///
  /// In en, this message translates to:
  /// **'Create Driver'**
  String get createDriver;

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelect;

  /// No description provided for @driverPhotoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Driver photo'**
  String get driverPhotoPlaceholder;

  /// No description provided for @errorUploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error uploading image: {error}'**
  String errorUploadingImage(Object error);

  /// No description provided for @errorUpdatingActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorUpdatingActiveStatus(Object error);

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @errorGettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Error getting address'**
  String get errorGettingAddress;

  /// No description provided for @tapMapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to select a location'**
  String get tapMapToSelectLocation;

  /// No description provided for @centerButton.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get centerButton;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @barcodeCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get barcodeCodeCopied;

  /// No description provided for @copyCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCodeTooltip;

  /// No description provided for @regenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerateButton;

  /// No description provided for @alphanumericLabel.
  ///
  /// In en, this message translates to:
  /// **'Alphanumeric'**
  String get alphanumericLabel;

  /// No description provided for @numericLabel.
  ///
  /// In en, this message translates to:
  /// **'Numeric'**
  String get numericLabel;

  /// No description provided for @errorGeneratingBarcode.
  ///
  /// In en, this message translates to:
  /// **'Error generating barcode'**
  String get errorGeneratingBarcode;

  /// No description provided for @errorLoadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error loading image'**
  String get errorLoadingImage;

  /// No description provided for @serverResponseError.
  ///
  /// In en, this message translates to:
  /// **'Server response error'**
  String get serverResponseError;

  /// No description provided for @errorLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Error logging out'**
  String get errorLoggingOut;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// No description provided for @selectAPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Select a pharmacy'**
  String get selectAPharmacy;

  /// No description provided for @centralPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Central Pharmacy'**
  String get centralPharmacy;

  /// No description provided for @clearCsv.
  ///
  /// In en, this message translates to:
  /// **'Clear CSV'**
  String get clearCsv;

  /// No description provided for @orderTypeMedicalSupplies.
  ///
  /// In en, this message translates to:
  /// **'Medical Supplies'**
  String get orderTypeMedicalSupplies;

  /// No description provided for @orderTypeMedicalEquipment.
  ///
  /// In en, this message translates to:
  /// **'Medical Equipment'**
  String get orderTypeMedicalEquipment;

  /// No description provided for @orderTypeControlledMedications.
  ///
  /// In en, this message translates to:
  /// **'Controlled Medications'**
  String get orderTypeControlledMedications;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @driverAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver {name} assigned successfully'**
  String driverAssignedSuccess(String name);

  /// No description provided for @errorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {detail}'**
  String errorWithDetail(String detail);

  /// No description provided for @orderCanceledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order #{id} canceled successfully'**
  String orderCanceledSuccess(String id);

  /// No description provided for @errorCancelingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error canceling order: {detail}'**
  String errorCancelingOrder(String detail);

  /// No description provided for @orderMarkedFailedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order #{id} marked as failed'**
  String orderMarkedFailedSuccess(String id);

  /// No description provided for @errorMarkingOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Error marking order as failed: {detail}'**
  String errorMarkingOrderFailed(String detail);

  /// No description provided for @defaultSchedulePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Mon-Fri: 8:00-20:00'**
  String get defaultSchedulePlaceholder;

  /// No description provided for @orderAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order assigned successfully'**
  String get orderAssignedSuccess;

  /// No description provided for @errorAssigningOrderDetail.
  ///
  /// In en, this message translates to:
  /// **'Error assigning order: {detail}'**
  String errorAssigningOrderDetail(String detail);

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order delivered'**
  String get orderDelivered;

  /// No description provided for @orderFailed.
  ///
  /// In en, this message translates to:
  /// **'Order failed'**
  String get orderFailed;

  /// No description provided for @orderCancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelledStatus;

  /// No description provided for @reoptimizeRoute.
  ///
  /// In en, this message translates to:
  /// **'Re-optimize route'**
  String get reoptimizeRoute;

  /// No description provided for @inQueue.
  ///
  /// In en, this message translates to:
  /// **'In Queue'**
  String get inQueue;

  /// No description provided for @pickupAt.
  ///
  /// In en, this message translates to:
  /// **'Pick up at: '**
  String get pickupAt;

  /// No description provided for @routeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Route not available'**
  String get routeNotAvailable;

  /// No description provided for @toPickup.
  ///
  /// In en, this message translates to:
  /// **'to pickup'**
  String get toPickup;

  /// No description provided for @toDelivery.
  ///
  /// In en, this message translates to:
  /// **'to delivery'**
  String get toDelivery;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completedStatus;

  /// No description provided for @pickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pick up: '**
  String get pickupLabel;

  /// No description provided for @clientInformation.
  ///
  /// In en, this message translates to:
  /// **'Client Information'**
  String get clientInformation;

  /// No description provided for @copyPhoneTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy phone'**
  String get copyPhoneTooltip;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewMap;

  /// No description provided for @noChain.
  ///
  /// In en, this message translates to:
  /// **'No chain'**
  String get noChain;

  /// No description provided for @orderTypeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Type'**
  String get orderTypeSectionTitle;

  /// No description provided for @orderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Order type'**
  String get orderTypeLabel;

  /// No description provided for @signatureCaptured.
  ///
  /// In en, this message translates to:
  /// **'Signature Captured'**
  String get signatureCaptured;

  /// No description provided for @deliveryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Delivery not found'**
  String get deliveryNotFound;

  /// No description provided for @deliveryNotFoundWithId.
  ///
  /// In en, this message translates to:
  /// **'Delivery #{id} does not exist'**
  String deliveryNotFoundWithId(String id);

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get pickedUp;

  /// No description provided for @deliveredStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveredStatus;

  /// No description provided for @noSignatureAvailable.
  ///
  /// In en, this message translates to:
  /// **'No signature available'**
  String get noSignatureAvailable;

  /// No description provided for @errorLoadingSignature.
  ///
  /// In en, this message translates to:
  /// **'Error loading signature'**
  String get errorLoadingSignature;

  /// No description provided for @errorRenderingSvg.
  ///
  /// In en, this message translates to:
  /// **'Error rendering SVG'**
  String get errorRenderingSvg;

  /// No description provided for @errorDecodingSignature.
  ///
  /// In en, this message translates to:
  /// **'Error decoding signature'**
  String get errorDecodingSignature;

  /// No description provided for @invalidSignatureFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid signature format'**
  String get invalidSignatureFormat;

  /// No description provided for @onRoute.
  ///
  /// In en, this message translates to:
  /// **'On Route'**
  String get onRoute;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @pickUpAction.
  ///
  /// In en, this message translates to:
  /// **'Pick up'**
  String get pickUpAction;

  /// No description provided for @filterDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get filterDelivered;

  /// No description provided for @filterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get filterCancelled;

  /// No description provided for @filterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get filterFailed;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Profile photo deleted'**
  String get profilePhotoDeleted;

  /// No description provided for @confirmDeleteProfilePhotoQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your profile photo?'**
  String get confirmDeleteProfilePhotoQuestion;

  /// No description provided for @securitySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySectionTitle;

  /// No description provided for @changeButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeButton;

  /// No description provided for @min8Characters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get min8Characters;

  /// No description provided for @newPasswordMin8Chars.
  ///
  /// In en, this message translates to:
  /// **'The new password must be at least 8 characters'**
  String get newPasswordMin8Chars;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @errorChangingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error changing password: {detail}'**
  String errorChangingPassword(String detail);

  /// No description provided for @errorChangingPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Error changing password'**
  String get errorChangingPasswordShort;

  /// No description provided for @activeSessions.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get activeSessions;

  /// No description provided for @drivingLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get drivingLicense;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Unknown error loading history'**
  String get errorLoadingHistory;

  /// No description provided for @orderIdShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID:'**
  String get orderIdShortLabel;

  /// No description provided for @pharmacyIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy ID:'**
  String get pharmacyIdLabel;

  /// No description provided for @copyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// No description provided for @formatNumericDigits.
  ///
  /// In en, this message translates to:
  /// **'Numeric format ({count} digits)'**
  String formatNumericDigits(int count);

  /// No description provided for @formatAlphanumericChars.
  ///
  /// In en, this message translates to:
  /// **'Alphanumeric format ({count} characters)'**
  String formatAlphanumericChars(int count);

  /// No description provided for @selectedLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected location:'**
  String get selectedLocationLabel;

  /// No description provided for @exitButton.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitButton;

  /// No description provided for @invalidCoordinatesFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinates format. Use: \"latitude, longitude\"'**
  String get invalidCoordinatesFormat;

  /// No description provided for @viewDriver.
  ///
  /// In en, this message translates to:
  /// **'View Driver'**
  String get viewDriver;

  /// No description provided for @optimizeRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Optimize Routes'**
  String get optimizeRoutesTitle;

  /// No description provided for @optimizeButton.
  ///
  /// In en, this message translates to:
  /// **'Optimize'**
  String get optimizeButton;

  /// No description provided for @pharmacyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Details'**
  String get pharmacyDetailsTitle;

  /// No description provided for @cameraPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission'**
  String get cameraPermissionTitle;

  /// No description provided for @settingsButton.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsButton;

  /// No description provided for @codeScanned.
  ///
  /// In en, this message translates to:
  /// **'Code Scanned'**
  String get codeScanned;

  /// No description provided for @scanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan Another'**
  String get scanAnother;

  /// No description provided for @allowCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow Camera Access'**
  String get allowCameraAccess;

  /// No description provided for @changeOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Change order - Order #{id}'**
  String changeOrderTitle(String id);

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient:'**
  String get patientLabel;

  /// No description provided for @reloadRoute.
  ///
  /// In en, this message translates to:
  /// **'Reload route'**
  String get reloadRoute;

  /// No description provided for @viewDeliveriesCount.
  ///
  /// In en, this message translates to:
  /// **'View deliveries ({count})'**
  String viewDeliveriesCount(int count);

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// No description provided for @deliveryMarkerTitle.
  ///
  /// In en, this message translates to:
  /// **'{order}) Delivery - {name}'**
  String deliveryMarkerTitle(String order, String name);

  /// No description provided for @pickedUpCount.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get pickedUpCount;

  /// No description provided for @pickUpCount.
  ///
  /// In en, this message translates to:
  /// **'Pick up'**
  String get pickUpCount;

  /// No description provided for @optimizeRoutesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to optimize all routes? This process may take several minutes.'**
  String get optimizeRoutesConfirmation;

  /// No description provided for @cameraPermissionContent.
  ///
  /// In en, this message translates to:
  /// **'The app needs camera access to scan barcodes.'**
  String get cameraPermissionContent;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission Required'**
  String get cameraPermissionRequired;

  /// No description provided for @cameraPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'To scan barcodes, we need access to your camera.'**
  String get cameraPermissionBody;

  /// No description provided for @scanTitleWithMode.
  ///
  /// In en, this message translates to:
  /// **'Scan - {mode}'**
  String scanTitleWithMode(String mode);

  /// No description provided for @modeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode:'**
  String get modeLabel;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order:'**
  String get orderNumberLabel;

  /// No description provided for @successDeliveryVerified.
  ///
  /// In en, this message translates to:
  /// **'Delivery code verified successfully'**
  String get successDeliveryVerified;

  /// No description provided for @successPickupVerified.
  ///
  /// In en, this message translates to:
  /// **'Pickup code verified successfully'**
  String get successPickupVerified;

  /// No description provided for @successVerified.
  ///
  /// In en, this message translates to:
  /// **'Code verified successfully'**
  String get successVerified;

  /// No description provided for @successScanned.
  ///
  /// In en, this message translates to:
  /// **'Code scanned successfully'**
  String get successScanned;

  /// No description provided for @flashTooltip.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get flashTooltip;

  /// No description provided for @switchCameraTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get switchCameraTooltip;

  /// No description provided for @currentLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocationLabel;

  /// No description provided for @pickupMarkerTitle.
  ///
  /// In en, this message translates to:
  /// **'{order}) Pickup - {name}'**
  String pickupMarkerTitle(String order, String name);

  /// No description provided for @pickupMarkerTitleWithCount.
  ///
  /// In en, this message translates to:
  /// **'Pickup ({count} pending)'**
  String pickupMarkerTitleWithCount(int count);

  /// No description provided for @pickupPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup point'**
  String get pickupPointLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending:'**
  String get pendingLabel;

  /// No description provided for @pickedUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Picked up:'**
  String get pickedUpLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address:'**
  String get addressLabel;

  /// No description provided for @noPickupLocationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No pickup location available'**
  String get noPickupLocationAvailable;

  /// No description provided for @noDeliveryLocationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No delivery location available'**
  String get noDeliveryLocationAvailable;

  /// No description provided for @noValidLocationToNavigate.
  ///
  /// In en, this message translates to:
  /// **'No valid location to navigate'**
  String get noValidLocationToNavigate;

  /// No description provided for @orderProcessed.
  ///
  /// In en, this message translates to:
  /// **'This order has already been processed'**
  String get orderProcessed;

  /// No description provided for @errorLoadingMap.
  ///
  /// In en, this message translates to:
  /// **'Error loading map'**
  String get errorLoadingMap;

  /// No description provided for @networkConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Network Configuration'**
  String get networkConfigTitle;

  /// No description provided for @logInfoButton.
  ///
  /// In en, this message translates to:
  /// **'Log Info'**
  String get logInfoButton;

  /// No description provided for @routeMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Map:'**
  String get routeMapTitle;

  /// No description provided for @startPoint.
  ///
  /// In en, this message translates to:
  /// **'Start Point'**
  String get startPoint;

  /// No description provided for @routeStart.
  ///
  /// In en, this message translates to:
  /// **'Route start'**
  String get routeStart;

  /// No description provided for @endPoint.
  ///
  /// In en, this message translates to:
  /// **'End Point'**
  String get endPoint;

  /// No description provided for @routeEnd.
  ///
  /// In en, this message translates to:
  /// **'Route end'**
  String get routeEnd;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @orderNumberPrefix.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderNumberPrefix;

  /// No description provided for @centerMap.
  ///
  /// In en, this message translates to:
  /// **'Center map'**
  String get centerMap;

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'Legend:'**
  String get legend;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MedRush - Medicine Delivery'**
  String get appTitle;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get statusPickedUp;

  /// No description provided for @statusInRoute.
  ///
  /// In en, this message translates to:
  /// **'In Route'**
  String get statusInRoute;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @orderTypeMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get orderTypeMedicines;

  /// No description provided for @orderTypeControlledMedicines.
  ///
  /// In en, this message translates to:
  /// **'Controlled Medicines'**
  String get orderTypeControlledMedicines;

  /// No description provided for @driverStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get driverStatusAvailable;

  /// No description provided for @driverStatusInRoute.
  ///
  /// In en, this message translates to:
  /// **'In Route'**
  String get driverStatusInRoute;

  /// No description provided for @driverStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get driverStatusDisconnected;

  /// No description provided for @pharmacyStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get pharmacyStatusActive;

  /// No description provided for @pharmacyStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get pharmacyStatusInactive;

  /// No description provided for @pharmacyStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get pharmacyStatusSuspended;

  /// No description provided for @pharmacyStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get pharmacyStatusUnderReview;

  /// No description provided for @failureReasonClientNotFound.
  ///
  /// In en, this message translates to:
  /// **'Client not found'**
  String get failureReasonClientNotFound;

  /// No description provided for @failureReasonWrongAddress.
  ///
  /// In en, this message translates to:
  /// **'Wrong address'**
  String get failureReasonWrongAddress;

  /// No description provided for @failureReasonNoCalls.
  ///
  /// In en, this message translates to:
  /// **'No calls received'**
  String get failureReasonNoCalls;

  /// No description provided for @failureReasonDeliveryRejected.
  ///
  /// In en, this message translates to:
  /// **'Delivery rejected'**
  String get failureReasonDeliveryRejected;

  /// No description provided for @failureReasonAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get failureReasonAccessDenied;

  /// No description provided for @failureReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get failureReasonOther;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @ago.
  ///
  /// In en, this message translates to:
  /// **'ago'**
  String get ago;

  /// No description provided for @inTime.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inTime;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minute;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @dateTypeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get dateTypeDelivery;

  /// No description provided for @dateTypePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get dateTypePickup;

  /// No description provided for @dateTypeAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get dateTypeAssignment;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @recentlyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Recently assigned'**
  String get recentlyAssigned;

  /// No description provided for @recentlyPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Recently picked up'**
  String get recentlyPickedUp;

  /// No description provided for @inRoute.
  ///
  /// In en, this message translates to:
  /// **'In route'**
  String get inRoute;

  /// No description provided for @recentlyDelivered.
  ///
  /// In en, this message translates to:
  /// **'Recently delivered'**
  String get recentlyDelivered;

  /// No description provided for @deliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery failed'**
  String get deliveryFailed;

  /// No description provided for @invalidTime.
  ///
  /// In en, this message translates to:
  /// **'Invalid time'**
  String get invalidTime;

  /// No description provided for @addressNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Address not specified'**
  String get addressNotSpecified;

  /// No description provided for @cityNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'City not specified'**
  String get cityNotSpecified;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @notificationOrderStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order Status Updated'**
  String get notificationOrderStatusUpdated;

  /// No description provided for @notificationOrderAssigned.
  ///
  /// In en, this message translates to:
  /// **'Order {code} has been assigned to a delivery driver'**
  String notificationOrderAssigned(Object code);

  /// No description provided for @notificationOrderPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Order {code} has been picked up by the delivery driver'**
  String notificationOrderPickedUp(Object code);

  /// No description provided for @notificationOrderInRoute.
  ///
  /// In en, this message translates to:
  /// **'Order {code} is on route to its destination'**
  String notificationOrderInRoute(Object code);

  /// No description provided for @notificationOrderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order {code} has been delivered successfully'**
  String notificationOrderDelivered(Object code);

  /// No description provided for @notificationOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery of order {code} has failed'**
  String notificationOrderFailed(Object code);

  /// No description provided for @notificationOrderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order {code} has been cancelled'**
  String notificationOrderCancelled(Object code);

  /// No description provided for @notificationOrderStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Order {code} status changed from {oldStatus} to {newStatus}'**
  String notificationOrderStatusChanged(
      Object code, Object newStatus, Object oldStatus);

  /// No description provided for @notificationDriverStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Driver Status Updated'**
  String get notificationDriverStatusUpdated;

  /// No description provided for @notificationDriverStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Driver {name} changed status from {oldStatus} to {newStatus}'**
  String notificationDriverStatusChanged(
      Object name, Object newStatus, Object oldStatus);

  /// No description provided for @notificationPharmacyStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Status Updated'**
  String get notificationPharmacyStatusUpdated;

  /// No description provided for @notificationPharmacyStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy {name} changed status from {oldStatus} to {newStatus}'**
  String notificationPharmacyStatusChanged(
      Object name, Object newStatus, Object oldStatus);

  /// No description provided for @userTypeAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get userTypeAdministrator;

  /// No description provided for @userTypeDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get userTypeDriver;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noPages.
  ///
  /// In en, this message translates to:
  /// **'No pages'**
  String get noPages;

  /// No description provided for @eventTypeCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get eventTypeCreated;

  /// No description provided for @eventTypeAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get eventTypeAssigned;

  /// No description provided for @eventTypePickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get eventTypePickedUp;

  /// No description provided for @eventTypeInRoute.
  ///
  /// In en, this message translates to:
  /// **'In Route'**
  String get eventTypeInRoute;

  /// No description provided for @eventTypeDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get eventTypeDelivered;

  /// No description provided for @eventTypeFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery Failed'**
  String get eventTypeFailed;

  /// No description provided for @eventTypeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get eventTypeCancelled;

  /// No description provided for @eventTypeRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get eventTypeRescheduled;

  /// No description provided for @eventTypeOrderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order Created'**
  String get eventTypeOrderCreated;

  /// No description provided for @eventTypeOrderAssigned.
  ///
  /// In en, this message translates to:
  /// **'Order Assigned'**
  String get eventTypeOrderAssigned;

  /// No description provided for @eventTypeRouteOptimized.
  ///
  /// In en, this message translates to:
  /// **'Route Optimized'**
  String get eventTypeRouteOptimized;

  /// No description provided for @eventTypeLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location Updated'**
  String get eventTypeLocationUpdated;

  /// No description provided for @eventTypeDriverConnected.
  ///
  /// In en, this message translates to:
  /// **'Driver Connected'**
  String get eventTypeDriverConnected;

  /// No description provided for @eventTypeDriverDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Driver Disconnected'**
  String get eventTypeDriverDisconnected;

  /// No description provided for @eventTypePharmacyConnected.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Connected'**
  String get eventTypePharmacyConnected;

  /// No description provided for @eventTypePharmacyDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Disconnected'**
  String get eventTypePharmacyDisconnected;

  /// No description provided for @eventTypeNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification Sent'**
  String get eventTypeNotificationSent;

  /// No description provided for @signatureTypeFirstTime.
  ///
  /// In en, this message translates to:
  /// **'First Time'**
  String get signatureTypeFirstTime;

  /// No description provided for @signatureTypeReception.
  ///
  /// In en, this message translates to:
  /// **'Reception'**
  String get signatureTypeReception;

  /// No description provided for @signatureTypeControlledMedicine.
  ///
  /// In en, this message translates to:
  /// **'Controlled Medicine'**
  String get signatureTypeControlledMedicine;

  /// No description provided for @signatureTypeAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Authorization'**
  String get signatureTypeAuthorization;

  /// No description provided for @signatureDescriptionFirstTime.
  ///
  /// In en, this message translates to:
  /// **'Initial patient signature to authorize the service'**
  String get signatureDescriptionFirstTime;

  /// No description provided for @signatureDescriptionReception.
  ///
  /// In en, this message translates to:
  /// **'Signature confirming receipt of the order'**
  String get signatureDescriptionReception;

  /// No description provided for @signatureDescriptionControlledMedicine.
  ///
  /// In en, this message translates to:
  /// **'Special signature required for controlled medicines'**
  String get signatureDescriptionControlledMedicine;

  /// No description provided for @signatureDescriptionAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Authorization signature for the delivery service'**
  String get signatureDescriptionAuthorization;

  /// No description provided for @defaultCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get defaultCity;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
