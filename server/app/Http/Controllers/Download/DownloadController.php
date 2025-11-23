<?php

namespace App\Http\Controllers\Download;

use App\Console\Commands\GenerateCsvTemplates;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Storage;
use URL;

class DownloadController extends Controller
{
  /**
   * @OA\Get(
   *     path="/api/downloads/csv-template/{lang}/{templateKey}/url",
   *     operationId="downloadGetSignedCsvTemplateUrl",
   *     tags={"Downloads"},
   *     summary="Obtener URL firmada para descargar plantilla CSV",
   *     description="Genera una URL firmada y temporal (válida 15 minutos) para descargar una plantilla CSV en el idioma especificado. Útil para importación de datos masivos.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="lang",
   *         in="path",
   *         required=true,
   *         description="Código de idioma (ej: es, en)",
   *         @OA\Schema(type="string", example="es"),
   *     ),
   *     @OA\Parameter(
   *         name="templateKey",
   *         in="path",
   *         required=true,
   *         description="Identificador de la plantilla (ej: pedidos, farmacias, repartidores)",
   *         @OA\Schema(type="string", example="pedidos"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="URL firmada generada exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="URL firmada generada exitosamente."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="signed_url", type="string", format="url", description="URL temporal firmada para descargar", example="https://api.example.com/downloads/csv-template/es/pedidos?signature=..."),
   *                 @OA\Property(property="expires_at", type="string", format="date-time", description="Fecha/hora de expiración de la URL", example="2025-11-22T11:00:00Z"),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Plantilla CSV no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function getSignedCsvTemplateUrl(
    Request $request,
    string $lang,
    string $templateKey
  ): \Illuminate\Http\JsonResponse {
    $baseTemplatesDir = GenerateCsvTemplates::BASE_CSV_TEMPLATES_DIR;
    $filePath = "{$baseTemplatesDir}/{$lang}_{$templateKey}_template.csv";

    if (!Storage::exists($filePath)) {
      throw CustomException::notFound('Plantilla CSV no encontrada');
    }

    $expirationTime = now()->addMinutes(15);
    $signedUrl = URL::temporarySignedRoute(
      'downloads.csv_template.download',
      $expirationTime,
      [
        'lang' => $lang,
        'templateKey' => $templateKey,
      ]
    );

    return ApiResponder::success(
      message: 'URL firmada generada exitosamente.',
      data: [
        'signed_url' => $signedUrl,
        'expires_at' => $expirationTime->toIso8601String(),
      ]
    );
  }

  /**
   * @OA\Get(
   *     path="/api/downloads/csv-template/{lang}/{templateKey}",
   *     operationId="downloadCsvTemplate",
   *     tags={"Downloads"},
   *     summary="Descargar plantilla CSV",
   *     description="Descarga una plantilla CSV para importación de datos. Esta ruta debe ser accedida con la URL firmada generada por el endpoint anterior.",
   *     @OA\Parameter(
   *         name="lang",
   *         in="path",
   *         required=true,
   *         description="Código de idioma",
   *         @OA\Schema(type="string", example="es"),
   *     ),
   *     @OA\Parameter(
   *         name="templateKey",
   *         in="path",
   *         required=true,
   *         description="Identificador de la plantilla",
   *         @OA\Schema(type="string", example="pedidos"),
   *     ),
   *     @OA\Parameter(
   *         name="signature",
   *         in="query",
   *         required=false,
   *         description="Firma de URL (requerida si la ruta lo exige)",
   *         @OA\Schema(type="string"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Archivo CSV descargado exitosamente",
   *         @OA\MediaType(
   *             mediaType="text/csv",
   *             @OA\Schema(type="string", format="binary")
   *         ),
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Plantilla no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function csvTemplates(Request $request, string $lang, string $templateKey)
  {
    $baseTemplatesDir = GenerateCsvTemplates::BASE_CSV_TEMPLATES_DIR;

    $filePath = "{$baseTemplatesDir}/{$lang}_{$templateKey}_template.csv";

    if (!Storage::exists($filePath)) {
      throw CustomException::notFound('Plantilla CSV no encontrada');
    }

    $downloadFileName = "{$templateKey}_template.csv";

    return Storage::download($filePath, $downloadFileName);
  }

  /**
   * @OA\Get(
   *     path="/api/downloads/app",
   *     operationId="downloadMedrushApp",
   *     tags={"Downloads"},
   *     summary="Descargar aplicación MedRush (APK)",
   *     description="Descarga el archivo APK de la aplicación MedRush para instalar en dispositivos Android.",
   *     @OA\Response(
   *         response=200,
   *         description="Archivo APK descargado exitosamente",
   *         @OA\MediaType(
   *             mediaType="application/vnd.android.package-archive",
   *             @OA\Schema(type="string", format="binary")
   *         ),
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Archivo de aplicación no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function medrushApp(Request $request)
  {
    $filePath = 'medrush-app/app-release.apk';

    if (!Storage::exists($filePath)) {
      throw CustomException::notFound('Archivo no encontrado: ' . $filePath);
    }

    return Storage::download($filePath);
  }
}
