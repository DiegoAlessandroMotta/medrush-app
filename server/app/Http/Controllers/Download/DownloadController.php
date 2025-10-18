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

  public function medrushApp(Request $request)
  {
    $filePath = 'medrush-app/app-release.apk';

    if (!Storage::exists($filePath)) {
      throw CustomException::notFound('Archivo no encontrado: ' . $filePath);
    }

    return Storage::download($filePath);
  }
}
