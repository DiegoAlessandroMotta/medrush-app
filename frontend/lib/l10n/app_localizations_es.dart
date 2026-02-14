// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get loginSubtitle => 'Ingresa tus credenciales para acceder';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get emailHint => 'ejemplo@medrush.com';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => 'Ingresa tu contraseña';

  @override
  String get capsLockActive => 'Bloq Mayús está activo';

  @override
  String get loggingIn => 'Iniciando sesión...';

  @override
  String get sessionExpiredWarning =>
      'Tu sesión ha expirado. Por favor, inicia sesión de nuevo.';

  @override
  String get downloadApkTooltip => 'Descargar APP Android (APK)';

  @override
  String get checkingConnection => 'Verificando conexión al servidor...';

  @override
  String get serverConnectionError => 'No se pudo conectar con el servidor';

  @override
  String get deliveriesTab => 'Entregas';

  @override
  String get historyTab => 'Historial';

  @override
  String get routeTab => 'Ruta';

  @override
  String get profileTab => 'Perfil';

  @override
  String get searchOrders => 'Buscar pedidos...';

  @override
  String get filter => 'Filtrar';

  @override
  String get call => 'Llamar';

  @override
  String get navigate => 'Navegar';

  @override
  String get deliver => 'Entregar';

  @override
  String get viewDetails => 'Ver Detalles';

  @override
  String get noActiveOrders => 'No tienes pedidos activos';

  @override
  String get activeOrdersDescription =>
      'Los pedidos asignados, recogidos y en ruta aparecerán aquí';

  @override
  String get cannotOpenNavigation => 'No se puede abrir navegación';

  @override
  String get clientPhoneNotAvailable => 'Teléfono del cliente no disponible';

  @override
  String get cannotMakeCall => 'No se puede realizar la llamada';

  @override
  String get infoCopied => 'Información copiada al portapapeles';

  @override
  String get errorCopyingInfo => 'Error al copiar información';

  @override
  String get errorLoadingOrders => 'Error al cargar pedidos';

  @override
  String get processingDelivery => 'Procesando entrega...';

  @override
  String get deliveryDetails => 'Detalles de la Entrega';

  @override
  String get orderIdLabel => 'ID de Pedido: ';

  @override
  String get clientLabel => 'Cliente: ';

  @override
  String productsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return '$_temp0';
  }

  @override
  String get products => 'Productos';

  @override
  String get proofOfDelivery => 'Prueba de Entrega';

  @override
  String get changePhoto => 'Cambiar Foto';

  @override
  String get delete => 'Eliminar';

  @override
  String get noPhotoTaken => 'Aún no se ha tomado una foto';

  @override
  String get takePhotoInstruction =>
      'Por favor, tome una foto del paquete entregado.';

  @override
  String get takePhoto => 'Tomar Foto';

  @override
  String get cancel => 'Cancelar';

  @override
  String get signAndDeliver => 'Firmar y Entregar';

  @override
  String errorTakingPhoto(Object error) {
    return 'Error al tomar foto: $error';
  }

  @override
  String get confirmDelivery => 'Confirmar Entrega';

  @override
  String get confirmDeliveryQuestion =>
      '¿Estás seguro de que deseas confirmar la entrega de este pedido?';

  @override
  String get confirm => 'Confirmar';

  @override
  String get deliverySuccess => 'Pedido entregado exitosamente';

  @override
  String deliveryError(Object error) {
    return 'Error al entregar pedido: $error';
  }

  @override
  String get editDeliverySignature => 'Editar Firma de Entrega';

  @override
  String get deliverySignature => 'Firma de Entrega';

  @override
  String get sampleSignature => 'Firma de Muestra';

  @override
  String get mustSignBeforeSaving => 'Debes firmar antes de guardar';

  @override
  String signatureSuccess(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'delivery': 'Firma de entrega generada exitosamente',
        'sample': 'Firma de muestra generada exitosamente',
        'other': 'Firma generada exitosamente',
      },
    );
    return '$_temp0';
  }

  @override
  String get errorSavingSignature => 'Error al guardar la firma';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get personalInfo => 'Información Personal';

  @override
  String get professionalInfo => 'Información Profesional';

  @override
  String get systemStatus => 'Estado del Sistema';

  @override
  String get security => 'Seguridad';

  @override
  String get session => 'Sesión';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get logoutConfirmation => '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get changeProfilePhoto => 'Cambiar foto de perfil';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get deletePhoto => 'Eliminar foto';

  @override
  String get photoUpdateSuccess => 'Foto de perfil actualizada';

  @override
  String get photoUpdateError => 'Error al actualizar la foto';

  @override
  String get photoSelectError => 'Error al seleccionar la foto';

  @override
  String get changePassword => 'Cambiar Contraseña';

  @override
  String get changePasswordInstruction =>
      'Ingresa tu contraseña actual y la nueva contraseña:';

  @override
  String get currentPassword => 'Contraseña Actual';

  @override
  String get newPassword => 'Nueva Contraseña';

  @override
  String get confirmNewPassword => 'Confirmar Nueva Contraseña';

  @override
  String get minCharacters => 'Mínimo 8 caracteres';

  @override
  String get enterCurrentPassword => 'Ingresa tu contraseña actual';

  @override
  String get enterNewPassword => 'Ingresa la nueva contraseña';

  @override
  String get passwordMinLength =>
      'La nueva contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get passwordMustBeDifferent =>
      'La nueva contraseña debe ser diferente a la actual';

  @override
  String get passwordUpdateSuccess => 'Contraseña actualizada exitosamente';

  @override
  String get loadingProfile => 'Cargando perfil...';

  @override
  String get retry => 'Reintentar';

  @override
  String get name => 'Nombre';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Teléfono';

  @override
  String get driverLicense => 'Licencia de Conducir';

  @override
  String get vehicle => 'Vehículo';

  @override
  String get driverStatus => 'Estado del Repartidor';

  @override
  String get activeUser => 'Usuario Activo';

  @override
  String get notSpecified => 'No especificado';

  @override
  String get notAssigned => 'No asignado';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get adminPanel => 'Panel de Admin';

  @override
  String get pharmaciesTab => 'Farmacias';

  @override
  String get driversTab => 'Repartidores';

  @override
  String get routesTab => 'Rutas';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get configuration => 'Configuración';

  @override
  String get registerDriverTitle => 'Registro de Repartidor';

  @override
  String get accountCreatedSuccess =>
      'Cuenta creada exitosamente. Ahora inicia sesión.';

  @override
  String errorRegistering(Object error) {
    return 'Error al registrar: $error';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get noUserAuthenticated => 'No hay usuario autenticado';

  @override
  String get retryConnection => 'Reintentar conexión';

  @override
  String get verifyConnectionAgain => 'Verificar conexión nuevamente';

  @override
  String connectedToServer(Object url) {
    return 'Conectado al servidor: $url';
  }

  @override
  String get obtainingDownloadLink => 'Obteniendo enlace de descarga...';

  @override
  String get couldNotGetDownloadLink =>
      'No se pudo obtener el enlace de descarga';

  @override
  String get downloadStarted => 'Descarga iniciada correctamente';

  @override
  String get couldNotOpenDownloadLink =>
      'No se pudo abrir el enlace de descarga';

  @override
  String errorDownloadingApk(Object error) {
    return 'Error al descargar APK: $error';
  }

  @override
  String connectionError(Object error) {
    return 'Error de conexión: $error';
  }

  @override
  String errorLoadingOrdersWithError(Object error) {
    return 'Error al cargar los pedidos: $error';
  }

  @override
  String get errorLoadingProfile => 'Error al cargar perfil';

  @override
  String get callClient => 'Llamar al Cliente';

  @override
  String get navigateToPickup => 'Navegar a recogida';

  @override
  String get navigateToDelivery => 'Navegar a entrega';

  @override
  String get deliverWithoutSignature => 'Entregar sin firma';

  @override
  String get allOrdersLoaded => 'Todos los pedidos cargados';

  @override
  String loadingPage(Object current, Object total) {
    return 'Cargando página $current de $total...';
  }

  @override
  String get errorDeletingPhoto => 'Error al eliminar la foto';

  @override
  String errorLoadingHistoryWithError(Object error) {
    return 'Error al cargar el historial: $error';
  }

  @override
  String get orderIdShort => 'Pedido #';

  @override
  String get basicInfo => 'Información Básica';

  @override
  String get medications => 'Medicamentos';

  @override
  String get deliveryAddress => 'Dirección de Entrega';

  @override
  String get address => 'Dirección';

  @override
  String get addressLine2 => 'Dirección Línea 2';

  @override
  String get city => 'Ciudad';

  @override
  String get region => 'Estado/Región';

  @override
  String get postalCode => 'Código Postal';

  @override
  String get detail => 'Detalle';

  @override
  String get accessCode => 'Código de Acceso';

  @override
  String get buildingCode => 'Código de Edificio';

  @override
  String get country => 'País';

  @override
  String get type => 'Tipo';

  @override
  String get status => 'Estado';

  @override
  String get priority => 'Prioridad';

  @override
  String get requiresSpecialSignature => 'Requiere firma especial';

  @override
  String get assignmentDate => 'Fecha de Asignación';

  @override
  String get pickupLocation => 'Ubicación de Recogida';

  @override
  String get coordinates => 'Coordenadas';

  @override
  String get detailedLocation => 'Ubicación Detallada';

  @override
  String get pharmacy => 'Farmacia';

  @override
  String get pharmacyLocation => 'Ubicación de la farmacia';

  @override
  String get driver => 'Repartidor';

  @override
  String get datesAndProgress => 'Fechas y Progreso';

  @override
  String get pickupDate => 'Fecha de Recogida';

  @override
  String get deliveryDate => 'Fecha de Entrega';

  @override
  String get created => 'Creado';

  @override
  String get lastUpdate => 'Última Actualización';

  @override
  String get estimatedTime => 'Tiempo Estimado';

  @override
  String get estimatedDistance => 'Distancia Estimada';

  @override
  String get observations => 'Observaciones';

  @override
  String get deliveryProof => 'Comprobantes de Entrega';

  @override
  String get deliveryPhoto => 'Foto de Entrega';

  @override
  String get clientSignature => 'Firma del Cliente';

  @override
  String get consentDocument => 'Documento de Consentimiento';

  @override
  String get failureInfo => 'Información de Fallo';

  @override
  String get reason => 'Motivo';

  @override
  String get notFound => 'No encontrada';

  @override
  String get barcodeTooltip => 'Código de barras';

  @override
  String get couldNotOpenDocument => 'No se pudo abrir el documento';

  @override
  String get barcodeTitle => 'Código de Barras';

  @override
  String get orderNumber => 'N° PEDIDO';

  @override
  String get client => 'CLIENTE';

  @override
  String get location => 'UBICACIÓN';

  @override
  String get date => 'FECHA';

  @override
  String get actions => 'ACCIONES';

  @override
  String get noOrdersToShow => 'No hay pedidos para mostrar';

  @override
  String get assignDriver => 'Asignar Repartidor';

  @override
  String get edit => 'Editar';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get cancelOrder => 'Cancelar Pedido';

  @override
  String get markAsFailed => 'Marcar como Fallido';

  @override
  String get generateBarcode => 'Generar Código de Barras';

  @override
  String get notAvailable => 'No disponible';

  @override
  String get assigned => 'Asignado';

  @override
  String get confirmDeliveryTitle => 'Confirmar entrega';

  @override
  String get captureSignature => 'Capturar firma';

  @override
  String get phoneCopied => 'Teléfono copiado al portapapeles';

  @override
  String get emailCopied => 'Email copiado al portapapeles';

  @override
  String get clientHasNoEmail => 'El cliente no tiene email registrado';

  @override
  String get couldNotOpenMaps => 'No se puede abrir Google Maps';

  @override
  String get deliveryStatus => 'Estado de la Entrega';

  @override
  String get scheduledDeliveries => 'Entregas programadas';

  @override
  String get navigateToPickupPoint => 'Navegar a punto de recogida';

  @override
  String get navigateToDeliveryPoint => 'Navegar a punto de entrega';

  @override
  String get statusLabel => 'Estado: ';

  @override
  String get details => 'Detalles';

  @override
  String get confirmDeliveryWithSignature =>
      '¿Deseas capturar la firma del cliente antes de marcar como entregado?';

  @override
  String errorUpdatingState(Object error) {
    return 'Error al actualizar estado: $error';
  }

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get adminProfile => 'Perfil del Administrador';

  @override
  String get updateProfile => 'Actualizar Perfil';

  @override
  String get passwordUpdateAvailable =>
      'Actualización de contraseña disponible tras la integración con backend.';

  @override
  String get couldNotLoadUserInfo =>
      'No se pudo cargar la información del usuario';

  @override
  String get updateProfileButton => 'Actualizar Perfil';

  @override
  String get save => 'Guardar';

  @override
  String get required => 'Requerido';

  @override
  String get assignOrder => 'Asignar Pedido';

  @override
  String get assign => 'Asignar';

  @override
  String get assignOrderConfirm =>
      '¿Asignar este pedido a tu lista de entregas?';

  @override
  String get couldNotGetDriverInfo =>
      'No se pudo obtener la información del repartidor';

  @override
  String get noOrderWithBarcode =>
      'No se encontró ningún pedido con este código de barras';

  @override
  String get errorProcessingBarcode => 'Error al procesar el código de barras';

  @override
  String get processingBarcode => 'Procesando código de barras...';

  @override
  String get assignedTo => 'Asignado a: ';

  @override
  String get loadingRoutes => 'Cargando rutas...';

  @override
  String get allRoutes => 'Todas las rutas';

  @override
  String get activeRoutes => 'Rutas activas';

  @override
  String get completedRoutes => 'Rutas completadas';

  @override
  String get allDrivers => 'Todos los repartidores';

  @override
  String get unknownDriver => 'Repartidor Desconocido';

  @override
  String get errorLoadingRoutes => 'Error al cargar rutas';

  @override
  String get searchPharmacies => 'Buscar farmacias...';

  @override
  String get allStatuses => 'Todos los estados';

  @override
  String get active => 'Activa';

  @override
  String get inactive => 'Inactiva';

  @override
  String get suspended => 'Suspendida';

  @override
  String get inReview => 'En Revisión';

  @override
  String get view => 'Ver';

  @override
  String get pharmacySavedSuccess => 'Farmacia creada exitosamente';

  @override
  String get pharmacyUpdatedSuccess => 'Farmacia actualizada exitosamente';

  @override
  String get errorReloadPharmacies => 'Error al recargar farmacias';

  @override
  String get pharmacySavedButErrorReload =>
      'Farmacia guardada pero error al actualizar lista';

  @override
  String pharmacyDeletedSuccess(Object name) {
    return 'Farmacia \"$name\" eliminada exitosamente';
  }

  @override
  String errorDeletePharmacy(Object error) {
    return 'Error al eliminar farmacia: $error';
  }

  @override
  String get noPharmaciesFound => 'No se encontraron farmacias';

  @override
  String get errorLoadingPharmacies => 'Error al cargar farmacias';

  @override
  String get errorLoadingPharmaciesUnknown =>
      'Error desconocido al cargar farmacias';

  @override
  String get errorLoadingOrdersUnknown => 'Error desconocido al cargar pedidos';

  @override
  String get printShippingLabelsTooltip => 'Imprimir Etiquetas de Envío';

  @override
  String get uploadCsvTooltip => 'Cargar CSV';

  @override
  String get addOrderTooltip => 'Agregar Pedido';

  @override
  String get searchOrdersByClientCodePhone =>
      'Buscar por cliente, código, teléfono...';

  @override
  String get selectAll => 'Seleccionar Todo';

  @override
  String get clearFilters => 'Limpiar Filtros';

  @override
  String statesCount(Object count) {
    return '$count estados';
  }

  @override
  String get noDeliveriesFound => 'No se encontraron entregas';

  @override
  String get noOrdersMatchFilters =>
      'No hay pedidos que coincidan con los filtros aplicados';

  @override
  String showingXOfYOrders(Object showing, Object total) {
    return 'Mostrando $showing de $total pedidos';
  }

  @override
  String pageXOfY(Object current, Object total) {
    return 'Página $current de $total';
  }

  @override
  String get orderBarcodeCaption => 'Código de barras del pedido';

  @override
  String get confirmDeletion => 'Confirmar eliminación';

  @override
  String confirmDeleteOrderQuestion(Object id) {
    return '¿Estás seguro de que deseas eliminar el pedido #$id?';
  }

  @override
  String get deleteOrderIrreversible =>
      'Esta acción no se puede deshacer. El pedido será eliminado permanentemente.';

  @override
  String orderDeletedSuccess(Object id) {
    return 'Pedido #$id eliminado exitosamente';
  }

  @override
  String errorDeleteOrder(Object error) {
    return 'Error al eliminar pedido: $error';
  }

  @override
  String errorLoadingDrivers(String detail) {
    return 'Error al cargar repartidores: $detail';
  }

  @override
  String selectDriverForOrder(Object name) {
    return 'Selecciona un repartidor para el pedido de $name';
  }

  @override
  String get noDriversAvailable => 'No hay repartidores disponibles';

  @override
  String get codeLabel => 'Código: ';

  @override
  String get errorUnknown => 'Error desconocido';

  @override
  String confirmCancelOrderQuestion(Object id) {
    return '¿Estás seguro de que deseas cancelar el pedido #$id?';
  }

  @override
  String get errorLoadingDriversUnknown =>
      'No se pudo cargar la lista de repartidores';

  @override
  String get driverCreatedSuccess => 'Repartidor creado exitosamente';

  @override
  String get driverUpdatedSuccess => 'Repartidor actualizado exitosamente';

  @override
  String driverDeletedSuccess(Object name) {
    return 'Repartidor \"$name\" eliminado exitosamente';
  }

  @override
  String errorDeleteDriver(Object error) {
    return 'Error al eliminar repartidor: $error';
  }

  @override
  String get searchDrivers => 'Buscar repartidores...';

  @override
  String get noDriversMatchFilters =>
      'No se encontraron repartidores con los filtros aplicados';

  @override
  String get noDriversRegistered => 'No hay repartidores registrados';

  @override
  String get addDriver => 'Agregar Repartidor';

  @override
  String deactivatedDriversCount(Object count) {
    return 'Repartidores desactivados ($count)';
  }

  @override
  String get driverLabel => 'Repartidor';

  @override
  String get idLabel => 'ID: ';

  @override
  String get driverPhoneNotAvailable => 'Teléfono del repartidor no disponible';

  @override
  String get errorMakingCall => 'Error al realizar la llamada';

  @override
  String get lastActivityNoActivity => 'sin actividad';

  @override
  String get lastActivityJustNow => 'justo ahora';

  @override
  String lastActivityMinutesAgo(Object count) {
    return 'hace $count min';
  }

  @override
  String lastActivityHoursAgo(Object count) {
    return 'hace $count h';
  }

  @override
  String lastActivityDaysAgo(Object count) {
    return 'hace $count d';
  }

  @override
  String get enterValidName => 'Ingresa un nombre válido.';

  @override
  String get nameMinLength3 => 'El nombre debe tener al menos 3 caracteres.';

  @override
  String get enterEmailAddress => 'Ingresa una dirección de correo.';

  @override
  String get invalidEmail => 'Correo inválido.';

  @override
  String get enterValidPhone => 'Ingresa un teléfono válido.';

  @override
  String get repeatNewPassword => 'Repite la nueva contraseña';

  @override
  String get confirmPasswordRequired => 'Confirma la nueva contraseña.';

  @override
  String get newPasswordMin12 => 'Usa al menos 12 caracteres.';

  @override
  String get passwordMustIncludeComplexity =>
      'Debe incluir mayúsculas, minúsculas y números.';

  @override
  String get updatePassword => 'Actualizar contraseña';

  @override
  String get tableHeaderPhoto => 'FOTO';

  @override
  String get tableHeaderName => 'NOMBRE';

  @override
  String get tableHeaderEmail => 'EMAIL';

  @override
  String get tableHeaderPhone => 'TELÉFONO';

  @override
  String get tableHeaderVehicle => 'VEHÍCULO';

  @override
  String get tableHeaderLastActivity => 'ÚLTIMA ACTIVIDAD';

  @override
  String get noDriversToShow => 'No hay repartidores para mostrar';

  @override
  String get viewDetailsTooltip => 'Ver detalles';

  @override
  String get copyEmail => 'Copiar Email';

  @override
  String confirmDeleteDriverQuestion(Object name) {
    return '¿Estás seguro de que deseas eliminar al repartidor \"$name\"?';
  }

  @override
  String get deleteDriverIrreversible =>
      'Esta acción no se puede deshacer. El repartidor será eliminado permanentemente.';

  @override
  String get cannotOpenCallApp => 'No se pudo abrir la aplicación de llamadas';

  @override
  String errorMakingCallWithError(Object error) {
    return 'Error al realizar la llamada: $error';
  }

  @override
  String get noEmailAvailable => 'No hay email disponible';

  @override
  String errorCopyingEmail(Object error) {
    return 'Error al copiar el email: $error';
  }

  @override
  String get changePasswordTitle => 'Cambiar contraseña';

  @override
  String get requiredField => 'Requerido';

  @override
  String get min6Characters => 'Mínimo 6 caracteres';

  @override
  String get passwordsDoNotMatchShort => 'No coinciden';

  @override
  String get passwordUpdated => 'Contraseña actualizada';

  @override
  String get couldNotUpdatePassword => 'No se pudo actualizar la contraseña';

  @override
  String errorSavingDriver(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get errorSavingDriverUnknown =>
      'Error desconocido al guardar repartidor';

  @override
  String get selectExpiryDate => 'Seleccionar fecha de vencimiento';

  @override
  String errorSelectingDate(Object error) {
    return 'Error al seleccionar fecha: $error';
  }

  @override
  String get phoneNumberLabel => 'Número de Teléfono';

  @override
  String get phoneMustBe10Digits =>
      'El teléfono debe tener exactamente 10 dígitos';

  @override
  String get editDriver => 'Editar Repartidor';

  @override
  String get newDriver => 'Nuevo Repartidor';

  @override
  String get modifyingDriver => 'Modificando repartidor';

  @override
  String get creatingDriver => 'Creando nuevo repartidor';

  @override
  String get sectionPersonalInfo => 'Información Personal';

  @override
  String get sectionLicenseInfo => 'Información de Licencia';

  @override
  String get sectionVehicleInfo => 'Información del Vehículo';

  @override
  String get sectionDocuments => 'Documentos y Fotos';

  @override
  String get sectionSettings => 'Configuración';

  @override
  String get fullNameRequired => 'Nombre Completo *';

  @override
  String get nameRequired => 'El nombre es requerido';

  @override
  String get emailRequired => 'El email es requerido';

  @override
  String get countryDefaultUSA => 'Se enviará como USA por defecto';

  @override
  String get passwordRequired => 'La contraseña es requerida';

  @override
  String get passwordMin6Chars =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get idDriverLicenseLabel => 'ID (Driver\'s License o State ID)';

  @override
  String get idHelper => 'Letras y números; sin espacios ni guiones';

  @override
  String get idMin5Chars => 'El ID debe tener al menos 5 caracteres';

  @override
  String get alphanumericOnly => 'Solo letras y números';

  @override
  String get licenseNumberLabel => 'Número de Licencia';

  @override
  String get licenseFormatHelper => 'Formato: Letras y números';

  @override
  String get licenseMin5Chars =>
      'El número de licencia debe tener al menos 5 caracteres';

  @override
  String get uppercaseAndNumbersOnly => 'Solo letras mayúsculas y números';

  @override
  String get licenseExpiryLabel => 'Vencimiento de Licencia';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get vehiclePlateLabel => 'Placa del Vehículo';

  @override
  String get vehiclePlateFormat => 'Formato: ABC-123 o ABC123';

  @override
  String get plateMin4Chars => 'La placa debe tener al menos 4 caracteres';

  @override
  String get uppercaseNumbersDashes =>
      'Solo letras mayúsculas, números y guiones';

  @override
  String get vehicleBrandLabel => 'Marca del Vehículo';

  @override
  String get vehicleBrandHelper => 'Ej: Toyota, Honda, Ford';

  @override
  String get brandMin2Chars => 'La marca debe tener al menos 2 caracteres';

  @override
  String get lettersAndSpacesOnly => 'Solo letras y espacios';

  @override
  String get vehicleModelLabel => 'Modelo del Vehículo';

  @override
  String get vehicleModelHelper => 'Ej: Corolla, Civic, Focus';

  @override
  String get modelMin2Chars => 'El modelo debe tener al menos 2 caracteres';

  @override
  String get alphanumericSpacesDashes =>
      'Solo letras, números, espacios y guiones';

  @override
  String get vehicleRegistrationLabel => 'Código de Registro del Vehículo';

  @override
  String get vehicleRegistrationHelper => 'Alfanumérico; ej: ABC123456';

  @override
  String get min5Characters => 'Debe tener al menos 5 caracteres';

  @override
  String get photoIdTitle => 'Foto de ID';

  @override
  String get photoIdSubtitle => 'Documento de identidad';

  @override
  String get photoLicenseTitle => 'Foto de Licencia de Conducir';

  @override
  String get photoLicenseSubtitle => 'Licencia de conducir vigente';

  @override
  String get photoInsuranceTitle => 'Foto de Seguro del Vehículo';

  @override
  String get photoInsuranceSubtitle => 'Póliza vigente';

  @override
  String get stateRequired => 'Estado *';

  @override
  String get userTypeLabel => 'Tipo de Usuario';

  @override
  String get verifiedLabel => 'Verificado';

  @override
  String get documentsSection => 'Documentos';

  @override
  String get loadingPharmacyInfo => 'Cargando información de la farmacia...';

  @override
  String get notAssignedToAnyPharmacy => 'No asignado a ninguna farmacia';

  @override
  String get profilePhotoTitle => 'Foto de perfil';

  @override
  String get documentTitle => 'Documento';

  @override
  String get adminRole => 'Administrador';

  @override
  String get driverRole => 'Repartidor';

  @override
  String get pharmacyAssignmentSection => 'Asignación de Farmacia';

  @override
  String get systemInfoSection => 'Información del Sistema';

  @override
  String get registrationDateLabel => 'Fecha de Registro';

  @override
  String get lastActivityLabel => 'Última Actividad';

  @override
  String get expiryLabel => 'Vencimiento';

  @override
  String get photoIdLabel => 'Foto ID';

  @override
  String get photoLicenseLabel => 'Foto Licencia';

  @override
  String get digitalSignatureLabel => 'Firma Digital';

  @override
  String get pharmacyDetailTitle => 'Detalle de Farmacia';

  @override
  String get generalInfoTitle => 'Información General';

  @override
  String get locationTitle => 'Ubicación';

  @override
  String get contactTitle => 'Contacto';

  @override
  String get additionalInfoTitle => 'Información Adicional';

  @override
  String get responsibleLabel => 'Responsable';

  @override
  String get responsiblePhoneLabel => 'Teléfono Responsable';

  @override
  String get latitudeLabel => 'Latitud';

  @override
  String get longitudeLabel => 'Longitud';

  @override
  String get scheduleLabel => 'Horario';

  @override
  String get delivery24hLabel => 'Delivery 24h';

  @override
  String get registrationDateShort => 'Fecha Registro';

  @override
  String pharmacyLocationTitle(Object name) {
    return 'Ubicación de $name';
  }

  @override
  String get idShort => 'ID';

  @override
  String get razonSocialLabel => 'Razón Social';

  @override
  String get rucLabel => 'EIN';

  @override
  String get cadenaLabel => 'Cadena';

  @override
  String get stateRegionLabel => 'Estado';

  @override
  String get zipCodeLabel => 'ZIP';

  @override
  String get lastUpdateLabel => 'Última Actualización';

  @override
  String get statusShort => 'Estado';

  @override
  String get selectPharmacyLocationTitle =>
      'Seleccionar Ubicación de la Farmacia';

  @override
  String get updatingPharmacy => 'Actualizando farmacia...';

  @override
  String get creatingPharmacy => 'Creando farmacia...';

  @override
  String get errorUpdatingPharmacy => 'Error al actualizar farmacia';

  @override
  String get errorCreatingPharmacy => 'Error al crear farmacia';

  @override
  String get errorDeletingPharmacy => 'Error al eliminar farmacia';

  @override
  String get pleaseEnterPharmacyName =>
      'Por favor ingrese el nombre de la farmacia';

  @override
  String get pleaseEnterResponsible => 'Por favor ingrese el responsable';

  @override
  String get pleaseEnterPhone => 'Por favor ingrese el teléfono';

  @override
  String get pleaseEnterValidEmail => 'Por favor ingrese un correo válido';

  @override
  String get pleaseEnterRuc => 'Por favor ingrese el RUC';

  @override
  String get pharmacyStatusTitle => 'Estado de la Farmacia';

  @override
  String get available => 'Disponible';

  @override
  String get pleaseEnterCity => 'Por favor ingrese la ciudad';

  @override
  String get editPharmacy => 'Editar Farmacia';

  @override
  String get newPharmacy => 'Nueva Farmacia';

  @override
  String get mapLocationTitle => 'Ubicación en el mapa';

  @override
  String get geocodingErrorMap => 'Error en geocodificación del mapa pequeño';

  @override
  String get pleaseEnterLatitude => 'Por favor ingrese la latitud';

  @override
  String get pleaseEnterValidLatitude => 'Por favor ingrese una latitud válida';

  @override
  String get pleaseEnterLongitude => 'Por favor ingrese la longitud';

  @override
  String get pleaseEnterValidLongitude =>
      'Por favor ingrese una longitud válida';

  @override
  String get updatePharmacy => 'Actualizar Farmacia';

  @override
  String get createPharmacy => 'Crear Farmacia';

  @override
  String confirmDeletePharmacyQuestion(Object name) {
    return '¿Estás seguro de que deseas eliminar la farmacia \"$name\"?\n\nEsta acción no se puede deshacer.';
  }

  @override
  String get pharmacyNameLabel => 'Nombre de la Farmacia *';

  @override
  String get chainOptionalLabel => 'Cadena (opcional)';

  @override
  String get responsibleRequiredLabel => 'Responsable *';

  @override
  String get responsiblePhoneOptionalLabel =>
      'Teléfono del Responsable (opcional)';

  @override
  String get phoneRequiredLabel => 'Teléfono *';

  @override
  String get emailOptionalLabel => 'Correo Electrónico (opcional)';

  @override
  String get rucRequiredLabel => 'RUC *';

  @override
  String get rucEinOptionalLabel => 'EIN (opcional)';

  @override
  String get cityRequiredLabel => 'Ciudad *';

  @override
  String get zipOptionalLabel => 'ZIP Code (opcional)';

  @override
  String get scheduleOptionalLabel => 'Horario de Atención (opcional)';

  @override
  String get delivery24hHoursLabel => 'Delivery 24 horas';

  @override
  String get addressLine1RequiredLabel => 'Dirección Línea 1 *';

  @override
  String get addressLine2OptionalLabel => 'Dirección Línea 2 (opcional)';

  @override
  String get pleaseEnterAddressLine1 =>
      'Por favor ingrese la dirección línea 1';

  @override
  String get addressLine1HelperText => 'Calle, avenida, jirón, etc.';

  @override
  String get addressLine2HelperText => 'Piso, departamento, referencia, etc.';

  @override
  String get deletePharmacyIrreversible =>
      'Esta acción no se puede deshacer. La farmacia será eliminada permanentemente.';

  @override
  String confirmDeletePharmacyQuestionShort(Object name) {
    return '¿Estás seguro de que deseas eliminar la farmacia \"$name\"?';
  }

  @override
  String get latitudeRequiredLabel => 'Latitud *';

  @override
  String get longitudeRequiredLabel => 'Longitud *';

  @override
  String get saving => 'Guardando...';

  @override
  String get barcodeLabel => 'Código de Barras';

  @override
  String get assignDriverTitle => 'Asignar Repartidor';

  @override
  String get noActiveDrivers => 'No hay repartidores activos';

  @override
  String get confirmAssignment => 'Confirmar Asignación';

  @override
  String get cancelOrderTitle => 'Cancelar Pedido';

  @override
  String get confirmCancellation => 'Confirmar Cancelación';

  @override
  String get markAsFailedTitle => 'Marcar como Fallido';

  @override
  String get failureReasonLabel => 'Motivo del fallo';

  @override
  String get observationsOptionalLabel => 'Observaciones (opcional)';

  @override
  String get failureDetailsHint => 'Detalles adicionales sobre el fallo...';

  @override
  String get confirmFailure => 'Confirmar Fallo';

  @override
  String get barcodeOrderDescription => 'Código de barras del pedido';

  @override
  String get errorDeletingOrder => 'Error al eliminar pedido';

  @override
  String orderCancelledSuccess(Object id) {
    return 'Pedido #$id cancelado exitosamente';
  }

  @override
  String get errorCancellingOrder => 'Error al cancelar pedido';

  @override
  String get cancelOrderIrreversible =>
      'Esta acción cambiará el estado del pedido a \"Cancelado\" y no se podrá revertir.';

  @override
  String selectFailureReasonForOrder(Object id) {
    return 'Selecciona el motivo del fallo para el pedido #$id';
  }

  @override
  String get markAsFailedIrreversible =>
      'Esta acción cambiará el estado del pedido a \"Fallido\" y registrará la ubicación actual.';

  @override
  String get phoneHint => '5551234567';

  @override
  String get stateOptionalLabel => 'Estado (opcional)';

  @override
  String get districtRequiredLabel => 'Distrito *';

  @override
  String get postalCodeOptionalLabel => 'Código Postal (opcional)';

  @override
  String get deliveryAddressLine1Label => 'Dirección de Entrega Línea 1 *';

  @override
  String get deliveryAddressLine2OptionalLabel =>
      'Dirección de Entrega Línea 2 (opcional)';

  @override
  String get add => 'Agregar';

  @override
  String get driverOptionalLabel => 'Repartidor (opcional)';

  @override
  String get loadingDrivers => 'Cargando repartidores...';

  @override
  String get unassigned => 'Sin asignar';

  @override
  String get pharmacyRequiredLabel => 'Farmacia *';

  @override
  String get loadingPharmacies => 'Cargando farmacias...';

  @override
  String get clientNameRequiredLabel => 'Nombre del Cliente *';

  @override
  String get buildingAccessCodeOptionalLabel =>
      'Código de Acceso al Edificio (opcional)';

  @override
  String get orderTypeRequiredLabel => 'Tipo de Pedido *';

  @override
  String get addMedicationTitle => 'Agregar Medicamento';

  @override
  String get medicationNameRequiredLabel => 'Nombre del Medicamento *';

  @override
  String get quantityRequiredLabel => 'Cantidad *';

  @override
  String get selectDriverTitle => 'Seleccionar Repartidor';

  @override
  String get searchDriverHint => 'Buscar por nombre, teléfono o email...';

  @override
  String get unassignDriverOption => 'No asignar repartidor a este pedido';

  @override
  String get select => 'Seleccionar';

  @override
  String get selectDeliveryLocationTitle => 'Seleccionar Ubicación de Entrega';

  @override
  String get noMedicationsAddedHint =>
      'No hay medicamentos agregados. Presiona \"Agregar\" para añadir medicamentos.';

  @override
  String get routeDetailsTitle => 'Detalles de la Ruta';

  @override
  String get noName => 'Sin nombre';

  @override
  String get completed => 'Completada';

  @override
  String get unknown => 'Desconocido';

  @override
  String get distanceLabel => 'Distancia';

  @override
  String get estimatedTimeLabel => 'Tiempo Estimado';

  @override
  String get additionalDetailsLabel => 'Detalles adicionales';

  @override
  String get startPointLabel => 'Punto de Inicio';

  @override
  String get endPointLabel => 'Punto Final';

  @override
  String get creationDateLabel => 'Fecha de Creación';

  @override
  String get routeOrdersTitle => 'Pedidos de la Ruta';

  @override
  String get refreshOrdersTooltip => 'Refrescar pedidos';

  @override
  String get clientNotSpecified => 'Cliente no especificado';

  @override
  String get oldOrdersCleanupTitle =>
      'Limpieza de Archivos de Pedidos Antiguos';

  @override
  String get oldOrdersCleanupDescription =>
      'Esta acción eliminará permanentemente solo los archivos multimedia (fotos de entrega y firmas digitales) de pedidos entregados hace más del tiempo seleccionado. Los datos del pedido se mantendrán intactos.';

  @override
  String get weeksBackLabel => 'Semanas hacia atrás';

  @override
  String get processing => 'Procesando...';

  @override
  String get saveConfiguration => 'Guardar Configuración';

  @override
  String get confirmCleanup => 'Confirmar Limpieza';

  @override
  String get confirmCleanupDescription =>
      'Esta acción eliminará permanentemente solo los archivos multimedia (fotos y firmas). Los datos del pedido se mantendrán intactos.';

  @override
  String get cleanupStartedSuccess =>
      'La limpieza de archivos multimedia de pedidos antiguos ha sido iniciada exitosamente';

  @override
  String get errorStartingCleanup => 'Error al iniciar la limpieza';

  @override
  String get googleApiUsageTitle => 'Uso de Google API';

  @override
  String get refreshMetricsTooltip => 'Actualizar métricas';

  @override
  String get apiCallsLast30Days => 'Llamadas API (Últimos 30 días)';

  @override
  String get errorLoadingMetrics => 'Error al cargar las métricas';

  @override
  String get requestsLabel => 'Solicitudes';

  @override
  String get servicesLabel => 'Servicios';

  @override
  String get costPerRequest => 'Costo por solicitud';

  @override
  String get totalCost => 'Costo total';

  @override
  String get noUsageDataAvailable => 'No hay datos de uso disponibles';

  @override
  String get metricsWillAppearWhenRequests =>
      'Las métricas aparecerán cuando se realicen solicitudes a la API';

  @override
  String get periodLabel => 'Período';

  @override
  String get weekLabel => 'semana';

  @override
  String get weeksLabel => 'semanas';

  @override
  String confirmCleanupWeeksQuestion(Object count, Object weeksLabel) {
    return '¿Estás seguro de que deseas eliminar solo los archivos multimedia (fotos y firmas) de pedidos entregados hace más de $count $weeksLabel?';
  }

  @override
  String get selectPharmacyRequired => 'Debes seleccionar una farmacia';

  @override
  String get noCsvDataToUpload => 'No hay datos CSV para subir';

  @override
  String get csvUploadSuccess =>
      'CSV subido exitosamente. Recibirás una notificación cuando termine el procesamiento.';

  @override
  String get errorUploadingCsv => 'Error al subir CSV';

  @override
  String get csvTemplateReady =>
      'Plantilla CSV generada y lista para descargar.';

  @override
  String get errorDownloadingTemplate => 'Error al descargar plantilla';

  @override
  String get generatePdfTitle => 'Generar PDF';

  @override
  String get filterByNameAddressHint => 'Filtrar por nombre, dirección';

  @override
  String get deselectAll => 'Deseleccionar Todo';

  @override
  String get selectAllOrders => 'Seleccionar Todos';

  @override
  String get errorLoadingPage => 'Error al cargar la página';

  @override
  String get noDriverInfoAvailable =>
      'No hay información del repartidor disponible';

  @override
  String get errorLoadingRouteDetails =>
      'No se pudieron cargar los detalles de la ruta';

  @override
  String get errorLoadingRouteDetailsWithError => 'Error al cargar detalles';

  @override
  String get driverDetailsTitle => 'Detalles del Repartidor';

  @override
  String get currentRouteLabel => 'Ruta Actual';

  @override
  String get routeIdLabel => 'Ruta ID';

  @override
  String get routeNameLabel => 'Nombre de Ruta';

  @override
  String get totalDistanceLabel => 'Distancia Total';

  @override
  String get assignedOrdersLabel => 'Pedidos Asignados';

  @override
  String get calculationDateLabel => 'Fecha de Cálculo';

  @override
  String get startDateLabel => 'Fecha de Inicio';

  @override
  String get completedDateLabel => 'Fecha de Completado';

  @override
  String get viewRoute => 'Ver Ruta';

  @override
  String ordersInOptimizedOrderCount(Object count) {
    return '$count pedidos en orden optimizado';
  }

  @override
  String get pickupLocationLabel => 'Ubicación Recojo';

  @override
  String get deliveryLocationLabel => 'Ubicación Entrega';

  @override
  String get typeLabel => 'Tipo';

  @override
  String get ordersUpdatedSuccess => 'Pedidos actualizados exitosamente';

  @override
  String get errorUpdatingOrders => 'Error al actualizar pedidos';

  @override
  String get lessThanOneMonth => 'menos de 1 mes';

  @override
  String get aboutOneMonth => '~1 mes';

  @override
  String aboutMonthsCount(Object count) {
    return '~$count meses';
  }

  @override
  String weeksBackDisplay(Object count, Object weeksLabel) {
    return '$count $weeksLabel hacia atrás';
  }

  @override
  String get weekShortLabel => 'sem';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get csvValidationErrorsPrefix => 'Errores encontrados en el CSV:';

  @override
  String get errorChangingItemsPerPage => 'Error al cambiar items por página';

  @override
  String get copyData => 'Copiar Datos';

  @override
  String get generatingPdf => 'Generando PDF...';

  @override
  String get loadingOrdersForPdf => 'Cargando pedidos para PDF...';

  @override
  String get noPendingOrdersForPdf =>
      'No hay pedidos pendientes para generar PDF';

  @override
  String get pendingOrdersPdfDescription =>
      'Los pedidos pendientes aparecerán aquí para generar etiquetas de envío';

  @override
  String get dateToday => 'Hoy';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String get dateDayBeforeYesterday => 'Anteayer';

  @override
  String get dateThreeDaysAgo => 'Hace 3 días';

  @override
  String ordersCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pedidos',
      one: '1 pedido',
    );
    return '$_temp0';
  }

  @override
  String get pdfDownloadUrlNotReceived =>
      'No se recibió URL de descarga del PDF';

  @override
  String get unknownErrorGeneratingPdf => 'Error desconocido al generar PDF';

  @override
  String get errorGeneratingPdf => 'Error al generar PDF';

  @override
  String errorGeneratingPdfWithError(Object error) {
    return 'Error al generar PDF: $error';
  }

  @override
  String get pdfGenerationTimeout =>
      'La generación del PDF tardó demasiado. Intente con menos etiquetas.';

  @override
  String get onlyPending => 'Solo Pendientes';

  @override
  String get understood => 'Entendido';

  @override
  String get csvHelpTitle => 'Ayuda - Cargar CSV';

  @override
  String get csvHelpHowToUse => 'Cómo usar esta herramienta:';

  @override
  String get csvHelpStep1Title => '1. Descargar plantilla';

  @override
  String get csvHelpStep1Description =>
      'Haz clic en el ícono de descarga para obtener la plantilla CSV con las columnas necesarias.';

  @override
  String get csvHelpStep2Title => '2. Llenar datos';

  @override
  String get csvHelpStep2Description =>
      'Completa la plantilla con los datos de los pedidos. Las coordenadas deben estar en formato \"latitud, longitud\".';

  @override
  String get csvHelpStep3Title => '3. Cargar archivo';

  @override
  String get csvHelpStep3Description =>
      'Arrastra y suelta tu archivo CSV o haz clic para seleccionarlo.';

  @override
  String get csvHelpStep4Title => '4. Seleccionar farmacia';

  @override
  String get csvHelpStep4Description =>
      'Elige la farmacia a la que se asignarán los pedidos.';

  @override
  String get csvHelpStep5Title => '5. Procesar';

  @override
  String get csvHelpStep5Description =>
      'Haz clic en \"Procesar\" para cargar los pedidos al sistema.';

  @override
  String get csvHelpTipTitle => 'Tip importante:';

  @override
  String get csvHelpTipCoordinates =>
      'Las coordenadas deben estar en formato decimal: \"26.037737, -80.179550\" para EEUU.';

  @override
  String orderAssignedToName(Object name) {
    return 'Pedido asignado a $name';
  }

  @override
  String get errorAssigningOrder => 'Error al asignar';

  @override
  String dateOfType(Object type) {
    return 'Fecha de $type';
  }

  @override
  String get noPharmaciesToShow => 'No hay farmacias para mostrar';

  @override
  String get noResponsible => 'Sin responsable';

  @override
  String get noPhone => 'Sin teléfono';

  @override
  String get noCity => 'Sin ciudad';

  @override
  String get tableHeaderAddress => 'DIRECCIÓN';

  @override
  String get tableHeaderResponsible => 'RESPONSABLE';

  @override
  String get tableHeaderCity => 'CIUDAD';

  @override
  String get tableHeaderLocation => 'UBICACIÓN';

  @override
  String get errorLoadingPharmaciesForForm =>
      'Error al cargar farmacias para el formulario';

  @override
  String errorLoadingData(Object error) {
    return 'Error al cargar datos: $error';
  }

  @override
  String get selectLocationOnMap => 'Debe seleccionar una ubicación en el mapa';

  @override
  String get orderUpdatedSuccess => 'Pedido actualizado exitosamente';

  @override
  String get orderCreatedSuccess => 'Pedido creado exitosamente';

  @override
  String get errorUpdatingOrder => 'Error al actualizar pedido';

  @override
  String get errorCreatingOrder => 'Error al crear pedido';

  @override
  String errorSavingOrder(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get editDelivery => 'Editar Entrega';

  @override
  String get newDelivery => 'Nueva Entrega';

  @override
  String get creatingNewDelivery => 'Creando nueva entrega';

  @override
  String get saveDelivery => 'Guardar Entrega';

  @override
  String get districtRequired => 'El distrito es requerido';

  @override
  String get deliveryAddressLine1Required =>
      'La dirección línea 1 es requerida';

  @override
  String get orderStatusLabel => 'Estado del Pedido';

  @override
  String quantityLabelShort(Object count) {
    return 'Cantidad: $count';
  }

  @override
  String get medicationDefaultName => 'Medicamento';

  @override
  String get selectDriverForOrderHint =>
      'Selecciona un repartidor para asignar al pedido';

  @override
  String driversAvailableTapToSearch(Object count) {
    return '$count repartidores disponibles - Toca para buscar';
  }

  @override
  String driversAvailableCount(Object count) {
    return '$count disponibles';
  }

  @override
  String get buildingAccessCodeHelper =>
      'Código para acceder al edificio o condominio';

  @override
  String get phoneRequired => 'El teléfono es requerido';

  @override
  String get errorUnassigningDriver => 'Error al retirar repartidor';

  @override
  String errorAssigningDriver(String detail) {
    return 'Error al asignar: $detail';
  }

  @override
  String get errorFetchingUpdatedData => 'Error al obtener datos actualizados';

  @override
  String get clientNameRequired => 'El nombre del cliente es requerido';

  @override
  String get medicationNameRequired => 'El nombre es requerido';

  @override
  String get medicationQuantityRequired => 'La cantidad es requerida';

  @override
  String get phoneLengthBetween =>
      'El teléfono debe tener entre 10 y 12 dígitos';

  @override
  String errorChangingDriver(Object error) {
    return 'Error al cambiar repartidor: $error';
  }

  @override
  String errorRefreshingData(Object error) {
    return 'Error al refrescar datos: $error';
  }

  @override
  String get enterValidQuantity => 'Ingresa una cantidad válida';

  @override
  String get uploadOrdersFromCsvTitle => 'Cargar Pedidos desde CSV';

  @override
  String get backTooltip => 'Volver';

  @override
  String get downloadCsvTemplateTooltip => 'Descargar plantilla CSV';

  @override
  String get helpTooltip => 'Ayuda';

  @override
  String get validationProgressTitle => 'Progreso de Validación';

  @override
  String get allRecordsHaveValidCoordinates =>
      'Todos los registros tienen coordenadas válidas';

  @override
  String get dragDropCsvHere => 'Arrastra y suelta tu archivo CSV aquí';

  @override
  String get orClickToSelectFile => 'o haz clic para seleccionar un archivo';

  @override
  String get fileInfoTitle => 'Información del archivo';

  @override
  String get fileSizeFormatHint =>
      'Tamaño máximo: 10MB • Formato: CSV • Codificación: UTF-8';

  @override
  String get csvFileLabel => 'Archivo CSV';

  @override
  String recordsLoadComplete(Object count, Object fileName) {
    return '$fileName - $count registros - Carga completa';
  }

  @override
  String get selectPharmacyToAssignOrders =>
      'Seleccionar Farmacia para asignar pedidos';

  @override
  String get noDataToShow => 'No hay datos para mostrar';

  @override
  String get selectCsvFileToPreview =>
      'Selecciona un archivo CSV para ver una vista previa de los datos';

  @override
  String get noLocation => 'Sin ubicación';

  @override
  String get emptyField => 'Campo vacío';

  @override
  String get processButton => 'Procesar';

  @override
  String get errorLoadingPharmaciesForExport =>
      'Error al cargar farmacias para exportar';

  @override
  String recordsValidCount(Object total, Object valid) {
    return '$valid/$total válidos';
  }

  @override
  String recordsNeedValidCoordinates(Object count) {
    return '$count registros necesitan coordenadas válidas';
  }

  @override
  String get userCanAccessSystem => 'El usuario puede acceder al sistema';

  @override
  String get userDisabled => 'Usuario deshabilitado';

  @override
  String get couldNotUpdateActiveStatus =>
      'No se pudo actualizar estado activo';

  @override
  String get updateLabel => 'Actualizar';

  @override
  String get createDriver => 'Crear Repartidor';

  @override
  String get tapToSelect => 'Toca para seleccionar';

  @override
  String get driverPhotoPlaceholder => 'Foto del repartidor';

  @override
  String errorUploadingImage(Object error) {
    return 'Error al subir imagen: $error';
  }

  @override
  String errorUpdatingActiveStatus(Object error) {
    return 'Error: $error';
  }

  @override
  String get locationLabel => 'Ubicación';

  @override
  String get errorGettingAddress => 'Error al obtener dirección';

  @override
  String get tapMapToSelectLocation =>
      'Toca el mapa para seleccionar una ubicación';

  @override
  String get centerButton => 'Centrar';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get barcodeCodeCopied => 'Código copiado al portapapeles';

  @override
  String get copyCodeTooltip => 'Copiar código';

  @override
  String get regenerateButton => 'Regenerar';

  @override
  String get alphanumericLabel => 'Alfanumérico';

  @override
  String get numericLabel => 'Numérico';

  @override
  String get errorGeneratingBarcode => 'Error al generar código de barras';

  @override
  String get errorLoadingImage => 'Error al cargar imagen';

  @override
  String get serverResponseError => 'Error en la respuesta del servidor';

  @override
  String get errorLoggingOut => 'Error al cerrar sesión';

  @override
  String get errorUpdatingProfile => 'Error al actualizar perfil';

  @override
  String get selectAPharmacy => 'Selecciona una farmacia';

  @override
  String get centralPharmacy => 'Farmacia Central';

  @override
  String get clearCsv => 'Limpiar CSV';

  @override
  String get orderTypeMedicalSupplies => 'Insumos Médicos';

  @override
  String get orderTypeMedicalEquipment => 'Equipos Médicos';

  @override
  String get orderTypeControlledMedications => 'Medicamentos Controlados';

  @override
  String get invalidCode => 'Código inválido';

  @override
  String get errorLabel => 'Error';

  @override
  String driverAssignedSuccess(String name) {
    return 'Repartidor $name asignado exitosamente';
  }

  @override
  String errorWithDetail(String detail) {
    return 'Error: $detail';
  }

  @override
  String orderCanceledSuccess(String id) {
    return 'Pedido #$id cancelado exitosamente';
  }

  @override
  String errorCancelingOrder(String detail) {
    return 'Error al cancelar pedido: $detail';
  }

  @override
  String orderMarkedFailedSuccess(String id) {
    return 'Pedido #$id marcado como fallido';
  }

  @override
  String errorMarkingOrderFailed(String detail) {
    return 'Error al marcar pedido como fallido: $detail';
  }

  @override
  String get defaultSchedulePlaceholder => 'Lun-Vie: 8:00-20:00';

  @override
  String get orderAssignedSuccess => 'Pedido asignado exitosamente';

  @override
  String errorAssigningOrderDetail(String detail) {
    return 'Error al asignar pedido: $detail';
  }

  @override
  String get orderDelivered => 'Pedido entregado';

  @override
  String get orderFailed => 'Pedido fallido';

  @override
  String get orderCancelledStatus => 'Pedido cancelado';

  @override
  String get reoptimizeRoute => 'Re-optimizar ruta';

  @override
  String get inQueue => 'En Cola';

  @override
  String get pickupAt => 'Recoger en: ';

  @override
  String get routeNotAvailable => 'Ruta no disponible';

  @override
  String get toPickup => 'a recogida';

  @override
  String get toDelivery => 'a entrega';

  @override
  String get completedStatus => 'completado';

  @override
  String get pickupLabel => 'Recoger: ';

  @override
  String get clientInformation => 'Información del Cliente';

  @override
  String get copyPhoneTooltip => 'Copiar teléfono';

  @override
  String get districtLabel => 'Distrito';

  @override
  String get viewMap => 'Ver Mapa';

  @override
  String get noChain => 'Sin cadena';

  @override
  String get orderTypeSectionTitle => 'Tipo de Pedido';

  @override
  String get orderTypeLabel => 'Tipo de pedido';

  @override
  String get signatureCaptured => 'Firma Capturada';

  @override
  String get deliveryNotFound => 'Entrega no encontrada';

  @override
  String deliveryNotFoundWithId(String id) {
    return 'La entrega #$id no existe';
  }

  @override
  String get pickedUp => 'Recogido';

  @override
  String get deliveredStatus => 'Entregado';

  @override
  String get noSignatureAvailable => 'No hay firma disponible';

  @override
  String get errorLoadingSignature => 'Error al cargar firma';

  @override
  String get errorRenderingSvg => 'Error al renderizar SVG';

  @override
  String get errorDecodingSignature => 'Error al decodificar firma';

  @override
  String get invalidSignatureFormat => 'Formato de firma inválido';

  @override
  String get onRoute => 'En Ruta';

  @override
  String get next => 'Siguiente';

  @override
  String get pickUpAction => 'Recoger';

  @override
  String get filterDelivered => 'Entregados';

  @override
  String get filterCancelled => 'Cancelados';

  @override
  String get filterFailed => 'Fallidos';

  @override
  String get profilePhotoUpdated => 'Foto de perfil actualizada';

  @override
  String get profilePhotoDeleted => 'Foto de perfil eliminada';

  @override
  String get confirmDeleteProfilePhotoQuestion =>
      '¿Estás seguro de que deseas eliminar tu foto de perfil?';

  @override
  String get securitySectionTitle => 'Seguridad';

  @override
  String get changeButton => 'Cambiar';

  @override
  String get min8Characters => 'Mínimo 8 caracteres';

  @override
  String get newPasswordMin8Chars =>
      'La nueva contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordChangedSuccess => 'Contraseña actualizada exitosamente';

  @override
  String errorChangingPassword(String detail) {
    return 'Error al cambiar contraseña: $detail';
  }

  @override
  String get errorChangingPasswordShort => 'Error al cambiar contraseña';

  @override
  String get activeSessions => 'Sesiones activas';

  @override
  String get drivingLicense => 'Licencia de Conducir';

  @override
  String get errorLoadingHistory => 'Error desconocido al cargar historial';

  @override
  String get orderIdShortLabel => 'Pedido ID:';

  @override
  String get pharmacyIdLabel => 'Farmacia ID:';

  @override
  String get copyButton => 'Copiar';

  @override
  String formatNumericDigits(int count) {
    return 'Formato numérico ($count dígitos)';
  }

  @override
  String formatAlphanumericChars(int count) {
    return 'Formato alfanumérico ($count caracteres)';
  }

  @override
  String get selectedLocationLabel => 'Ubicación seleccionada:';

  @override
  String get exitButton => 'Salir';

  @override
  String get invalidCoordinatesFormat =>
      'Formato de coordenadas no válido. Use: \"latitud, longitud\"';

  @override
  String get viewDriver => 'Ver Repartidor';

  @override
  String get optimizeRoutesTitle => 'Optimizar Rutas';

  @override
  String get optimizeButton => 'Optimizar';

  @override
  String get pharmacyDetailsTitle => 'Detalles de Farmacia';

  @override
  String get cameraPermissionTitle => 'Permiso de Cámara';

  @override
  String get settingsButton => 'Configuración';

  @override
  String get codeScanned => 'Código Escaneado';

  @override
  String get scanAnother => 'Escanear Otro';

  @override
  String get allowCameraAccess => 'Permitir Acceso a Cámara';

  @override
  String changeOrderTitle(String id) {
    return 'Cambiar orden - Pedido #$id';
  }

  @override
  String get patientLabel => 'Paciente:';

  @override
  String get reloadRoute => 'Recargar ruta';

  @override
  String viewDeliveriesCount(int count) {
    return 'Ver entregas ($count)';
  }

  @override
  String get revoke => 'Revocar';

  @override
  String get myLocation => 'Mi Ubicación';

  @override
  String deliveryMarkerTitle(String order, String name) {
    return '$order) Entrega - $name';
  }

  @override
  String get pickedUpCount => 'Recogido';

  @override
  String get pickUpCount => 'Recoger';

  @override
  String get optimizeRoutesConfirmation =>
      '¿Estás seguro de que quieres optimizar todas las rutas? Este proceso puede tomar varios minutos.';

  @override
  String get cameraPermissionContent =>
      'La aplicación necesita acceso a la cámara para escanear códigos de barras.';

  @override
  String get cameraPermissionRequired => 'Permiso de Cámara Requerido';

  @override
  String get cameraPermissionBody =>
      'Para escanear códigos de barras, necesitamos acceso a tu cámara.';

  @override
  String scanTitleWithMode(String mode) {
    return 'Escanear - $mode';
  }

  @override
  String get modeLabel => 'Modo:';

  @override
  String get orderNumberLabel => 'Pedido:';

  @override
  String get successDeliveryVerified =>
      'Código de entrega verificado correctamente';

  @override
  String get successPickupVerified =>
      'Código de recogida verificado correctamente';

  @override
  String get successVerified => 'Código verificado correctamente';

  @override
  String get successScanned => 'Código escaneado correctamente';

  @override
  String get flashTooltip => 'Flash';

  @override
  String get switchCameraTooltip => 'Cambiar Cámara';

  @override
  String get currentLocationLabel => 'Ubicación actual';

  @override
  String pickupMarkerTitle(String order, String name) {
    return '$order) Recogida - $name';
  }

  @override
  String pickupMarkerTitleWithCount(int count) {
    return 'Recogida ($count pendientes)';
  }

  @override
  String get pickupPointLabel => 'Punto de recogida';

  @override
  String get pendingLabel => 'Pendientes:';

  @override
  String get pickedUpLabel => 'Recogidos:';

  @override
  String get addressLabel => 'Dirección:';

  @override
  String get noPickupLocationAvailable =>
      'No hay ubicación de recogida disponible';

  @override
  String get noDeliveryLocationAvailable =>
      'No hay ubicación de entrega disponible';

  @override
  String get noValidLocationToNavigate =>
      'No hay ubicación válida para navegar';

  @override
  String get orderProcessed => 'Este pedido ya fue procesado';

  @override
  String get errorLoadingMap => 'Error al cargar el mapa';

  @override
  String get networkConfigTitle => 'Configuración de Red';

  @override
  String get logInfoButton => 'Log Info';

  @override
  String get routeMapTitle => 'Mapa de Ruta:';

  @override
  String get startPoint => 'Punto de Inicio';

  @override
  String get routeStart => 'Inicio de la ruta';

  @override
  String get endPoint => 'Punto Final';

  @override
  String get routeEnd => 'Final de la ruta';

  @override
  String get patient => 'Paciente';

  @override
  String get orderNumberPrefix => 'Pedido #';

  @override
  String get centerMap => 'Centrar mapa';

  @override
  String get legend => 'Leyenda:';

  @override
  String get start => 'Inicio';

  @override
  String get end => 'Final';

  @override
  String get orders => 'Pedidos';

  @override
  String get appTitle => 'MedRush - Delivery de Medicamentos';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get statusAssigned => 'Asignado';

  @override
  String get statusPickedUp => 'Recogido';

  @override
  String get statusInRoute => 'En Ruta';

  @override
  String get statusDelivered => 'Entregado';

  @override
  String get statusFailed => 'Fallido';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get orderTypeMedicines => 'Medicamentos';

  @override
  String get orderTypeControlledMedicines => 'Medicamentos Controlados';

  @override
  String get driverStatusAvailable => 'Disponible';

  @override
  String get driverStatusInRoute => 'En Ruta';

  @override
  String get driverStatusDisconnected => 'Desconectado';

  @override
  String get pharmacyStatusActive => 'Activa';

  @override
  String get pharmacyStatusInactive => 'Inactiva';

  @override
  String get pharmacyStatusSuspended => 'Suspendida';

  @override
  String get pharmacyStatusUnderReview => 'En Revisión';

  @override
  String get failureReasonClientNotFound => 'Cliente no se encontraba';

  @override
  String get failureReasonWrongAddress => 'Dirección incorrecta';

  @override
  String get failureReasonNoCalls => 'No recibió llamadas';

  @override
  String get failureReasonDeliveryRejected => 'Rechazó la entrega';

  @override
  String get failureReasonAccessDenied => 'Acceso denegado';

  @override
  String get failureReasonOther => 'Otro motivo';

  @override
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get yesterday => 'Ayer';

  @override
  String get monday => 'Lunes';

  @override
  String get tuesday => 'Martes';

  @override
  String get wednesday => 'Miércoles';

  @override
  String get thursday => 'Jueves';

  @override
  String get friday => 'Viernes';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get ago => 'hace';

  @override
  String get inTime => 'en';

  @override
  String get minute => 'min';

  @override
  String get minutes => 'minutos';

  @override
  String get hour => 'hora';

  @override
  String get hours => 'horas';

  @override
  String get day => 'día';

  @override
  String get days => 'días';

  @override
  String get month => 'mes';

  @override
  String get months => 'meses';

  @override
  String get year => 'año';

  @override
  String get years => 'años';

  @override
  String get dateTypeDelivery => 'Entrega';

  @override
  String get dateTypePickup => 'Recogida';

  @override
  String get dateTypeAssignment => 'Asignación';

  @override
  String get noDate => 'Sin fecha';

  @override
  String get recentlyAssigned => 'Recién asignado';

  @override
  String get recentlyPickedUp => 'Recién recogido';

  @override
  String get inRoute => 'En ruta';

  @override
  String get recentlyDelivered => 'Recién entregado';

  @override
  String get deliveryFailed => 'Entrega fallida';

  @override
  String get invalidTime => 'Tiempo inválido';

  @override
  String get addressNotSpecified => 'Dirección no especificada';

  @override
  String get cityNotSpecified => 'Ciudad no especificada';

  @override
  String get inProgress => 'En Progreso';

  @override
  String get notificationOrderStatusUpdated => 'Estado del Pedido Actualizado';

  @override
  String notificationOrderAssigned(Object code) {
    return 'El pedido $code ha sido asignado a un repartidor';
  }

  @override
  String notificationOrderPickedUp(Object code) {
    return 'El pedido $code ha sido recogido por el repartidor';
  }

  @override
  String notificationOrderInRoute(Object code) {
    return 'El pedido $code está en ruta hacia su destino';
  }

  @override
  String notificationOrderDelivered(Object code) {
    return 'El pedido $code ha sido entregado exitosamente';
  }

  @override
  String notificationOrderFailed(Object code) {
    return 'La entrega del pedido $code ha fallado';
  }

  @override
  String notificationOrderCancelled(Object code) {
    return 'El pedido $code ha sido cancelado';
  }

  @override
  String notificationOrderStatusChanged(
      Object code, Object newStatus, Object oldStatus) {
    return 'El estado del pedido $code ha cambiado de $oldStatus a $newStatus';
  }

  @override
  String get notificationDriverStatusUpdated =>
      'Estado del Repartidor Actualizado';

  @override
  String notificationDriverStatusChanged(
      Object name, Object newStatus, Object oldStatus) {
    return 'El repartidor $name cambió de estado de $oldStatus a $newStatus';
  }

  @override
  String get notificationPharmacyStatusUpdated =>
      'Estado de la Farmacia Actualizado';

  @override
  String notificationPharmacyStatusChanged(
      Object name, Object newStatus, Object oldStatus) {
    return 'La farmacia $name cambió de estado de $oldStatus a $newStatus';
  }

  @override
  String get userTypeAdministrator => 'Administrador';

  @override
  String get userTypeDriver => 'Repartidor';

  @override
  String get noData => 'Sin datos';

  @override
  String get noPages => 'Sin páginas';

  @override
  String get eventTypeCreated => 'Creado';

  @override
  String get eventTypeAssigned => 'Asignado';

  @override
  String get eventTypePickedUp => 'Recogido';

  @override
  String get eventTypeInRoute => 'En Ruta';

  @override
  String get eventTypeDelivered => 'Entregado';

  @override
  String get eventTypeFailed => 'Entrega Fallida';

  @override
  String get eventTypeCancelled => 'Cancelado';

  @override
  String get eventTypeRescheduled => 'Reagendado';

  @override
  String get eventTypeOrderCreated => 'Pedido Creado';

  @override
  String get eventTypeOrderAssigned => 'Pedido Asignado';

  @override
  String get eventTypeRouteOptimized => 'Ruta Optimizada';

  @override
  String get eventTypeLocationUpdated => 'Ubicación Actualizada';

  @override
  String get eventTypeDriverConnected => 'Repartidor Conectado';

  @override
  String get eventTypeDriverDisconnected => 'Repartidor Desconectado';

  @override
  String get eventTypePharmacyConnected => 'Farmacia Conectada';

  @override
  String get eventTypePharmacyDisconnected => 'Farmacia Desconectada';

  @override
  String get eventTypeNotificationSent => 'Notificación Enviada';

  @override
  String get signatureTypeFirstTime => 'Primera Vez';

  @override
  String get signatureTypeReception => 'Recepción';

  @override
  String get signatureTypeControlledMedicine => 'Medicamento Controlado';

  @override
  String get signatureTypeAuthorization => 'Autorización';

  @override
  String get signatureDescriptionFirstTime =>
      'Firma inicial del paciente para autorizar el servicio';

  @override
  String get signatureDescriptionReception =>
      'Firma de confirmación de recepción del pedido';

  @override
  String get signatureDescriptionControlledMedicine =>
      'Firma especial requerida para medicamentos controlados';

  @override
  String get signatureDescriptionAuthorization =>
      'Firma de autorización para el servicio de delivery';

  @override
  String get defaultCity => 'Ciudad';
}
