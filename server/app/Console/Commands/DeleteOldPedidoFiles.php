<?php

namespace App\Console\Commands;

use App\Models\Pedido;
use App\Services\Disk\PrivateUploadsDiskService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Storage;

class DeleteOldPedidoFiles extends Command
{
  protected $signature = 'pedidos:cleanup-old-files {--semanas=3 : Número de semanas después de la entrega para eliminar archivos}';

  protected $description = 'Elimina automáticamente las fotos y firmas de pedidos entregados hace más de 3 semanas';

  public function handle()
  {
    $semanas = $this->option('semanas');
    $cutoffTime = Carbon::now()->subWeeks($semanas);

    /** @var \Illuminate\Database\Eloquent\Collection<int, Pedido> $oldPedidos */
    $oldPedidos = Pedido::where('fecha_entrega', '<', $cutoffTime)
      ->where(function ($query) {
        $query->whereNotNull('foto_entrega_path')
          ->orWhereNotNull('firma_digital')
          ->orWhereNotNull('firma_documento_consentimiento');
      })
      ->get();

    if ($oldPedidos->isEmpty()) {
      $this->info('No se encontraron pedidos antiguos con archivos para eliminar.');
      return Command::SUCCESS;
    }

    $deletedFilesCount = 0;
    $totalSize = 0;
    $processedPedidosCount = 0;
    $errors = 0;
    $privateUploadsDisk = Storage::disk(PrivateUploadsDiskService::DISK_NAME);

    $this->info("Encontrados {$oldPedidos->count()} pedidos con archivos para procesar...");

    $progressBar = $this->output->createProgressBar($oldPedidos->count());
    $progressBar->start();

    foreach ($oldPedidos as $pedido) {
      try {
        $pedidoFilesDeleted = 0;
        $pedidoSize = 0;
        $filesToUpdate = [];

        if ($pedido->foto_entrega_path !== null) {
          if ($privateUploadsDisk->exists($pedido->foto_entrega_path)) {
            $fileSize = $privateUploadsDisk->size($pedido->foto_entrega_path);

            if (PrivateUploadsDiskService::delete($pedido->foto_entrega_path)) {
              $pedidoSize += $fileSize;
              $pedidoFilesDeleted++;
              $filesToUpdate['foto_entrega_path'] = null;
            } else {
              $this->newLine();
              $this->error("✗ Error al eliminar foto de entrega del pedido {$pedido->id}");
              $errors++;
              continue;
            }
          } else {
            $filesToUpdate['foto_entrega_path'] = null;
          }
        }

        if ($pedido->firma_digital !== null) {
          $filesToUpdate['firma_digital'] = null;
        }

        if ($pedido->firma_documento_consentimiento !== null) {
          $filesToUpdate['firma_documento_consentimiento'] = null;
        }

        if (!empty($filesToUpdate)) {
          $pedido->update($filesToUpdate);
          $processedPedidosCount++;
          $deletedFilesCount += $pedidoFilesDeleted;
          $totalSize += $pedidoSize;
        }
      } catch (\Exception $e) {
        $this->newLine();
        $this->error("✗ Error al procesar pedido {$pedido->id}: {$e->getMessage()}");
        $errors++;
      }

      $progressBar->advance();
    }

    $progressBar->finish();
    $this->newLine(2);

    $totalSizeMB = round($totalSize / 1024 / 1024, 2);

    $this->info("Proceso completado:");
    $this->info("Pedidos procesados: {$processedPedidosCount}");
    $this->info("Archivos eliminados: {$deletedFilesCount}");
    $this->info("Espacio liberado: {$totalSizeMB} MB");

    if ($errors > 0) {
      $this->warn("Errores encontrados: {$errors}");
    }

    return Command::SUCCESS;
  }
}
