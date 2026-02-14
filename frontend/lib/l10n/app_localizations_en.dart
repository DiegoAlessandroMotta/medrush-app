// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle => 'Enter your credentials to access';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailHint => 'example@medrush.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get capsLockActive => 'Caps Lock is active';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get sessionExpiredWarning =>
      'Your session has expired. Please login again.';

  @override
  String get downloadApkTooltip => 'Download Android APP (APK)';

  @override
  String get checkingConnection => 'Checking server connection...';

  @override
  String get serverConnectionError => 'Could not connect to the server';

  @override
  String get deliveriesTab => 'Deliveries';

  @override
  String get historyTab => 'History';

  @override
  String get routeTab => 'Route';

  @override
  String get profileTab => 'Profile';

  @override
  String get searchOrders => 'Search orders...';

  @override
  String get filter => 'Filter';

  @override
  String get call => 'Call';

  @override
  String get navigate => 'Navigate';

  @override
  String get deliver => 'Deliver';

  @override
  String get viewDetails => 'View Details';

  @override
  String get noActiveOrders => 'You have no active orders';

  @override
  String get activeOrdersDescription =>
      'Assigned, picked up, and en-route orders will appear here';

  @override
  String get cannotOpenNavigation => 'Cannot open navigation';

  @override
  String get clientPhoneNotAvailable => 'Client phone not available';

  @override
  String get cannotMakeCall => 'Cannot make the call';

  @override
  String get infoCopied => 'Information copied to clipboard';

  @override
  String get errorCopyingInfo => 'Error copying information';

  @override
  String get errorLoadingOrders => 'Error loading orders';

  @override
  String get processingDelivery => 'Processing delivery...';

  @override
  String get deliveryDetails => 'Delivery Details';

  @override
  String get orderIdLabel => 'Order ID: ';

  @override
  String get clientLabel => 'Client: ';

  @override
  String productsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get products => 'Products';

  @override
  String get proofOfDelivery => 'Proof of Delivery';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get delete => 'Delete';

  @override
  String get noPhotoTaken => 'No photo taken yet';

  @override
  String get takePhotoInstruction =>
      'Please take a photo of the delivered package.';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get cancel => 'Cancel';

  @override
  String get signAndDeliver => 'Sign and Deliver';

  @override
  String errorTakingPhoto(Object error) {
    return 'Error taking photo: $error';
  }

  @override
  String get confirmDelivery => 'Confirm Delivery';

  @override
  String get confirmDeliveryQuestion =>
      'Are you sure you want to confirm the delivery of this order?';

  @override
  String get confirm => 'Confirm';

  @override
  String get deliverySuccess => 'Order delivered successfully';

  @override
  String deliveryError(Object error) {
    return 'Error delivering order: $error';
  }

  @override
  String get editDeliverySignature => 'Edit Delivery Signature';

  @override
  String get deliverySignature => 'Delivery Signature';

  @override
  String get sampleSignature => 'Sample Signature';

  @override
  String get mustSignBeforeSaving => 'You must sign before saving';

  @override
  String signatureSuccess(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'delivery': 'Delivery signature generated successfully',
        'sample': 'Sample signature generated successfully',
        'other': 'Signature generated successfully',
      },
    );
    return '$_temp0';
  }

  @override
  String get errorSavingSignature => 'Error saving signature';

  @override
  String get profileTitle => 'Profile';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get professionalInfo => 'Professional Information';

  @override
  String get systemStatus => 'System Status';

  @override
  String get security => 'Security';

  @override
  String get session => 'Session';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get deletePhoto => 'Delete photo';

  @override
  String get photoUpdateSuccess => 'Profile photo updated';

  @override
  String get photoUpdateError => 'Error updating photo';

  @override
  String get photoSelectError => 'Error selecting photo';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordInstruction =>
      'Enter your current password and the new password:';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get minCharacters => 'Minimum 8 characters';

  @override
  String get enterCurrentPassword => 'Enter your current password';

  @override
  String get enterNewPassword => 'Enter the new password';

  @override
  String get passwordMinLength =>
      'The new password must be at least 8 characters long';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordMustBeDifferent =>
      'The new password must be different from the current one';

  @override
  String get passwordUpdateSuccess => 'Password updated successfully';

  @override
  String get loadingProfile => 'Loading profile...';

  @override
  String get retry => 'Retry';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get driverLicense => 'Driver\'s License';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get driverStatus => 'Driver Status';

  @override
  String get activeUser => 'Active User';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get pharmaciesTab => 'Pharmacies';

  @override
  String get driversTab => 'Drivers';

  @override
  String get routesTab => 'Routes';

  @override
  String get settingsTab => 'Settings';

  @override
  String get configuration => 'Configuration';

  @override
  String get registerDriverTitle => 'Driver Registration';

  @override
  String get accountCreatedSuccess =>
      'Account created successfully. Please sign in.';

  @override
  String errorRegistering(Object error) {
    return 'Error registering: $error';
  }

  @override
  String get close => 'Close';

  @override
  String get noUserAuthenticated => 'No user authenticated';

  @override
  String get retryConnection => 'Retry connection';

  @override
  String get verifyConnectionAgain => 'Verify connection again';

  @override
  String connectedToServer(Object url) {
    return 'Connected to server: $url';
  }

  @override
  String get obtainingDownloadLink => 'Obtaining download link...';

  @override
  String get couldNotGetDownloadLink => 'Could not get download link';

  @override
  String get downloadStarted => 'Download started successfully';

  @override
  String get couldNotOpenDownloadLink => 'Could not open download link';

  @override
  String errorDownloadingApk(Object error) {
    return 'Error downloading APK: $error';
  }

  @override
  String connectionError(Object error) {
    return 'Connection error: $error';
  }

  @override
  String errorLoadingOrdersWithError(Object error) {
    return 'Error loading orders: $error';
  }

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get callClient => 'Call Client';

  @override
  String get navigateToPickup => 'Navigate to pickup';

  @override
  String get navigateToDelivery => 'Navigate to delivery';

  @override
  String get deliverWithoutSignature => 'Deliver without signature';

  @override
  String get allOrdersLoaded => 'All orders loaded';

  @override
  String loadingPage(Object current, Object total) {
    return 'Loading page $current of $total...';
  }

  @override
  String get errorDeletingPhoto => 'Error deleting photo';

  @override
  String errorLoadingHistoryWithError(Object error) {
    return 'Error loading history: $error';
  }

  @override
  String get orderIdShort => 'Order #';

  @override
  String get basicInfo => 'Basic Information';

  @override
  String get medications => 'Medications';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get address => 'Address';

  @override
  String get addressLine2 => 'Address Line 2';

  @override
  String get city => 'City';

  @override
  String get region => 'Region';

  @override
  String get postalCode => 'Postal Code';

  @override
  String get detail => 'Detail';

  @override
  String get accessCode => 'Access Code';

  @override
  String get buildingCode => 'Building Code';

  @override
  String get country => 'Country';

  @override
  String get type => 'Type';

  @override
  String get status => 'Status';

  @override
  String get priority => 'Priority';

  @override
  String get requiresSpecialSignature => 'Requires special signature';

  @override
  String get assignmentDate => 'Assignment Date';

  @override
  String get pickupLocation => 'Pickup Location';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get detailedLocation => 'Detailed Location';

  @override
  String get pharmacy => 'Pharmacy';

  @override
  String get pharmacyLocation => 'Pharmacy location';

  @override
  String get driver => 'Driver';

  @override
  String get datesAndProgress => 'Dates and Progress';

  @override
  String get pickupDate => 'Pickup Date';

  @override
  String get deliveryDate => 'Delivery Date';

  @override
  String get created => 'Created';

  @override
  String get lastUpdate => 'Last Update';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get estimatedDistance => 'Estimated Distance';

  @override
  String get observations => 'Observations';

  @override
  String get deliveryProof => 'Delivery Proof';

  @override
  String get deliveryPhoto => 'Delivery Photo';

  @override
  String get clientSignature => 'Client Signature';

  @override
  String get consentDocument => 'Consent Document';

  @override
  String get failureInfo => 'Failure Information';

  @override
  String get reason => 'Reason';

  @override
  String get notFound => 'Not found';

  @override
  String get barcodeTooltip => 'Barcode';

  @override
  String get couldNotOpenDocument => 'Could not open document';

  @override
  String get barcodeTitle => 'Barcode';

  @override
  String get orderNumber => 'Order #';

  @override
  String get client => 'Client';

  @override
  String get location => 'Location';

  @override
  String get date => 'Date';

  @override
  String get actions => 'Actions';

  @override
  String get noOrdersToShow => 'No orders to show';

  @override
  String get assignDriver => 'Assign Driver';

  @override
  String get edit => 'Edit';

  @override
  String get moreOptions => 'More options';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get markAsFailed => 'Mark as Failed';

  @override
  String get generateBarcode => 'Generate Barcode';

  @override
  String get notAvailable => 'Not available';

  @override
  String get assigned => 'Assigned';

  @override
  String get confirmDeliveryTitle => 'Confirm delivery';

  @override
  String get captureSignature => 'Capture signature';

  @override
  String get phoneCopied => 'Phone copied to clipboard';

  @override
  String get emailCopied => 'Email copied to clipboard';

  @override
  String get clientHasNoEmail => 'Client has no email registered';

  @override
  String get couldNotOpenMaps => 'Could not open Google Maps';

  @override
  String get deliveryStatus => 'Delivery Status';

  @override
  String get scheduledDeliveries => 'Scheduled deliveries';

  @override
  String get navigateToPickupPoint => 'Navigate to pickup point';

  @override
  String get navigateToDeliveryPoint => 'Navigate to delivery point';

  @override
  String get statusLabel => 'Status: ';

  @override
  String get details => 'Details';

  @override
  String get confirmDeliveryWithSignature =>
      'Do you want to capture the client signature before marking as delivered?';

  @override
  String errorUpdatingState(Object error) {
    return 'Error updating state: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get adminProfile => 'Admin Profile';

  @override
  String get updateProfile => 'Update Profile';

  @override
  String get passwordUpdateAvailable =>
      'Password update available after backend integration.';

  @override
  String get couldNotLoadUserInfo => 'Could not load user information';

  @override
  String get updateProfileButton => 'Update Profile';

  @override
  String get save => 'Save';

  @override
  String get required => 'Required';

  @override
  String get assignOrder => 'Assign Order';

  @override
  String get assign => 'Assign';

  @override
  String get assignOrderConfirm => 'Assign this order to your delivery list?';

  @override
  String get couldNotGetDriverInfo => 'Could not get driver information';

  @override
  String get noOrderWithBarcode => 'No order found with this barcode';

  @override
  String get errorProcessingBarcode => 'Error processing barcode';

  @override
  String get processingBarcode => 'Processing barcode...';

  @override
  String get assignedTo => 'Assigned to: ';

  @override
  String get loadingRoutes => 'Loading routes...';

  @override
  String get allRoutes => 'All routes';

  @override
  String get activeRoutes => 'Active routes';

  @override
  String get completedRoutes => 'Completed routes';

  @override
  String get allDrivers => 'All drivers';

  @override
  String get unknownDriver => 'Unknown driver';

  @override
  String get errorLoadingRoutes => 'Error loading routes';

  @override
  String get searchPharmacies => 'Search pharmacies...';

  @override
  String get allStatuses => 'All statuses';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get suspended => 'Suspended';

  @override
  String get inReview => 'In Review';

  @override
  String get view => 'View';

  @override
  String get pharmacySavedSuccess => 'Pharmacy saved successfully';

  @override
  String get pharmacyUpdatedSuccess => 'Pharmacy updated successfully';

  @override
  String get errorReloadPharmacies => 'Error reloading pharmacies';

  @override
  String get pharmacySavedButErrorReload =>
      'Pharmacy saved but error updating list';

  @override
  String pharmacyDeletedSuccess(Object name) {
    return 'Pharmacy \"$name\" deleted successfully';
  }

  @override
  String errorDeletePharmacy(Object error) {
    return 'Error deleting pharmacy: $error';
  }

  @override
  String get noPharmaciesFound => 'No pharmacies found';

  @override
  String get errorLoadingPharmacies => 'Error loading pharmacies';

  @override
  String get errorLoadingPharmaciesUnknown =>
      'Unknown error loading pharmacies';

  @override
  String get errorLoadingOrdersUnknown => 'Unknown error loading orders';

  @override
  String get printShippingLabelsTooltip => 'Print Shipping Labels';

  @override
  String get uploadCsvTooltip => 'Upload CSV';

  @override
  String get addOrderTooltip => 'Add Order';

  @override
  String get searchOrdersByClientCodePhone =>
      'Search by client, code, phone...';

  @override
  String get selectAll => 'Select All';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String statesCount(Object count) {
    return '$count states';
  }

  @override
  String get noDeliveriesFound => 'No deliveries found';

  @override
  String get noOrdersMatchFilters => 'No orders match the applied filters';

  @override
  String showingXOfYOrders(Object showing, Object total) {
    return 'Showing $showing of $total orders';
  }

  @override
  String pageXOfY(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String get orderBarcodeCaption => 'Order barcode';

  @override
  String get confirmDeletion => 'Confirm deletion';

  @override
  String confirmDeleteOrderQuestion(Object id) {
    return 'Are you sure you want to delete order #$id?';
  }

  @override
  String get deleteOrderIrreversible =>
      'This action cannot be undone. The order will be permanently deleted.';

  @override
  String orderDeletedSuccess(Object id) {
    return 'Order #$id deleted successfully';
  }

  @override
  String errorDeleteOrder(Object error) {
    return 'Error deleting order: $error';
  }

  @override
  String errorLoadingDrivers(String detail) {
    return 'Error loading drivers: $detail';
  }

  @override
  String selectDriverForOrder(Object name) {
    return 'Select a driver for the order of $name';
  }

  @override
  String get noDriversAvailable => 'No drivers available';

  @override
  String get codeLabel => 'Code: ';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String confirmCancelOrderQuestion(Object id) {
    return 'Are you sure you want to cancel order #$id?';
  }

  @override
  String get errorLoadingDriversUnknown => 'Could not load drivers list';

  @override
  String get driverCreatedSuccess => 'Driver created successfully';

  @override
  String get driverUpdatedSuccess => 'Driver updated successfully';

  @override
  String driverDeletedSuccess(Object name) {
    return 'Driver \"$name\" deleted successfully';
  }

  @override
  String errorDeleteDriver(Object error) {
    return 'Error deleting driver: $error';
  }

  @override
  String get searchDrivers => 'Search drivers...';

  @override
  String get noDriversMatchFilters =>
      'No drivers found with the applied filters';

  @override
  String get noDriversRegistered => 'No drivers registered';

  @override
  String get addDriver => 'Add Driver';

  @override
  String deactivatedDriversCount(Object count) {
    return 'Deactivated drivers ($count)';
  }

  @override
  String get driverLabel => 'Driver';

  @override
  String get idLabel => 'ID: ';

  @override
  String get driverPhoneNotAvailable => 'Driver phone not available';

  @override
  String get errorMakingCall => 'Error making call';

  @override
  String get lastActivityNoActivity => 'no activity';

  @override
  String get lastActivityJustNow => 'just now';

  @override
  String lastActivityMinutesAgo(Object count) {
    return '$count min ago';
  }

  @override
  String lastActivityHoursAgo(Object count) {
    return '$count h ago';
  }

  @override
  String lastActivityDaysAgo(Object count) {
    return '$count d ago';
  }

  @override
  String get enterValidName => 'Enter a valid name.';

  @override
  String get nameMinLength3 => 'Name must be at least 3 characters.';

  @override
  String get enterEmailAddress => 'Enter an email address.';

  @override
  String get invalidEmail => 'Invalid email.';

  @override
  String get enterValidPhone => 'Enter a valid phone number.';

  @override
  String get repeatNewPassword => 'Repeat the new password';

  @override
  String get confirmPasswordRequired => 'Confirm the new password.';

  @override
  String get newPasswordMin12 => 'Use at least 12 characters.';

  @override
  String get passwordMustIncludeComplexity =>
      'Must include uppercase, lowercase and numbers.';

  @override
  String get updatePassword => 'Update password';

  @override
  String get tableHeaderPhoto => 'PHOTO';

  @override
  String get tableHeaderName => 'NAME';

  @override
  String get tableHeaderEmail => 'EMAIL';

  @override
  String get tableHeaderPhone => 'PHONE';

  @override
  String get tableHeaderVehicle => 'VEHICLE';

  @override
  String get tableHeaderLastActivity => 'LAST ACTIVITY';

  @override
  String get noDriversToShow => 'No drivers to show';

  @override
  String get viewDetailsTooltip => 'View details';

  @override
  String get copyEmail => 'Copy Email';

  @override
  String confirmDeleteDriverQuestion(Object name) {
    return 'Are you sure you want to delete driver \"$name\"?';
  }

  @override
  String get deleteDriverIrreversible =>
      'This action cannot be undone. The driver will be permanently deleted.';

  @override
  String get cannotOpenCallApp => 'Could not open phone app';

  @override
  String errorMakingCallWithError(Object error) {
    return 'Error making call: $error';
  }

  @override
  String get noEmailAvailable => 'No email available';

  @override
  String errorCopyingEmail(Object error) {
    return 'Error copying email: $error';
  }

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get requiredField => 'Required';

  @override
  String get min6Characters => 'Minimum 6 characters';

  @override
  String get passwordsDoNotMatchShort => 'Do not match';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get couldNotUpdatePassword => 'Could not update password';

  @override
  String errorSavingDriver(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get errorSavingDriverUnknown => 'Unknown error saving driver';

  @override
  String get selectExpiryDate => 'Select expiry date';

  @override
  String errorSelectingDate(Object error) {
    return 'Error selecting date: $error';
  }

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get phoneMustBe10Digits => 'Phone must be exactly 10 digits';

  @override
  String get editDriver => 'Edit Driver';

  @override
  String get newDriver => 'New Driver';

  @override
  String get modifyingDriver => 'Modifying driver';

  @override
  String get creatingDriver => 'Creating new driver';

  @override
  String get sectionPersonalInfo => 'Personal Information';

  @override
  String get sectionLicenseInfo => 'License Information';

  @override
  String get sectionVehicleInfo => 'Vehicle Information';

  @override
  String get sectionDocuments => 'Documents and Photos';

  @override
  String get sectionSettings => 'Settings';

  @override
  String get fullNameRequired => 'Full Name *';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get countryDefaultUSA => 'Will be sent as USA by default';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMin6Chars => 'Password must be at least 6 characters';

  @override
  String get idDriverLicenseLabel => 'ID (Driver\'s License or State ID)';

  @override
  String get idHelper => 'Letters and numbers; no spaces or hyphens';

  @override
  String get idMin5Chars => 'ID must be at least 5 characters';

  @override
  String get alphanumericOnly => 'Letters and numbers only';

  @override
  String get licenseNumberLabel => 'License Number';

  @override
  String get licenseFormatHelper => 'Format: Letters and numbers';

  @override
  String get licenseMin5Chars => 'License number must be at least 5 characters';

  @override
  String get uppercaseAndNumbersOnly => 'Uppercase letters and numbers only';

  @override
  String get licenseExpiryLabel => 'License Expiry';

  @override
  String get selectDate => 'Select date';

  @override
  String get vehiclePlateLabel => 'Vehicle Plate';

  @override
  String get vehiclePlateFormat => 'Format: ABC-123 or ABC123';

  @override
  String get plateMin4Chars => 'Plate must be at least 4 characters';

  @override
  String get uppercaseNumbersDashes =>
      'Uppercase letters, numbers and hyphens only';

  @override
  String get vehicleBrandLabel => 'Vehicle Brand';

  @override
  String get vehicleBrandHelper => 'E.g.: Toyota, Honda, Ford';

  @override
  String get brandMin2Chars => 'Brand must be at least 2 characters';

  @override
  String get lettersAndSpacesOnly => 'Letters and spaces only';

  @override
  String get vehicleModelLabel => 'Vehicle Model';

  @override
  String get vehicleModelHelper => 'E.g.: Corolla, Civic, Focus';

  @override
  String get modelMin2Chars => 'Model must be at least 2 characters';

  @override
  String get alphanumericSpacesDashes =>
      'Letters, numbers, spaces and hyphens only';

  @override
  String get vehicleRegistrationLabel => 'Vehicle Registration Code';

  @override
  String get vehicleRegistrationHelper => 'Alphanumeric; e.g.: ABC123456';

  @override
  String get min5Characters => 'Must be at least 5 characters';

  @override
  String get photoLicenseTitle => 'Driver\'s License Photo';

  @override
  String get photoLicenseSubtitle => 'Valid driver\'s license';

  @override
  String get photoLicenseOrIdOptionalLabel =>
      'Driver\'s License / ID (optional)';

  @override
  String get licenseOrIdNumberOptionalLabel => 'License / ID (optional)';

  @override
  String get photoInsuranceTitle => 'Vehicle Insurance Photo';

  @override
  String get photoInsuranceSubtitle => 'Valid policy';

  @override
  String get stateRequired => 'Status *';

  @override
  String get userTypeLabel => 'User Type';

  @override
  String get verifiedLabel => 'Verified';

  @override
  String get documentsSection => 'Documents';

  @override
  String get loadingPharmacyInfo => 'Loading pharmacy information...';

  @override
  String get notAssignedToAnyPharmacy => 'Not assigned to any pharmacy';

  @override
  String get profilePhotoTitle => 'Profile photo';

  @override
  String get documentTitle => 'Document';

  @override
  String get adminRole => 'Administrator';

  @override
  String get driverRole => 'Driver';

  @override
  String get pharmacyAssignmentSection => 'Pharmacy Assignment';

  @override
  String get systemInfoSection => 'System Information';

  @override
  String get registrationDateLabel => 'Registration Date';

  @override
  String get lastActivityLabel => 'Last Activity';

  @override
  String get expiryLabel => 'Expiry';

  @override
  String get photoLicenseLabel => 'License Photo';

  @override
  String get digitalSignatureLabel => 'Digital Signature';

  @override
  String get pharmacyDetailTitle => 'Pharmacy Detail';

  @override
  String get generalInfoTitle => 'General Information';

  @override
  String get locationTitle => 'Location';

  @override
  String get contactTitle => 'Contact';

  @override
  String get additionalInfoTitle => 'Additional Information';

  @override
  String get responsibleLabel => 'Responsible';

  @override
  String get responsiblePhoneLabel => 'Responsible Phone';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get scheduleLabel => 'Schedule';

  @override
  String get delivery24hLabel => 'Delivery 24h';

  @override
  String get registrationDateShort => 'Registration Date';

  @override
  String pharmacyLocationTitle(Object name) {
    return 'Location of $name';
  }

  @override
  String get idShort => 'ID';

  @override
  String get razonSocialLabel => 'Legal Name';

  @override
  String get rucLabel => 'EIN';

  @override
  String get cadenaLabel => 'Chain';

  @override
  String get stateRegionLabel => 'State';

  @override
  String get zipCodeLabel => 'ZIP';

  @override
  String get lastUpdateLabel => 'Last Update';

  @override
  String get statusShort => 'Status';

  @override
  String get selectPharmacyLocationTitle => 'Select Pharmacy Location';

  @override
  String get updatingPharmacy => 'Updating pharmacy...';

  @override
  String get creatingPharmacy => 'Creating pharmacy...';

  @override
  String get errorUpdatingPharmacy => 'Error updating pharmacy';

  @override
  String get errorCreatingPharmacy => 'Error creating pharmacy';

  @override
  String get errorDeletingPharmacy => 'Error deleting pharmacy';

  @override
  String get pleaseEnterPharmacyName => 'Please enter the pharmacy name';

  @override
  String get pleaseEnterResponsible => 'Please enter the responsible person';

  @override
  String get pleaseEnterPhone => 'Please enter the phone number';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterRuc => 'Please enter the RUC';

  @override
  String get pharmacyStatusTitle => 'Pharmacy Status';

  @override
  String get available => 'Available';

  @override
  String get pleaseEnterCity => 'Please enter the city';

  @override
  String get editPharmacy => 'Edit Pharmacy';

  @override
  String get newPharmacy => 'New Pharmacy';

  @override
  String get mapLocationTitle => 'Map location';

  @override
  String get geocodingErrorMap => 'Geocoding error on small map';

  @override
  String get pleaseEnterLatitude => 'Please enter the latitude';

  @override
  String get pleaseEnterValidLatitude => 'Please enter a valid latitude';

  @override
  String get pleaseEnterLongitude => 'Please enter the longitude';

  @override
  String get pleaseEnterValidLongitude => 'Please enter a valid longitude';

  @override
  String get updatePharmacy => 'Update Pharmacy';

  @override
  String get createPharmacy => 'Create Pharmacy';

  @override
  String confirmDeletePharmacyQuestion(Object name) {
    return 'Are you sure you want to delete pharmacy \"$name\"?\n\nThis action cannot be undone.';
  }

  @override
  String get pharmacyNameLabel => 'Pharmacy Name *';

  @override
  String get chainOptionalLabel => 'Chain (optional)';

  @override
  String get responsibleRequiredLabel => 'Responsible *';

  @override
  String get responsiblePhoneOptionalLabel => 'Responsible Phone (optional)';

  @override
  String get phoneRequiredLabel => 'Phone *';

  @override
  String get emailOptionalLabel => 'Email (optional)';

  @override
  String get rucRequiredLabel => 'RUC *';

  @override
  String get rucEinOptionalLabel => 'EIN (optional)';

  @override
  String get cityRequiredLabel => 'City *';

  @override
  String get zipOptionalLabel => 'ZIP Code (optional)';

  @override
  String get scheduleOptionalLabel => 'Schedule (optional)';

  @override
  String get delivery24hHoursLabel => 'Delivery 24 hours';

  @override
  String get addressLine1RequiredLabel => 'Address Line 1 *';

  @override
  String get addressLine2OptionalLabel => 'Address Line 2 (optional)';

  @override
  String get pleaseEnterAddressLine1 => 'Please enter address line 1';

  @override
  String get addressLine1HelperText => 'Street, avenue, etc.';

  @override
  String get addressLine2HelperText => 'Floor, apartment, reference, etc.';

  @override
  String get deletePharmacyIrreversible =>
      'This action cannot be undone. The pharmacy will be permanently deleted.';

  @override
  String confirmDeletePharmacyQuestionShort(Object name) {
    return 'Are you sure you want to delete pharmacy \"$name\"?';
  }

  @override
  String get latitudeRequiredLabel => 'Latitude *';

  @override
  String get longitudeRequiredLabel => 'Longitude *';

  @override
  String get saving => 'Saving...';

  @override
  String get barcodeLabel => 'Barcode';

  @override
  String get assignDriverTitle => 'Assign Driver';

  @override
  String get noActiveDrivers => 'No active drivers';

  @override
  String get confirmAssignment => 'Confirm Assignment';

  @override
  String get cancelOrderTitle => 'Cancel Order';

  @override
  String get confirmCancellation => 'Confirm Cancellation';

  @override
  String get markAsFailedTitle => 'Mark as Failed';

  @override
  String get failureReasonLabel => 'Failure reason';

  @override
  String get observationsOptionalLabel => 'Observations (optional)';

  @override
  String get failureDetailsHint => 'Additional details about the failure...';

  @override
  String get confirmFailure => 'Confirm Failure';

  @override
  String get barcodeOrderDescription => 'Order barcode';

  @override
  String get errorDeletingOrder => 'Error deleting order';

  @override
  String orderCancelledSuccess(Object id) {
    return 'Order #$id cancelled successfully';
  }

  @override
  String get errorCancellingOrder => 'Error cancelling order';

  @override
  String get cancelOrderIrreversible =>
      'This action will change the order status to \"Cancelled\" and cannot be undone.';

  @override
  String selectFailureReasonForOrder(Object id) {
    return 'Select the failure reason for order #$id';
  }

  @override
  String get markAsFailedIrreversible =>
      'This action will change the order status to \"Failed\" and will record the current location.';

  @override
  String get phoneHint => '5551234567';

  @override
  String get stateOptionalLabel => 'State (optional)';

  @override
  String get districtRequiredLabel => 'District *';

  @override
  String get postalCodeOptionalLabel => 'Postal Code (optional)';

  @override
  String get deliveryAddressLine1Label => 'Delivery Address Line 1 *';

  @override
  String get deliveryAddressLine2OptionalLabel =>
      'Delivery Address Line 2 (optional)';

  @override
  String get add => 'Add';

  @override
  String get driverOptionalLabel => 'Driver (optional)';

  @override
  String get loadingDrivers => 'Loading drivers...';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get pharmacyRequiredLabel => 'Pharmacy *';

  @override
  String get loadingPharmacies => 'Loading pharmacies...';

  @override
  String get clientNameRequiredLabel => 'Client Name *';

  @override
  String get buildingAccessCodeOptionalLabel =>
      'Building Access Code (optional)';

  @override
  String get orderTypeRequiredLabel => 'Order Type *';

  @override
  String get addMedicationTitle => 'Add Medication';

  @override
  String get medicationNameRequiredLabel => 'Medication Name *';

  @override
  String get quantityRequiredLabel => 'Quantity *';

  @override
  String get selectDriverTitle => 'Select Driver';

  @override
  String get searchDriverHint => 'Search by name, phone or email...';

  @override
  String get unassignDriverOption => 'Do not assign driver to this order';

  @override
  String get select => 'Select';

  @override
  String get selectDeliveryLocationTitle => 'Select Delivery Location';

  @override
  String get noMedicationsAddedHint =>
      'No medications added. Press \"Add\" to add medications.';

  @override
  String get routeDetailsTitle => 'Route Details';

  @override
  String get noName => 'No name';

  @override
  String get completed => 'Completed';

  @override
  String get unknown => 'Unknown';

  @override
  String get distanceLabel => 'Distance';

  @override
  String get estimatedTimeLabel => 'Estimated Time';

  @override
  String get additionalDetailsLabel => 'Additional details';

  @override
  String get startPointLabel => 'Start Point';

  @override
  String get endPointLabel => 'End Point';

  @override
  String get creationDateLabel => 'Creation Date';

  @override
  String get routeOrdersTitle => 'Route Orders';

  @override
  String get refreshOrdersTooltip => 'Refresh orders';

  @override
  String get clientNotSpecified => 'Client not specified';

  @override
  String get oldOrdersCleanupTitle => 'Old Orders File Cleanup';

  @override
  String get oldOrdersCleanupDescription =>
      'This action will permanently delete only multimedia files (delivery photos and digital signatures) from orders delivered more than the selected time ago. Order data will remain intact.';

  @override
  String get weeksBackLabel => 'Weeks back';

  @override
  String get processing => 'Processing...';

  @override
  String get saveConfiguration => 'Save Configuration';

  @override
  String get confirmCleanup => 'Confirm Cleanup';

  @override
  String get confirmCleanupDescription =>
      'This action will permanently delete only multimedia files (photos and signatures). Order data will remain intact.';

  @override
  String get cleanupStartedSuccess =>
      'Multimedia file cleanup for old orders has been started successfully';

  @override
  String get errorStartingCleanup => 'Error starting cleanup';

  @override
  String get googleApiUsageTitle => 'Google API Usage';

  @override
  String get refreshMetricsTooltip => 'Refresh metrics';

  @override
  String get apiCallsLast30Days => 'API Calls (Last 30 days)';

  @override
  String get errorLoadingMetrics => 'Error loading metrics';

  @override
  String get requestsLabel => 'Requests';

  @override
  String get servicesLabel => 'Services';

  @override
  String get costPerRequest => 'Cost per request';

  @override
  String get totalCost => 'Total cost';

  @override
  String get noUsageDataAvailable => 'No usage data available';

  @override
  String get metricsWillAppearWhenRequests =>
      'Metrics will appear when API requests are made';

  @override
  String get periodLabel => 'Period';

  @override
  String get weekLabel => 'week';

  @override
  String get weeksLabel => 'weeks';

  @override
  String confirmCleanupWeeksQuestion(Object count, Object weeksLabel) {
    return 'Are you sure you want to delete only multimedia files (photos and signatures) from orders delivered more than $count $weeksLabel ago?';
  }

  @override
  String get selectPharmacyRequired => 'You must select a pharmacy';

  @override
  String get noCsvDataToUpload => 'No CSV data to upload';

  @override
  String get csvUploadSuccess =>
      'CSV uploaded successfully. You will receive a notification when processing is complete.';

  @override
  String get errorUploadingCsv => 'Error uploading CSV';

  @override
  String get csvTemplateReady =>
      'CSV template generated and ready to download.';

  @override
  String get errorDownloadingTemplate => 'Error downloading template';

  @override
  String get generatePdfTitle => 'Generate PDF';

  @override
  String get filterByNameAddressHint => 'Filter by name, address';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get selectAllOrders => 'Select All';

  @override
  String get errorLoadingPage => 'Error loading page';

  @override
  String get noDriverInfoAvailable => 'No driver information available';

  @override
  String get errorLoadingRouteDetails => 'Could not load route details';

  @override
  String get errorLoadingRouteDetailsWithError => 'Error loading details';

  @override
  String get driverDetailsTitle => 'Driver Details';

  @override
  String get currentRouteLabel => 'Current Route';

  @override
  String get routeIdLabel => 'Route ID';

  @override
  String get routeNameLabel => 'Route Name';

  @override
  String get totalDistanceLabel => 'Total Distance';

  @override
  String get assignedOrdersLabel => 'Assigned Orders';

  @override
  String get calculationDateLabel => 'Calculation Date';

  @override
  String get startDateLabel => 'Start Date';

  @override
  String get completedDateLabel => 'Completed Date';

  @override
  String get viewRoute => 'View Route';

  @override
  String ordersInOptimizedOrderCount(Object count) {
    return '$count orders in optimized order';
  }

  @override
  String get pickupLocationLabel => 'Pickup Location';

  @override
  String get deliveryLocationLabel => 'Delivery Location';

  @override
  String get typeLabel => 'Type';

  @override
  String get ordersUpdatedSuccess => 'Orders updated successfully';

  @override
  String get errorUpdatingOrders => 'Error updating orders';

  @override
  String get lessThanOneMonth => 'less than 1 month';

  @override
  String get aboutOneMonth => '~1 month';

  @override
  String aboutMonthsCount(Object count) {
    return '~$count months';
  }

  @override
  String weeksBackDisplay(Object count, Object weeksLabel) {
    return '$count $weeksLabel ago';
  }

  @override
  String get weekShortLabel => 'wk';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get csvValidationErrorsPrefix => 'Errors found in CSV:';

  @override
  String get errorChangingItemsPerPage => 'Error changing items per page';

  @override
  String get copyData => 'Copy Data';

  @override
  String get generatingPdf => 'Generating PDF...';

  @override
  String get loadingOrdersForPdf => 'Loading orders for PDF...';

  @override
  String get noPendingOrdersForPdf => 'No pending orders to generate PDF';

  @override
  String get pendingOrdersPdfDescription =>
      'Pending orders will appear here to generate shipping labels';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get dateDayBeforeYesterday => 'Day before yesterday';

  @override
  String get dateThreeDaysAgo => '3 days ago';

  @override
  String ordersCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String get pdfDownloadUrlNotReceived => 'PDF download URL was not received';

  @override
  String get unknownErrorGeneratingPdf => 'Unknown error generating PDF';

  @override
  String get errorGeneratingPdf => 'Error generating PDF';

  @override
  String errorGeneratingPdfWithError(Object error) {
    return 'Error generating PDF: $error';
  }

  @override
  String get pdfGenerationTimeout =>
      'PDF generation took too long. Try with fewer labels.';

  @override
  String get onlyPending => 'Pending Only';

  @override
  String get understood => 'Understood';

  @override
  String get csvHelpTitle => 'Help - Upload CSV';

  @override
  String get csvHelpHowToUse => 'How to use this tool:';

  @override
  String get csvHelpStep1Title => '1. Download template';

  @override
  String get csvHelpStep1Description =>
      'Click the download icon to get the CSV template with the required columns.';

  @override
  String get csvHelpStep2Title => '2. Fill in data';

  @override
  String get csvHelpStep2Description =>
      'Complete the template with order data. Coordinates must be in \"latitude, longitude\" format.';

  @override
  String get csvHelpStep3Title => '3. Upload file';

  @override
  String get csvHelpStep3Description =>
      'Drag and drop your CSV file or click to select it.';

  @override
  String get csvHelpStep4Title => '4. Select pharmacy';

  @override
  String get csvHelpStep4Description =>
      'Choose the pharmacy to which the orders will be assigned.';

  @override
  String get csvHelpStep5Title => '5. Process';

  @override
  String get csvHelpStep5Description =>
      'Click \"Process\" to upload the orders to the system.';

  @override
  String get csvHelpTipTitle => 'Important tip:';

  @override
  String get csvHelpTipCoordinates =>
      'Coordinates must be in decimal format: \"26.037737, -80.179550\" for USA.';

  @override
  String orderAssignedToName(Object name) {
    return 'Order assigned to $name';
  }

  @override
  String get errorAssigningOrder => 'Error assigning';

  @override
  String dateOfType(Object type) {
    return 'Date of $type';
  }

  @override
  String get noPharmaciesToShow => 'No pharmacies to show';

  @override
  String get noResponsible => 'No responsible';

  @override
  String get noPhone => 'No phone';

  @override
  String get noCity => 'No city';

  @override
  String get tableHeaderAddress => 'ADDRESS';

  @override
  String get tableHeaderResponsible => 'RESPONSIBLE';

  @override
  String get tableHeaderCity => 'CITY';

  @override
  String get tableHeaderLocation => 'LOCATION';

  @override
  String get errorLoadingPharmaciesForForm =>
      'Error loading pharmacies for form';

  @override
  String errorLoadingData(Object error) {
    return 'Error loading data: $error';
  }

  @override
  String get selectLocationOnMap => 'You must select a location on the map';

  @override
  String get orderUpdatedSuccess => 'Order updated successfully';

  @override
  String get orderCreatedSuccess => 'Order created successfully';

  @override
  String get errorUpdatingOrder => 'Error updating order';

  @override
  String get errorCreatingOrder => 'Error creating order';

  @override
  String errorSavingOrder(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get editDelivery => 'Edit Delivery';

  @override
  String get newDelivery => 'New Delivery';

  @override
  String get creatingNewDelivery => 'Creating new delivery';

  @override
  String get saveDelivery => 'Save Delivery';

  @override
  String get districtRequired => 'District is required';

  @override
  String get deliveryAddressLine1Required =>
      'Delivery address line 1 is required';

  @override
  String get orderStatusLabel => 'Order Status';

  @override
  String quantityLabelShort(Object count) {
    return 'Quantity: $count';
  }

  @override
  String get medicationDefaultName => 'Medication';

  @override
  String get selectDriverForOrderHint =>
      'Select a driver to assign to the order';

  @override
  String driversAvailableTapToSearch(Object count) {
    return '$count drivers available - Tap to search';
  }

  @override
  String driversAvailableCount(Object count) {
    return '$count available';
  }

  @override
  String get buildingAccessCodeHelper =>
      'Code to access building or condominium';

  @override
  String get phoneRequired => 'Phone is required';

  @override
  String get errorUnassigningDriver => 'Error unassigning driver';

  @override
  String errorAssigningDriver(String detail) {
    return 'Error assigning driver: $detail';
  }

  @override
  String get errorFetchingUpdatedData => 'Error fetching updated data';

  @override
  String get clientNameRequired => 'Client name is required';

  @override
  String get medicationNameRequired => 'Name is required';

  @override
  String get medicationQuantityRequired => 'Quantity is required';

  @override
  String get phoneLengthBetween => 'Phone must be between 10 and 12 digits';

  @override
  String errorChangingDriver(Object error) {
    return 'Error changing driver: $error';
  }

  @override
  String errorRefreshingData(Object error) {
    return 'Error refreshing data: $error';
  }

  @override
  String get enterValidQuantity => 'Enter a valid quantity';

  @override
  String get uploadOrdersFromCsvTitle => 'Upload Orders from CSV';

  @override
  String get backTooltip => 'Back';

  @override
  String get downloadCsvTemplateTooltip => 'Download CSV template';

  @override
  String get helpTooltip => 'Help';

  @override
  String get validationProgressTitle => 'Validation Progress';

  @override
  String get allRecordsHaveValidCoordinates =>
      'All records have valid coordinates';

  @override
  String get dragDropCsvHere => 'Drag and drop your CSV file here';

  @override
  String get orClickToSelectFile => 'or click to select a file';

  @override
  String get fileInfoTitle => 'File information';

  @override
  String get fileSizeFormatHint =>
      'Max size: 10MB • Format: CSV • Encoding: UTF-8';

  @override
  String get csvFileLabel => 'CSV file';

  @override
  String recordsLoadComplete(Object count, Object fileName) {
    return '$fileName - $count records - Load complete';
  }

  @override
  String get selectPharmacyToAssignOrders => 'Select Pharmacy to assign orders';

  @override
  String get noDataToShow => 'No data to show';

  @override
  String get selectCsvFileToPreview => 'Select a CSV file to preview the data';

  @override
  String get noLocation => 'No location';

  @override
  String get emptyField => 'Empty field';

  @override
  String get processButton => 'Process';

  @override
  String get errorLoadingPharmaciesForExport =>
      'Error loading pharmacies for export';

  @override
  String recordsValidCount(Object total, Object valid) {
    return '$valid/$total valid';
  }

  @override
  String recordsNeedValidCoordinates(Object count) {
    return '$count records need valid coordinates';
  }

  @override
  String get userCanAccessSystem => 'User can access the system';

  @override
  String get userDisabled => 'User disabled';

  @override
  String get couldNotUpdateActiveStatus => 'Could not update active status';

  @override
  String get updateLabel => 'Update';

  @override
  String get createDriver => 'Create Driver';

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String get driverPhotoPlaceholder => 'Driver photo';

  @override
  String errorUploadingImage(Object error) {
    return 'Error uploading image: $error';
  }

  @override
  String errorUpdatingActiveStatus(Object error) {
    return 'Error: $error';
  }

  @override
  String get locationLabel => 'Location';

  @override
  String get errorGettingAddress => 'Error getting address';

  @override
  String get tapMapToSelectLocation => 'Tap the map to select a location';

  @override
  String get centerButton => 'Center';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get barcodeCodeCopied => 'Code copied to clipboard';

  @override
  String get copyCodeTooltip => 'Copy code';

  @override
  String get regenerateButton => 'Regenerate';

  @override
  String get alphanumericLabel => 'Alphanumeric';

  @override
  String get numericLabel => 'Numeric';

  @override
  String get errorGeneratingBarcode => 'Error generating barcode';

  @override
  String get errorLoadingImage => 'Error loading image';

  @override
  String get serverResponseError => 'Server response error';

  @override
  String get errorLoggingOut => 'Error logging out';

  @override
  String get errorUpdatingProfile => 'Error updating profile';

  @override
  String get selectAPharmacy => 'Select a pharmacy';

  @override
  String get centralPharmacy => 'Central Pharmacy';

  @override
  String get clearCsv => 'Clear CSV';

  @override
  String get orderTypeMedicalSupplies => 'Medical Supplies';

  @override
  String get orderTypeMedicalEquipment => 'Medical Equipment';

  @override
  String get orderTypeControlledMedications => 'Controlled Medications';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get errorLabel => 'Error';

  @override
  String driverAssignedSuccess(String name) {
    return 'Driver $name assigned successfully';
  }

  @override
  String errorWithDetail(String detail) {
    return 'Error: $detail';
  }

  @override
  String orderCanceledSuccess(String id) {
    return 'Order #$id canceled successfully';
  }

  @override
  String errorCancelingOrder(String detail) {
    return 'Error canceling order: $detail';
  }

  @override
  String orderMarkedFailedSuccess(String id) {
    return 'Order #$id marked as failed';
  }

  @override
  String errorMarkingOrderFailed(String detail) {
    return 'Error marking order as failed: $detail';
  }

  @override
  String get defaultSchedulePlaceholder => 'Mon-Fri: 8:00-20:00';

  @override
  String get orderAssignedSuccess => 'Order assigned successfully';

  @override
  String errorAssigningOrderDetail(String detail) {
    return 'Error assigning order: $detail';
  }

  @override
  String get orderDelivered => 'Order delivered';

  @override
  String get orderFailed => 'Order failed';

  @override
  String get orderCancelledStatus => 'Order cancelled';

  @override
  String get reoptimizeRoute => 'Re-optimize route';

  @override
  String get inQueue => 'In Queue';

  @override
  String get pickupAt => 'Pick up at: ';

  @override
  String get routeNotAvailable => 'Route not available';

  @override
  String get toPickup => 'to pickup';

  @override
  String get toDelivery => 'to delivery';

  @override
  String get completedStatus => 'completed';

  @override
  String get pickupLabel => 'Pick up: ';

  @override
  String get clientInformation => 'Client Information';

  @override
  String get copyPhoneTooltip => 'Copy phone';

  @override
  String get districtLabel => 'District';

  @override
  String get viewMap => 'View Map';

  @override
  String get noChain => 'No chain';

  @override
  String get orderTypeSectionTitle => 'Order Type';

  @override
  String get orderTypeLabel => 'Order type';

  @override
  String get signatureCaptured => 'Signature Captured';

  @override
  String get deliveryNotFound => 'Delivery not found';

  @override
  String deliveryNotFoundWithId(String id) {
    return 'Delivery #$id does not exist';
  }

  @override
  String get pickedUp => 'Picked up';

  @override
  String get deliveredStatus => 'Delivered';

  @override
  String get noSignatureAvailable => 'No signature available';

  @override
  String get errorLoadingSignature => 'Error loading signature';

  @override
  String get errorRenderingSvg => 'Error rendering SVG';

  @override
  String get errorDecodingSignature => 'Error decoding signature';

  @override
  String get invalidSignatureFormat => 'Invalid signature format';

  @override
  String get onRoute => 'On Route';

  @override
  String get next => 'Next';

  @override
  String get pickUpAction => 'Pick up';

  @override
  String get filterDelivered => 'Delivered';

  @override
  String get filterCancelled => 'Cancelled';

  @override
  String get filterFailed => 'Failed';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String get profilePhotoDeleted => 'Profile photo deleted';

  @override
  String get confirmDeleteProfilePhotoQuestion =>
      'Are you sure you want to delete your profile photo?';

  @override
  String get securitySectionTitle => 'Security';

  @override
  String get changeButton => 'Change';

  @override
  String get min8Characters => 'Minimum 8 characters';

  @override
  String get newPasswordMin8Chars =>
      'The new password must be at least 8 characters';

  @override
  String get passwordChangedSuccess => 'Password updated successfully';

  @override
  String errorChangingPassword(String detail) {
    return 'Error changing password: $detail';
  }

  @override
  String get errorChangingPasswordShort => 'Error changing password';

  @override
  String get activeSessions => 'Active sessions';

  @override
  String get drivingLicense => 'Driver\'s License';

  @override
  String get errorLoadingHistory => 'Unknown error loading history';

  @override
  String get orderIdShortLabel => 'Order ID:';

  @override
  String get pharmacyIdLabel => 'Pharmacy ID:';

  @override
  String get copyButton => 'Copy';

  @override
  String formatNumericDigits(int count) {
    return 'Numeric format ($count digits)';
  }

  @override
  String formatAlphanumericChars(int count) {
    return 'Alphanumeric format ($count characters)';
  }

  @override
  String get selectedLocationLabel => 'Selected location:';

  @override
  String get exitButton => 'Exit';

  @override
  String get invalidCoordinatesFormat =>
      'Invalid coordinates format. Use: \"latitude, longitude\"';

  @override
  String get viewDriver => 'View Driver';

  @override
  String get optimizeRoutesTitle => 'Optimize Routes';

  @override
  String get optimizeButton => 'Optimize';

  @override
  String get pharmacyDetailsTitle => 'Pharmacy Details';

  @override
  String get cameraPermissionTitle => 'Camera Permission';

  @override
  String get settingsButton => 'Settings';

  @override
  String get codeScanned => 'Code Scanned';

  @override
  String get scanAnother => 'Scan Another';

  @override
  String get allowCameraAccess => 'Allow Camera Access';

  @override
  String changeOrderTitle(String id) {
    return 'Change order - Order #$id';
  }

  @override
  String get patientLabel => 'Patient:';

  @override
  String get reloadRoute => 'Reload route';

  @override
  String viewDeliveriesCount(int count) {
    return 'View deliveries ($count)';
  }

  @override
  String get revoke => 'Revoke';

  @override
  String get myLocation => 'My Location';

  @override
  String deliveryMarkerTitle(String order, String name) {
    return '$order) Delivery - $name';
  }

  @override
  String get pickedUpCount => 'Picked up';

  @override
  String get pickUpCount => 'Pick up';

  @override
  String get optimizeRoutesConfirmation =>
      'Are you sure you want to optimize all routes? This process may take several minutes.';

  @override
  String get cameraPermissionContent =>
      'The app needs camera access to scan barcodes.';

  @override
  String get cameraPermissionRequired => 'Camera Permission Required';

  @override
  String get cameraPermissionBody =>
      'To scan barcodes, we need access to your camera.';

  @override
  String scanTitleWithMode(String mode) {
    return 'Scan - $mode';
  }

  @override
  String get modeLabel => 'Mode:';

  @override
  String get orderNumberLabel => 'Order:';

  @override
  String get successDeliveryVerified => 'Delivery code verified successfully';

  @override
  String get successPickupVerified => 'Pickup code verified successfully';

  @override
  String get successVerified => 'Code verified successfully';

  @override
  String get successScanned => 'Code scanned successfully';

  @override
  String get flashTooltip => 'Flash';

  @override
  String get switchCameraTooltip => 'Switch Camera';

  @override
  String get currentLocationLabel => 'Current location';

  @override
  String pickupMarkerTitle(String order, String name) {
    return '$order) Pickup - $name';
  }

  @override
  String pickupMarkerTitleWithCount(int count) {
    return 'Pickup ($count pending)';
  }

  @override
  String get pickupPointLabel => 'Pickup point';

  @override
  String get pendingLabel => 'Pending:';

  @override
  String get pickedUpLabel => 'Picked up:';

  @override
  String get addressLabel => 'Address:';

  @override
  String get noPickupLocationAvailable => 'No pickup location available';

  @override
  String get noDeliveryLocationAvailable => 'No delivery location available';

  @override
  String get noValidLocationToNavigate => 'No valid location to navigate';

  @override
  String get orderProcessed => 'This order has already been processed';

  @override
  String get errorLoadingMap => 'Error loading map';

  @override
  String get networkConfigTitle => 'Network Configuration';

  @override
  String get logInfoButton => 'Log Info';

  @override
  String get routeMapTitle => 'Route Map:';

  @override
  String get startPoint => 'Start Point';

  @override
  String get routeStart => 'Route start';

  @override
  String get endPoint => 'End Point';

  @override
  String get routeEnd => 'Route end';

  @override
  String get patient => 'Patient';

  @override
  String get orderNumberPrefix => 'Order #';

  @override
  String get centerMap => 'Center map';

  @override
  String get legend => 'Legend:';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get orders => 'Orders';

  @override
  String get appTitle => 'MedRush - Medicine Delivery';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusPickedUp => 'Picked up';

  @override
  String get statusInRoute => 'In Route';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get orderTypeMedicines => 'Medicines';

  @override
  String get orderTypeControlledMedicines => 'Controlled Medicines';

  @override
  String get driverStatusAvailable => 'Available';

  @override
  String get driverStatusInRoute => 'In Route';

  @override
  String get driverStatusDisconnected => 'Disconnected';

  @override
  String get pharmacyStatusActive => 'Active';

  @override
  String get pharmacyStatusInactive => 'Inactive';

  @override
  String get pharmacyStatusSuspended => 'Suspended';

  @override
  String get pharmacyStatusUnderReview => 'Under Review';

  @override
  String get failureReasonClientNotFound => 'Client not found';

  @override
  String get failureReasonWrongAddress => 'Wrong address';

  @override
  String get failureReasonNoCalls => 'No calls received';

  @override
  String get failureReasonDeliveryRejected => 'Delivery rejected';

  @override
  String get failureReasonAccessDenied => 'Access denied';

  @override
  String get failureReasonOther => 'Other reason';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get ago => 'ago';

  @override
  String get inTime => 'in';

  @override
  String get minute => 'min';

  @override
  String get minutes => 'minutes';

  @override
  String get hour => 'hour';

  @override
  String get hours => 'hours';

  @override
  String get day => 'day';

  @override
  String get days => 'days';

  @override
  String get month => 'month';

  @override
  String get months => 'months';

  @override
  String get year => 'year';

  @override
  String get years => 'years';

  @override
  String get dateTypeDelivery => 'Delivery';

  @override
  String get dateTypePickup => 'Pickup';

  @override
  String get dateTypeAssignment => 'Assignment';

  @override
  String get noDate => 'No date';

  @override
  String get recentlyAssigned => 'Recently assigned';

  @override
  String get recentlyPickedUp => 'Recently picked up';

  @override
  String get inRoute => 'In route';

  @override
  String get recentlyDelivered => 'Recently delivered';

  @override
  String get deliveryFailed => 'Delivery failed';

  @override
  String get invalidTime => 'Invalid time';

  @override
  String get addressNotSpecified => 'Address not specified';

  @override
  String get cityNotSpecified => 'City not specified';

  @override
  String get inProgress => 'In Progress';

  @override
  String get notificationOrderStatusUpdated => 'Order Status Updated';

  @override
  String notificationOrderAssigned(Object code) {
    return 'Order $code has been assigned to a delivery driver';
  }

  @override
  String notificationOrderPickedUp(Object code) {
    return 'Order $code has been picked up by the delivery driver';
  }

  @override
  String notificationOrderInRoute(Object code) {
    return 'Order $code is on route to its destination';
  }

  @override
  String notificationOrderDelivered(Object code) {
    return 'Order $code has been delivered successfully';
  }

  @override
  String notificationOrderFailed(Object code) {
    return 'Delivery of order $code has failed';
  }

  @override
  String notificationOrderCancelled(Object code) {
    return 'Order $code has been cancelled';
  }

  @override
  String notificationOrderStatusChanged(
      Object code, Object newStatus, Object oldStatus) {
    return 'Order $code status changed from $oldStatus to $newStatus';
  }

  @override
  String get notificationDriverStatusUpdated => 'Driver Status Updated';

  @override
  String notificationDriverStatusChanged(
      Object name, Object newStatus, Object oldStatus) {
    return 'Driver $name changed status from $oldStatus to $newStatus';
  }

  @override
  String get notificationPharmacyStatusUpdated => 'Pharmacy Status Updated';

  @override
  String notificationPharmacyStatusChanged(
      Object name, Object newStatus, Object oldStatus) {
    return 'Pharmacy $name changed status from $oldStatus to $newStatus';
  }

  @override
  String get userTypeAdministrator => 'Administrator';

  @override
  String get userTypeDriver => 'Driver';

  @override
  String get noData => 'No data';

  @override
  String get noPages => 'No pages';

  @override
  String get eventTypeCreated => 'Created';

  @override
  String get eventTypeAssigned => 'Assigned';

  @override
  String get eventTypePickedUp => 'Picked Up';

  @override
  String get eventTypeInRoute => 'In Route';

  @override
  String get eventTypeDelivered => 'Delivered';

  @override
  String get eventTypeFailed => 'Delivery Failed';

  @override
  String get eventTypeCancelled => 'Cancelled';

  @override
  String get eventTypeRescheduled => 'Rescheduled';

  @override
  String get eventTypeOrderCreated => 'Order Created';

  @override
  String get eventTypeOrderAssigned => 'Order Assigned';

  @override
  String get eventTypeRouteOptimized => 'Route Optimized';

  @override
  String get eventTypeLocationUpdated => 'Location Updated';

  @override
  String get eventTypeDriverConnected => 'Driver Connected';

  @override
  String get eventTypeDriverDisconnected => 'Driver Disconnected';

  @override
  String get eventTypePharmacyConnected => 'Pharmacy Connected';

  @override
  String get eventTypePharmacyDisconnected => 'Pharmacy Disconnected';

  @override
  String get eventTypeNotificationSent => 'Notification Sent';

  @override
  String get signatureTypeFirstTime => 'First Time';

  @override
  String get signatureTypeReception => 'Reception';

  @override
  String get signatureTypeControlledMedicine => 'Controlled Medicine';

  @override
  String get signatureTypeAuthorization => 'Authorization';

  @override
  String get signatureDescriptionFirstTime =>
      'Initial patient signature to authorize the service';

  @override
  String get signatureDescriptionReception =>
      'Signature confirming receipt of the order';

  @override
  String get signatureDescriptionControlledMedicine =>
      'Special signature required for controlled medicines';

  @override
  String get signatureDescriptionAuthorization =>
      'Authorization signature for the delivery service';

  @override
  String get defaultCity => 'City';
}
