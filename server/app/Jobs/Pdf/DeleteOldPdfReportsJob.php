<?php

namespace App\Jobs\Pdf;

use App\Models\ReportePdf;
use Carbon\Carbon;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Log;

class DeleteOldPdfReportsJob implements ShouldQueue
{
  use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

  public $tries = 2;
  public $timeout = 300;

  private int $hours;

  public function __construct(int $hours = 24)
  {
    $this->hours = $hours;
  }

  public function handle(): void
  {
    $cutoffTime = Carbon::now()->subHours($this->hours);

    /** @var \Illuminate\Database\Eloquent\Collection<int, ReportePdf> $oldReports */
    $oldReports = ReportePdf::where('updated_at', '<', $cutoffTime)
      ->whereNotNull('file_path')
      ->get();

    if ($oldReports->isEmpty()) {
      Log::info('DeleteOldPdfReportsJob: No se encontraron reportes PDF antiguos para eliminar.');
      return;
    }

    $deletedCount = 0;
    $totalSize = 0;
    $errors = [];

    foreach ($oldReports as $report) {
      try {
        if ($report->existsOnDisk()) {
          $fileSize = $report->sizeOnDisk();
          $totalSize += $fileSize;

          if (!$report->deleteFromDisk()) {
            $errors[] = "Error al eliminar archivo: {$report->nombre}";
            Log::warning("DeleteOldPdfReportsJob: Error al eliminar archivo: {$report->nombre}");
            continue;
          }
        }

        $report->markAsExpired();
        $deletedCount++;

        Log::info("DeleteOldPdfReportsJob: Eliminado reporte {$report->nombre} (ID: {$report->id})");
      } catch (\Exception $e) {
        $error = "Error al procesar {$report->nombre}: {$e->getMessage()}";
        $errors[] = $error;
        Log::error("DeleteOldPdfReportsJob: {$error}");
      }
    }

    $totalSizeMB = round($totalSize / 1024 / 1024, 2);

    Log::info("DeleteOldPdfReportsJob completado:", [
      'reportes_eliminados' => $deletedCount,
      'espacio_liberado_mb' => $totalSizeMB,
      'errores_count' => count($errors),
      'horas_antigüedad' => $this->hours,
    ]);

    if (!empty($errors)) {
      Log::warning("DeleteOldPdfReportsJob: Se encontraron errores:", $errors);
    }
  }

  public function failed(\Throwable $exception): void
  {
    Log::error("DeleteOldPdfReportsJob falló:", [
      'error' => $exception->getMessage(),
      'horas_antigüedad' => $this->hours,
      'trace' => $exception->getTraceAsString(),
    ]);
  }
}
