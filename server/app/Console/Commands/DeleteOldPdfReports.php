<?php

namespace App\Console\Commands;

use App\Models\ReportePdf;
use Carbon\Carbon;
use Illuminate\Console\Command;

class DeleteOldPdfReports extends Command
{
  protected $signature = 'reports:cleanup-old-pdfs {--hours=24 : Número de horas después de las cuales eliminar los archivos}';

  protected $description = 'Elimina automáticamente los archivos PDF de reportes que han sido actualizados hace más de 24 horas';

  public function handle()
  {
    $hours = $this->option('hours');
    $cutoffTime = Carbon::now()->subHours($hours);

    /** @var \Illuminate\Database\Eloquent\Collection<int, ReportePdf> $oldReports */
    $oldReports = ReportePdf::where('updated_at', '<', $cutoffTime)
      ->whereNotNull('file_path')
      ->get();

    if ($oldReports->isEmpty()) {
      $this->info('No se encontraron reportes PDF antiguos para eliminar.');
      return Command::SUCCESS;
    }

    $deletedCount = 0;
    $totalSize = 0;

    foreach ($oldReports as $report) {
      try {
        if ($report->existsOnDisk()) {
          $fileSize = $report->sizeOnDisk();
          $totalSize += $fileSize;

          $report->deleteFromDisk();

          $this->line("✓ Eliminado: {$report->nombre} (ID: {$report->id})");
        } else {
          $this->warn("⚠ Archivo no encontrado: {$report->file_path}");
        }

        $report->markAsExpired();

        $deletedCount++;
      } catch (\Exception $e) {
        $this->error("✗ Error al eliminar {$report->nombre}: {$e->getMessage()}");
      }
    }

    $totalSizeMB = round($totalSize / 1024 / 1024, 2);

    $this->info("Proceso completado:");
    $this->info("Reportes procesados: {$deletedCount}");
    $this->info("Espacio liberado: {$totalSizeMB} MB");

    return Command::SUCCESS;
  }
}
