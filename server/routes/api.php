<?php

use App\Http\Controllers\Api\DirectionsController;
use App\Http\Controllers\Api\GeocodingController;
use App\Http\Controllers\Auth\AuthController;
use App\Http\Controllers\Download\DownloadController;
use App\Http\Controllers\Entities\EventoPedidoController;
use App\Http\Controllers\Entities\FarmaciaController;
use App\Http\Controllers\Entities\GoogleApiUsageController;
use App\Http\Controllers\Entities\ReportePdfController;
use App\Http\Controllers\Entities\PedidoController;
use App\Http\Controllers\Entities\RutaController;
use App\Http\Controllers\Entities\UbicacionRepartidorController;
use App\Http\Controllers\FcmDeviceTokenController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\User\AdminUserController;
use App\Http\Controllers\User\BaseUserController;
use App\Http\Controllers\User\FarmaciaUserController;
use App\Http\Controllers\User\RepartidorUserController;
use App\Models\Farmacia;
use App\Models\Pedido;
use App\Models\PerfilFarmacia;
use App\Models\PerfilRepartidor;
use App\Models\Ruta;
use App\Models\UbicacionRepartidor;
use App\Models\User;
use Illuminate\Support\Facades\Route;

Route::middleware('guest')->group(function () {
  Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
  });
});

Route::middleware('auth:sanctum')->group(function () {
  Route::prefix('auth')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);

    Route::post('/logout', [AuthController::class, 'logout']);

    Route::post('/logout-all', [AuthController::class, 'logoutAll']);

    Route::get('/tokens', [AuthController::class, 'listTokens']);

    Route::delete('/tokens/{tokenId}', [AuthController::class, 'revokeToken'])
      ->whereNumber('tokenId');
  });

  Route::prefix('user')->group(function () {
    Route::prefix('notificaciones')->group(function () {
      Route::get('/', [NotificationController::class, 'index']);

      Route::get('/unread-count', [NotificationController::class, 'getUnreadCount']);

      Route::post('/mark-all-read', [NotificationController::class, 'markAllAsRead']);

      Route::delete('/clear-read', [NotificationController::class, 'clearRead']);

      Route::get('/{notification}', [NotificationController::class, 'show'])
        ->whereUuid('notification');

      Route::patch('/{notification}/mark-read', [NotificationController::class, 'markAsRead'])
        ->whereUuid('notification');

      Route::delete('/{notification}', [NotificationController::class, 'destroy'])
        ->whereUuid('notification');
    });

    Route::post('/{user}/foto', [BaseUserController::class, 'uploadPicture'])
      ->whereUuid('user')
      ->can('uploadPicture', 'user');

    Route::patch('/{user}/activo', [BaseUserController::class, 'activo'])
      ->whereUuid('user')
      ->can('updateActivo', 'user');

    Route::prefix('repartidores')->group(function () {
      Route::get('/', [RepartidorUserController::class, 'index'])
        ->can('viewAny', PerfilRepartidor::class);

      Route::post('/', [RepartidorUserController::class, 'register'])
        ->can('register', PerfilRepartidor::class);

      Route::post('/{perfilRepartidor}/dni-id', [RepartidorUserController::class, 'uploadFotoDniId'])
        ->whereUuid('perfilRepartidor')
        ->can('update', 'perfilRepartidor');

      Route::post('/{perfilRepartidor}/licencia', [RepartidorUserController::class, 'uploadFotoLicencia'])
        ->whereUuid('perfilRepartidor')
        ->can('update', 'perfilRepartidor');

      Route::post('/{perfilRepartidor}/seguro-vehiculo', [RepartidorUserController::class, 'uploadFotoSeguroVehiculo'])
        ->whereUuid('perfilRepartidor')
        ->can('update', 'perfilRepartidor');

      Route::get('/{perfilRepartidor}', [RepartidorUserController::class, 'show'])
        ->whereUuid('perfilRepartidor')
        ->can('view', 'perfilRepartidor');

      Route::patch('/{perfilRepartidor}', [RepartidorUserController::class, 'update'])
        ->whereUuid('perfilRepartidor')
        ->can('update', 'perfilRepartidor');

      Route::patch('/{perfilRepartidor}/verificado', [RepartidorUserController::class, 'updateVerificado'])
        ->whereUuid('perfilRepartidor')
        ->can('updateVerificado', 'perfilRepartidor');

      Route::patch('/{perfilRepartidor}/estado', [RepartidorUserController::class, 'updateEstado'])
        ->whereUuid('perfilRepartidor')
        ->can('updateEstado', 'perfilRepartidor');

      Route::delete('/{perfilRepartidor}', [RepartidorUserController::class, 'destroy'])
        ->whereUuid('perfilRepartidor')
        ->can('delete', 'perfilRepartidor');
    });

    Route::prefix('farmacias')->group(function () {
      Route::get('/', [FarmaciaUserController::class, 'index'])
        ->can('viewAny', PerfilFarmacia::class);

      Route::post('/', [FarmaciaUserController::class, 'register'])
        ->can('register', PerfilFarmacia::class);

      Route::get('/{perfilFarmacia}', [FarmaciaUserController::class, 'show'])
        ->whereUuid('perfilFarmacia')
        ->can('view', 'perfilFarmacia');

      Route::patch('/{perfilFarmacia}', [FarmaciaUserController::class, 'update'])
        ->whereUuid('perfilFarmacia')
        ->can('update', 'perfilFarmacia');

      Route::delete('/{perfilFarmacia}', [FarmaciaUserController::class, 'destroy'])
        ->whereUuid('perfilFarmacia')
        ->can('delete', 'perfilFarmacia');
    });

    Route::prefix('administradores')->group(function () {
      Route::get('/', [AdminUserController::class, 'index'])
        ->can('viewAny', User::class);

      Route::post('/', [AdminUserController::class, 'register'])
        ->can('register', User::class);

      Route::get('/{user}', [AdminUserController::class, 'show'])
        ->whereUuid('user')
        ->can('view', 'user');

      Route::patch('/{user}', [AdminUserController::class, 'update'])
        ->whereUuid('user')
        ->can('update', 'user');

      Route::delete('/{user}', [AdminUserController::class, 'destroy'])
        ->whereUuid('user')
        ->can('delete', 'user');
    });
  });

  Route::prefix('fcm')->group(function () {
    Route::post('/tokens', [FcmDeviceTokenController::class, 'store']);

    Route::delete('/tokens/:token', [FcmDeviceTokenController::class, 'destroy']);

    Route::delete('/tokens/current-session', [FcmDeviceTokenController::class, 'destroyCurrentSessionTokens']);
  });

  Route::prefix('pedidos')->group(function () {
    Route::get('/', [PedidoController::class, 'index'])
      ->can('viewAny', Pedido::class);

    Route::post('/', [PedidoController::class, 'store'])
      ->can('create', Pedido::class);

    Route::post('/cargar-csv', [PedidoController::class, 'uploadCsv'])
      ->can('createFromCsv', Pedido::class);

    Route::get('/{pedido}', [PedidoController::class, 'show'])
      ->whereUuid('pedido')
      ->can('view', 'pedido');

    Route::get('/codigo-barra/{pedido:codigo_barra}', [PedidoController::class, 'show'])
      ->whereAlphaNumeric('pedido')
      ->can('view', 'pedido');

    Route::patch('/{pedido}', [PedidoController::class, 'update'])
      ->whereUuid('pedido')
      ->can('update', 'pedido');

    Route::patch('/{pedido}/asignar', [PedidoController::class, 'asignar'])
      ->whereUuid('pedido')
      ->can('asignar', 'pedido');

    Route::patch('/{pedido:codigo_barra}/asignar/codigo-barra', [PedidoController::class, 'asignar'])
      ->whereAlphaNumeric('pedido')
      ->can('asignar', 'pedido');

    Route::patch('/{pedido}/retirar-repartidor', [PedidoController::class, 'retirarRepartidor'])
      ->whereUuid('pedido')
      ->can('retirarRepartidor', 'pedido');

    Route::patch('/{pedido}/cancelar', [PedidoController::class, 'cancelar'])
      ->whereUuid('pedido')
      ->can('cancelar', 'pedido');

    Route::patch('/{pedido}/recoger', [PedidoController::class, 'recoger'])
      ->whereUuid('pedido')
      ->can('recoger', 'pedido');

    Route::patch('/{pedido:codigo_barra}/recoger/codigo-barra', [PedidoController::class, 'recoger'])
      ->whereAlphaNumeric('pedido')
      ->can('recoger', 'pedido');

    Route::patch('/{pedido}/en-ruta', [PedidoController::class, 'enRuta'])
      ->whereUuid('pedido')
      ->can('enRuta', 'pedido');

    Route::post('/{pedido}/entregar', [PedidoController::class, 'entregar'])
      ->whereUuid('pedido')
      ->can('entregar', 'pedido');

    Route::patch('/{pedido}/fallo-entrega', [PedidoController::class, 'falloEntrega'])
      ->whereUuid('pedido')
      ->can('falloEntrega', 'pedido');

    // Route::patch('/{pedido}/devolver', [PedidoController::class, 'devolver'])
    //   ->whereUuid('pedido');

    Route::delete('/{pedido}', [PedidoController::class, 'destroy'])
      ->whereUuid('pedido')
      ->can('delete', 'pedido');

    Route::prefix('/{pedido}/eventos')->group(function () {
      Route::get('/', [EventoPedidoController::class, 'index'])
        ->can('view', 'pedido');
    })
      ->whereUuid('pedido');
  });

  Route::prefix('farmacias')->group(function () {
    Route::get('/', [FarmaciaController::class, 'index'])
      ->can('viewAny', Farmacia::class);

    Route::post('/', [FarmaciaController::class, 'store'])
      ->can('create', Farmacia::class);

    Route::get('/{farmacia}', [FarmaciaController::class, 'show'])
      ->whereUuid('farmacia')
      ->can('view', 'farmacia');

    Route::get('/{farmacia}/users', [FarmaciaController::class, 'listUsers'])
      ->whereUuid('farmacia');

    Route::get('/ruc-ein/{farmacia:ruc_ein}', [FarmaciaController::class, 'show'])
      ->can('view', 'farmacia');

    Route::patch('/{farmacia}', [FarmaciaController::class, 'update'])
      ->whereUuid('farmacia')
      ->can('update', 'farmacia');

    Route::patch('/{farmacia}/estado', [FarmaciaController::class, 'updateEstado'])
      ->whereUuid('farmacia');

    Route::delete('/{farmacia}', [FarmaciaController::class, 'destroy'])
      ->whereUuid('farmacia')
      ->can('delete', 'farmacia');
  });

  Route::prefix('ubicaciones-repartidor')->group(function () {
    Route::get('/', [UbicacionRepartidorController::class, 'index'])
      ->can('viewAny', UbicacionRepartidor::class);

    Route::post('/', [UbicacionRepartidorController::class, 'store'])
      ->can('create', UbicacionRepartidor::class);
  });

  Route::prefix('rutas')->group(function () {
    Route::get('/', [RutaController::class, 'index'])
      ->can('viewAny', Ruta::class);

    Route::post('/', [RutaController::class, 'store'])
      ->can('create', Ruta::class);

    Route::post('/optimizar', [RutaController::class, 'optimizarAll'])
      ->can('optimizeRutas', Ruta::class);

    Route::get('/{ruta}', [RutaController::class, 'show'])
      ->can('view', 'ruta')
      ->whereUuid('ruta');

    Route::get('/current', [RutaController::class, 'miRuta']);

    Route::patch('/{ruta}', [RutaController::class, 'update'])
      ->can('update', 'ruta')
      ->whereUuid('ruta');

    Route::patch('/{ruta}/optimizar', [RutaController::class, 'optimizarRuta'])
      ->can('update', 'ruta')
      ->whereUuid('ruta');

    Route::delete('/{ruta}', [RutaController::class, 'destroy'])
      ->can('delete', 'ruta')
      ->whereUuid('ruta');

    Route::prefix('/{ruta}/pedidos')->group(function () {
      Route::get('/', [RutaController::class, 'listPedidos'])
        ->can('view', 'ruta');

      Route::post('/', [RutaController::class, 'addPedido'])
        ->can('update', 'ruta');

      Route::delete('/{pedido}', [RutaController::class, 'removePedido'])
        ->can('update', 'ruta')
        ->whereUuid('pedido');

      Route::patch('/reordenar', [RutaController::class, 'reordenarPedidos'])
        ->can('update', 'ruta')
        ->whereUuid('ruta');
    })
      ->whereUuid('ruta');
  });

  Route::prefix('reportes-pdf')->group(function () {
    Route::get('/', [ReportePdfController::class, 'index']);

    Route::get('/{reportePdf}', [ReportePdfController::class, 'show'])
      ->whereUuid('reportePdf');

    Route::delete('/{reportePdf}', [ReportePdfController::class, 'delete'])
      ->whereUuid('reportePdf');

    Route::delete('/antiguos', [ReportePdfController::class, 'deleteAntiguos']);

    Route::patch('/{reportePdf}/regenerar', [ReportePdfController::class, 'regenerar'])
      ->whereUuid('reportePdf');

    Route::prefix('etiquetas-pedido')->group(function () {
      Route::post('/', [ReportePdfController::class, 'etiquetasPedido']);
    });
  });

  Route::prefix('google-api-usage')->group(function () {
    Route::get('/stats', [GoogleApiUsageController::class, 'getUsageStats']);
  });

  Route::prefix('downloads')->group(function () {
    Route::get('/templates/csv/{lang}/{templateKey}/signed-url', [DownloadController::class, 'getSignedCsvTemplateUrl'])
      ->name('downloads.csv_template.get_signed_url')
      ->can('getSignedUrlCsvTemplate');
  });

  Route::prefix('geocoding')->group(function () {
    Route::post('/reverse', [GeocodingController::class, 'reverseGeocode']);
  });

  Route::prefix('directions')->group(function () {
    Route::post('/with-waypoints', [DirectionsController::class, 'getDirectionsWithWaypoints']);
    Route::post('/route-info', [DirectionsController::class, 'getRouteInfo']);
  });
});

Route::middleware('signed')->group(function () {
  Route::prefix('downloads')->group(function () {
    Route::get('/templates/csv/{lang}/{templateKey}', [DownloadController::class, 'csvTemplates'])
      ->name('downloads.csv_template.download');
  });
});

Route::prefix('downloads')->group(function () {
  Route::get('/medrush-app/apk', [DownloadController::class, 'medrushApp']);
});
