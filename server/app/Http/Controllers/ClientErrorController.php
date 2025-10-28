<?php

namespace App\Http\Controllers;

use App\Helpers\ApiResponder;
use App\Http\Requests\ClientErrorIndexRequest;
use App\Http\Requests\ClientErrorReportRequest;
use App\Models\ClientError;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class ClientErrorController extends Controller
{
  public function report(ClientErrorReportRequest $request): JsonResponse
  {
    try {
      $context = $request->getContext();

      $context['ip_address'] = $request->ip();
      $context['user_agent'] = $request->header('User-Agent');
      $context['reported_at'] = Carbon::now()->toDateTimeString();

      if (!isset($context['occurred_at'])) {
        $context['occurred_at'] = $context['reported_at'];
      }

      $clientError = ClientError::create([
        'user_id' => Auth::id(),
        'context' => $context,
      ]);

      return ApiResponder::success(
        message: 'Error reportado exitosamente. Gracias por ayudarnos a mejorar la aplicación.',
        data: [
          'error_id' => $clientError->id,
          'reported_at' => $clientError->created_at->toISOString(),
        ]
      );
    } catch (\Exception $e) {
      Log::error('Error al procesar reporte de error del cliente', [
        'exception' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
        'request_data' => $request->all(),
      ]);

      return ApiResponder::serverError(
        message: 'No se pudo procesar el reporte de error. Inténtalo más tarde.'
      );
    }
  }

  public function index(ClientErrorIndexRequest $request): JsonResponse
  {
    $query = ClientError::with('user:id,name,email')
      ->orderBy($request->getOrderBy(), $request->getOrderDirection());

    if ($request->getErrorType()) {
      $query->whereJsonContains('context->error_type', $request->getErrorType());
    }

    if ($request->getPlatform()) {
      $query->whereJsonContains('context->platform', $request->getPlatform());
    }

    if ($request->getUserId()) {
      $query->where('user_id', $request->getUserId());
    }

    if ($request->getFromDate()) {
      $query->where('created_at', '>=', $request->getFromDate());
    }

    if ($request->getToDate()) {
      $query->where('created_at', '<=', $request->getToDate());
    }

    if ($request->hasSearch() && $request->getSearch()) {
      $search = $request->getSearch();
      $query->where(function ($q) use ($search) {
        $q->whereJsonContains('context->message', $search)
          ->orWhereJsonContains('context->error_type', $search)
          ->orWhereHas('user', function ($userQuery) use ($search) {
            $userQuery->where('name', 'like', "%{$search}%")
              ->orWhere('email', 'like', "%{$search}%");
          });
      });
    }

    $errors = $query->paginate($request->getPerPage());

    return ApiResponder::success(
      message: 'Lista de errores reportados por clientes',
      data: $errors
    );
  }

  public function show(ClientError $clientError): JsonResponse
  {
    $clientError->load('user:id,name,email');

    return ApiResponder::success(
      message: 'Detalle del error reportado',
      data: $clientError
    );
  }
}
