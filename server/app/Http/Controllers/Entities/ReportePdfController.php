<?php

namespace App\Http\Controllers\Entities;

use App\Enums\EstadoReportePdfEnum;
use App\Enums\PageSizeEnum;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\BasePaginationRequest;
use App\Http\Requests\ReportePdf\CreateEtiquetasPedidoRequest;
use App\Http\Resources\ReportePdf\ReportePdfItemResource;
use App\Http\Resources\ReportePdf\ReportePdfResource;
use App\Jobs\Pdf\DeleteOldPdfReportsJob;
use App\Jobs\Pdf\GeneratePedidosBarcodePdf;
use App\Models\ReportePdf;
use Auth;
use Carbon\Carbon;
use Storage;
use Str;

class ReportePdfController extends Controller
{
  public function etiquetasPedido(CreateEtiquetasPedidoRequest $request)
  {
    $user = Auth::user();
    $pedidosIds = $request->getValidatedPedidosIds();

    /** @var ReportePdf $reportePdf  */
    $reportePdf = ReportePdf::create([
      'user_id' => $user->id,
      'nombre' => 'etiquetas-' . Str::uuid() . '.pdf',
      'pedidos' => $pedidosIds,
      'page_size' => PageSizeEnum::A5,
      'status' => EstadoReportePdfEnum::EN_PROCESO,
    ]);

    GeneratePedidosBarcodePdf::dispatch($reportePdf->id);

    return ApiResponder::accepted(
      message: 'La creación del PDF de etiquetas ha sido iniciada. Recibirás una notificación cuando esté listo.',
      data: ReportePdfResource::make($reportePdf),
    );
  }

  public function index(BasePaginationRequest $request)
  {
    $perPage = $request->getPerPage();
    $currentPage = $request->getCurrentPage();
    $orderBy = 'updated_at';
    $orderDirection = $request->getOrderDirection();

    $query = ReportePdf::query();

    $fechaDesde = $request->getFechaDesde();
    $fechaHasta = $request->getFechaHasta();
    if ($fechaDesde !== null && $fechaHasta !== null) {
      $query->whereBetween('updated_at', [$fechaDesde, $fechaHasta]);
    } elseif ($fechaDesde !== null) {
      $query->where('updated_at', '>=', $fechaDesde);
    } elseif ($fechaHasta !== null) {
      $query->where('updated_at', '<=', $fechaHasta);
    }

    $query->orderBy($orderBy, $orderDirection);

    $pagination = $query->paginate(
      perPage: $perPage,
      page: $currentPage,
    );

    return ApiResponder::success(
      message: 'Mostrando los reportes pdf.',
      data: ReportePdfItemResource::collection($pagination->items()),
      pagination: $pagination,
    );
  }

  public function show(ReportePdf $reportePdf)
  {
    return ApiResponder::success(
      message: 'Mostrando información del reporte',
      data: ReportePdfResource::make($reportePdf),
    );
  }

  public function delete(ReportePdf $reportePdf)
  {
    if (!$reportePdf->deleteFromDisk()) {
      throw CustomException::internalServer('Ha ocurrido un error inesperado al intentar eliminar el archivo pdf');
    };

    $reportePdf->delete();

    return ApiResponder::noContent();
  }

  public function deleteAntiguos()
  {
    DeleteOldPdfReportsJob::dispatch();

    return ApiResponder::accepted(
      message: 'La eliminación de reportes PDF antiguos ha sido iniciada.'
    );
  }

  public function regenerar(ReportePdf $reportePdf)
  {
    if ($reportePdf->file_path !== null && Storage::exists($reportePdf->file_path)) {
      Storage::delete($reportePdf->file_path);
    }

    $reportePdf->markAsInProcess();

    GeneratePedidosBarcodePdf::dispatch($reportePdf->id);

    return ApiResponder::accepted(
      message: 'La regeneración del PDF ha sido iniciada. Recibirás una notificación cuando esté listo.',
      data: ReportePdfResource::make($reportePdf),
    );
  }
}
