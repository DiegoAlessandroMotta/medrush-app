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
  /**
   * Crear PDF de etiquetas para pedidos.
   *
   * @OA\Post(
   *     path="/api/reportes-pdf/etiquetas-pedido",
   *     operationId="reportesPdfEtiquetasPedido",
   *     tags={"Entities","ReportesPdf"},
   *     summary="Generar PDF de etiquetas de pedidos",
   *     description="Crea un PDF con etiquetas de códigos de barras para los pedidos especificados. La generación es asincrónica y se notificará al usuario cuando esté listo para descargar.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         description="Lista de UUIDs de pedidos",
   *         @OA\JsonContent(
   *             required={"pedidos"},
   *             @OA\Property(property="pedidos", type="array",
   *                 description="Array de UUIDs de pedidos (mínimo 1, máximo 500)",
   *                 items=@OA\Items(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000"),
   *                 minItems=1,
   *                 maxItems=500
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=202,
   *         description="Generación de PDF aceptada",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="La creación del PDF de etiquetas ha sido iniciada. Recibirás una notificación cuando esté listo."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid"),
   *                 @OA\Property(property="nombre", type="string"),
   *                 @OA\Property(property="status", type="string", enum={"en_proceso","creado","fallido","expirado"}, example="en_proceso"),
   *                 @OA\Property(property="page_size", type="string", example="A5"),
   *                 @OA\Property(property="pedidos", type="array", items=@OA\Items(type="string")),
   *                 @OA\Property(property="created_at", type="string", format="date-time"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time")
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Error de validación",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Listar reportes PDF generados.
   *
   * @OA\Get(
   *     path="/api/reportes-pdf",
   *     operationId="reportesPdfIndex",
   *     tags={"Entities","ReportesPdf"},
   *     summary="Listar reportes PDF",
   *     description="Obtiene una lista paginada de reportes PDF generados por el usuario actual o todos si es administrador.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="page",
   *         in="query",
   *         required=false,
   *         description="Número de página (por defecto: 1)",
   *         @OA\Schema(type="integer", example=1)
   *     ),
   *     @OA\Parameter(
   *         name="per_page",
   *         in="query",
   *         required=false,
   *         description="Cantidad de registros por página (por defecto: 15)",
   *         @OA\Schema(type="integer", example=15)
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección de ordenamiento",
   *         @OA\Schema(type="string", enum={"asc","desc"}, example="desc")
   *     ),
   *     @OA\Parameter(
   *         name="fecha_desde",
   *         in="query",
   *         required=false,
   *         description="Filtrar por fecha de creación desde",
   *         @OA\Schema(type="string", format="date", example="2024-01-01")
   *     ),
   *     @OA\Parameter(
   *         name="fecha_hasta",
   *         in="query",
   *         required=false,
   *         description="Filtrar por fecha de creación hasta",
   *         @OA\Schema(type="string", format="date", example="2024-12-31")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de reportes PDF obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando los reportes pdf."),
   *             @OA\Property(property="data", type="array",
   *                 items=@OA\Items(type="object",
   *                     @OA\Property(property="id", type="string", format="uuid"),
   *                     @OA\Property(property="nombre", type="string"),
   *                     @OA\Property(property="status", type="string", enum={"en_proceso","creado","fallido","expirado"}),
   *                     @OA\Property(property="paginas", type="integer", nullable=true),
   *                     @OA\Property(property="created_at", type="string", format="date-time"),
   *                     @OA\Property(property="updated_at", type="string", format="date-time")
   *                 )
   *             ),
   *             @OA\Property(property="pagination", type="object", ref="#/components/schemas/PaginationInfo")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Obtener detalles de un reporte PDF.
   *
   * @OA\Get(
   *     path="/api/reportes-pdf/{reportePdf}",
   *     operationId="reportesPdfShow",
   *     tags={"Entities","ReportesPdf"},
   *     summary="Obtener reporte PDF",
   *     description="Obtiene la información completa de un reporte PDF, incluyendo URL de descarga firmada y detalles del archivo.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="reportePdf",
   *         in="path",
   *         required=true,
   *         description="UUID del reporte PDF",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Detalles del reporte PDF obtenidos exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando información del reporte"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid"),
   *                 @OA\Property(property="user_id", type="string", format="uuid"),
   *                 @OA\Property(property="nombre", type="string"),
   *                 @OA\Property(property="file_url", type="string", format="url", nullable=true, description="URL de descarga firmada válida por 60 minutos"),
   *                 @OA\Property(property="file_size", type="integer", nullable=true, description="Tamaño del archivo en bytes"),
   *                 @OA\Property(property="page_size", type="string", example="A5"),
   *                 @OA\Property(property="paginas", type="integer", nullable=true),
   *                 @OA\Property(property="pedidos", type="array", items=@OA\Items(type="string", format="uuid")),
   *                 @OA\Property(property="status", type="string", enum={"en_proceso","creado","fallido","expirado"}),
   *                 @OA\Property(property="created_at", type="string", format="date-time"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time")
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Reporte PDF no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function show(ReportePdf $reportePdf)
  {
    return ApiResponder::success(
      message: 'Mostrando información del reporte',
      data: ReportePdfResource::make($reportePdf),
    );
  }

  /**
   * Eliminar un reporte PDF.
   *
   * @OA\Delete(
   *     path="/api/reportes-pdf/{reportePdf}",
   *     operationId="reportesPdfDelete",
   *     tags={"Entities","ReportesPdf"},
   *     summary="Eliminar reporte PDF",
   *     description="Elimina un reporte PDF y su archivo asociado del almacenamiento.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="reportePdf",
   *         in="path",
   *         required=true,
   *         description="UUID del reporte PDF",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=204,
   *         description="Reporte PDF eliminado exitosamente"
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Reporte PDF no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function delete(ReportePdf $reportePdf)
  {
    if (!$reportePdf->deleteFromDisk()) {
      throw CustomException::internalServer('Ha ocurrido un error inesperado al intentar eliminar el archivo pdf');
    };

    $reportePdf->delete();

    return ApiResponder::noContent();
  }

  /**
   * Eliminar reportes PDF antiguos.
   *
   * @OA\Delete(
   *     path="/api/reportes-pdf/antiguos",
   *     operationId="reportesPdfDeleteAntiguos",
   *     tags={"Entities","ReportesPdf"},
   *     summary="Eliminar reportes PDF antiguos",
   *     description="Inicia un trabajo asíncrono para eliminar automáticamente todos los reportes PDF cuya fecha de creación sea anterior a 30 días desde hoy.",
   *     security={{"sanctum":{}}},
   *     @OA\Response(
   *         response=202,
   *         description="Proceso de eliminación iniciado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="La eliminación de reportes PDF antiguos ha sido iniciada."),
   *             @OA\Property(property="data", type="null")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function deleteAntiguos()
  {
    DeleteOldPdfReportsJob::dispatch();

    return ApiResponder::accepted(
      message: 'La eliminación de reportes PDF antiguos ha sido iniciada.'
    );
  }

  /**
   * Regenerar un reporte PDF.
   *
   * @OA\Patch(
   *     path="/api/reportes-pdf/{reportePdf}/regenerar",
   *     operationId="reportesPdfRegenenar",
   *     tags={"Entities","ReportesPdf"},
   *     summary="Regenerar reporte PDF",
   *     description="Elimina el archivo PDF actual y reinicia el proceso de generación. La URL de descarga estará disponible cuando el proceso asíncrono se complete.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="reportePdf",
   *         in="path",
   *         required=true,
   *         description="UUID del reporte PDF",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=202,
   *         description="Proceso de regeneración iniciado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="La regeneración del PDF ha sido iniciada. Recibirás una notificación cuando esté listo."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid"),
   *                 @OA\Property(property="user_id", type="string", format="uuid"),
   *                 @OA\Property(property="nombre", type="string"),
   *                 @OA\Property(property="file_url", type="string", format="url", nullable=true),
   *                 @OA\Property(property="file_size", type="integer", nullable=true),
   *                 @OA\Property(property="page_size", type="string"),
   *                 @OA\Property(property="paginas", type="integer", nullable=true),
   *                 @OA\Property(property="pedidos", type="array", items=@OA\Items(type="string", format="uuid")),
   *                 @OA\Property(property="status", type="string", enum={"en_proceso","creado","fallido","expirado"}),
   *                 @OA\Property(property="created_at", type="string", format="date-time"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time")
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Reporte PDF no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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
