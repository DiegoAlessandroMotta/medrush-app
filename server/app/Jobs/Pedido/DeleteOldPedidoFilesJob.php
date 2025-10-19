<?php

namespace App\Jobs\Pedido;

use App\Models\Pedido;
use App\Services\Disk\PrivateUploadsDiskService;
use Carbon\Carbon;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Log;
use Storage;

class DeleteOldPedidoFilesJob implements ShouldQueue
{
  use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

  public $tries = 2;
  public $timeout = 600;

  private int $weeks;

  public function __construct(int $weeks = 3)
  {
    $this->weeks = $weeks;
  }

  public function handle(): void
  {
    $cutoffTime = Carbon::now()->subWeeks($this->weeks);

    /** @var \Illuminate\Database\Eloquent\Collection<int, Pedido> $oldPedidos */
    $oldPedidos = Pedido::where('fecha_entrega', '<', $cutoffTime)
      ->where(function ($query) {
        $query->whereNotNull('foto_entrega_path')
          ->orWhereNotNull('firma_digital')
          ->orWhereNotNull('firma_documento_consentimiento');
      })
      ->get();

    if ($oldPedidos->isEmpty()) {
      Log::info('DeleteOldPedidoFilesJob: No se encontraron pedidos antiguos con archivos para eliminar.');
      return;
    }

    $deletedFilesCount = 0;
    $totalSize = 0;
    $processedPedidosCount = 0;
    $errors = [];

    foreach ($oldPedidos as $pedido) {
      try {
        $pedidoFilesDeleted = 0;
        $pedidoSize = 0;
        $filesToUpdate = [];

        if ($pedido->foto_entrega_path !== null) {
          $privateUploadsDisk = Storage::disk(PrivateUploadsDiskService::DISK_NAME);

          if ($privateUploadsDisk->exists($pedido->foto_entrega_path)) {
            $fileSize = $privateUploadsDisk->size($pedido->foto_entrega_path);

            if (PrivateUploadsDiskService::delete($pedido->foto_entrega_path)) {
              $pedidoSize += $fileSize;
              $pedidoFilesDeleted++;
              $filesToUpdate['foto_entrega_path'] = null;
            } else {
              $errors[] = "Error al eliminar foto de entrega del pedido {$pedido->id}";
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
        $error = "Error al procesar pedido {$pedido->id}: {$e->getMessage()}";
        $errors[] = $error;
        Log::error("DeleteOldPedidoFilesJob: {$error}");
      }
    }

    $totalSizeMB = round($totalSize / 1024 / 1024, 2);

    Log::info("DeleteOldPedidoFilesJob completado:", [
      'pedidos_procesados' => $processedPedidosCount,
      'archivos_eliminados' => $deletedFilesCount,
      'espacio_liberado_mb' => $totalSizeMB,
      'errores_count' => count($errors),
      'semanas_antigüedad' => $this->weeks,
    ]);

    if (!empty($errors)) {
      Log::warning("DeleteOldPedidoFilesJob: Se encontraron errores:", $errors);
    }
  }

  public function failed(\Throwable $exception): void
  {
    Log::error("DeleteOldPedidoFilesJob falló:", [
      'error' => $exception->getMessage(),
      'semanas_antigüedad' => $this->weeks,
      'trace' => $exception->getTraceAsString(),
    ]);
  }
}
