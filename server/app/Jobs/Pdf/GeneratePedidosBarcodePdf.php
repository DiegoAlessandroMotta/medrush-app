<?php

namespace App\Jobs\Pdf;

use App\Exceptions\Jobs\JobException;
use App\Factories\NotificationDataDtoFactory;
use App\Models\Pedido;
use App\Models\ReportePdf;
use App\Models\User;
use App\Notifications\ReportePdfCreadoNotification;
use Barryvdh\DomPDF\Facade\Pdf;
use Exception;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Collection;
use Log;
use Milon\Barcode\Facades\DNS1DFacade;
use Throwable;

class GeneratePedidosBarcodePdf implements ShouldQueue
{
  use Dispatchable, Queueable;

  public $tries = 2;

  private string $reportePdfId;

  private ?ReportePdf $cachedReportePdf = null;
  private ?User $cachedUser = null;
  private ?Collection $cachedPedidos = null;

  public function __construct(
    string $reportePdfId,
  ) {
    $this->reportePdfId = $reportePdfId;
  }

  public function handle(): void
  {
    $filePath = null;

    try {
      $reportePdf = $this->getReportePdfOrFail();
      $user = $this->getUserOrFail();
      $pedidos = $this->getPedidos();

      if ($pedidos === null || $pedidos->isEmpty()) {
        throw new JobException(
          message: 'No se encontraron pedidos para generar el PDF de códigos de barras',
          details: [
            'reporte_id' => $reportePdf->id,
            'pedidos_solicitados' => count($reportePdf->pedidos),
            'pedidos_encontrados' => 0,
          ]
        );
      }

      $pagesData = [];
      $totalPaginas = 0;

      foreach ($pedidos as $pedido) {
        try {
          $barcodePng = DNS1DFacade::getBarcodePNG($pedido->codigo_barra, 'C128', 2, 60);
          $pagesData[] = [
            'id' => $pedido->id,
            'codigo_barra' => $pedido->codigo_barra,
            'paciente_nombre' => $pedido->paciente_nombre,
            'direccion_entrega_linea_1' => $pedido->direccion_entrega_linea_1,
            'nombre_repartidor' => $pedido->repartidor?->user?->name ?? '',
            'codigo_barra_url' => 'data:image/png;base64,' . $barcodePng,
          ];
          $totalPaginas++;
        } catch (Throwable $barcodeError) {
          Log::error('Error generando código de barras para pedido', [
            'pedido_id' => $pedido->id,
            'codigo_barra' => $pedido->codigo_barra,
            'error' => $barcodeError->getMessage(),
            'trace' => $barcodeError->getTraceAsString(),
          ]);
          throw new JobException(
            message: "Error al generar código de barras para el pedido {$pedido->codigo_barra}",
            details: [
              'pedido_id' => $pedido->id,
              'error' => $barcodeError->getMessage(),
            ],
            previous: $barcodeError
          );
        }
      }

      try {
        $pdf = Pdf::loadView('pdf.pedido-page', ['pagesData' => $pagesData])
          ->setPaper($reportePdf->page_size->value, 'portrait');
      } catch (Throwable $pdfError) {
        Log::error('Error cargando vista PDF', [
          'reporte_id' => $reportePdf->id,
          'error' => $pdfError->getMessage(),
          'trace' => $pdfError->getTraceAsString(),
        ]);
        throw new JobException(
          message: 'Error al generar el PDF desde la vista',
          details: [
            'reporte_id' => $reportePdf->id,
            'error' => $pdfError->getMessage(),
          ],
          previous: $pdfError
        );
      }

      try {
        $pdfOutput = $pdf->output();
        $filePath = ReportePdf::saveToDisk($reportePdf->nombre, $pdfOutput);
        
        if ($filePath === null) {
          throw new JobException(
            message: 'No se pudo guardar el archivo PDF en disco',
            details: [
              'reporte_id' => $reportePdf->id,
              'nombre' => $reportePdf->nombre,
            ]
          );
        }

        $fileSize = ReportePdf::getDiskInstance()->size($filePath);
      } catch (Throwable $saveError) {
        Log::error('Error guardando PDF en disco', [
          'reporte_id' => $reportePdf->id,
          'error' => $saveError->getMessage(),
          'trace' => $saveError->getTraceAsString(),
        ]);
        throw new JobException(
          message: 'Error al guardar el PDF en disco',
          details: [
            'reporte_id' => $reportePdf->id,
            'error' => $saveError->getMessage(),
          ],
          previous: $saveError
        );
      }

      $reportePdf->markAsCreated($filePath, $fileSize, $totalPaginas);

      $this->sendSuccessNotification($user, $reportePdf);
    } catch (Throwable $e) {
      if ($filePath !== null && ReportePdf::getDiskInstance()->exists($filePath)) {
        try {
          ReportePdf::getDiskInstance()->delete($filePath);
        } catch (Throwable $deleteError) {
          Log::warning('No se pudo eliminar archivo temporal después de error', [
            'file_path' => $filePath,
            'error' => $deleteError->getMessage(),
          ]);
        }
      }

      Log::error('Error en GeneratePedidosBarcodePdf::handle()', [
        'reporte_id' => $this->reportePdfId,
        'error_message' => $e->getMessage(),
        'error_class' => get_class($e),
        'trace' => $e->getTraceAsString(),
      ]);

      if ($e instanceof JobException) {
        throw $e;
      }

      throw new JobException(
        message: 'Error inesperado al generar el PDF',
        details: [
          'reporte_id' => $this->reportePdfId,
          'error' => $e->getMessage(),
        ],
        previous: $e
      );
    }
  }

  public function failed(?Exception $exception): void
  {
    try {
      $reportePdf = $this->getReportePdf();

      if (!$reportePdf) {
        $this->logFailedMethodError('ReportePdf no encontrado al procesar fallo del job', $exception);
        return;
      }

      $reportePdf->markAsFailed();

      $user = $this->getUser();

      if (!$user) {
        $this->logFailedMethodError('Usuario no encontrado al intentar enviar notificación de fallo', $exception, [
          'user_id' => $reportePdf->user_id,
        ]);
        return;
      }

      $this->sendFailureNotification($user, $exception);
    } catch (Exception $e) {
      Log::error('Error crítico al manejar fallo del job GeneratePedidosBarcodePdf', [
        'reportePdfId' => $this->reportePdfId,
        'job' => self::class,
        'error_failed_method' => $e->getMessage(),
        'error_original' => $exception?->getMessage(),
        'trace' => $e->getTraceAsString(),
      ]);
    }
  }

  private function logFailedMethodError(string $message, ?Exception $originalException, array $extraContext = []): void
  {
    Log::error("Error en failed(): {$message}", array_merge([
      'reportePdfId' => $this->reportePdfId,
      'job' => self::class,
      'error_original' => $originalException?->getMessage(),
    ], $extraContext));
  }

  private function getReportePdf(): ?ReportePdf
  {
    if ($this->cachedReportePdf === null) {
      $this->cachedReportePdf = ReportePdf::find($this->reportePdfId);
    }

    return $this->cachedReportePdf;
  }

  private function getReportePdfOrFail(): ReportePdf
  {
    $reportePdf = $this->getReportePdf();

    if (!$reportePdf) {
      $this->logModelNotFound('ReportePdf', [
        'reporte_pdf_id' => $this->reportePdfId,
      ]);

      throw new JobException(
        message: 'El reporte solicitado no existe o fue eliminado',
        details: [
          'reporte_id' => $this->reportePdfId,
        ]
      );
    }

    return $reportePdf;
  }

  private function getUserOrFail(): User
  {
    $user = $this->getUser();
    $reportePdf = $this->getReportePdf();

    if (!$user) {
      $this->logModelNotFound('Usuario', [
        'user_id' => $reportePdf?->user_id,
        'reporte_pdf_id' => $this->reportePdfId,
      ]);

      throw new JobException(
        message: 'El usuario asociado al reporte no existe',
        details: [
          'reporte_id' => $this->reportePdfId,
          'user_id' => $reportePdf?->user_id,
        ]
      );
    }

    return $user;
  }

  private function logModelNotFound(string $modelName, array $context = []): void
  {
    Log::error("{$modelName} no encontrado para generar PDF de códigos de barras", array_merge([
      'job' => self::class,
    ], $context));
  }

  private function getUser(): ?User
  {
    if ($this->cachedUser === null) {
      $reportePdf = $this->getReportePdf();
      if ($reportePdf) {
        $this->cachedUser = User::find($reportePdf->user_id);
      }
    }

    return $this->cachedUser;
  }

  private function getPedidos(): ?Collection
  {
    if ($this->cachedPedidos === null) {
      $reportePdf = $this->getReportePdf();
      if ($reportePdf) {
        $pedidosIds = $reportePdf->pedidos;
        $this->cachedPedidos = Pedido::whereIn('id', $pedidosIds)
          ->with(['repartidor', 'repartidor.user'])
          ->get();
      }
    }

    return $this->cachedPedidos;
  }

  private function sendSuccessNotification(User $user, ReportePdf $reportePdf): void
  {
    $notificationData = NotificationDataDtoFactory::success(
      title: 'PDF Generado',
      message: "Tu reporte de etiquetas de pedidos está listo para descargar.",
      details: [
        'reporte_id' => $reportePdf->id,
        'archivo' => $reportePdf->nombre,
        'cantidad_pedidos' => $reportePdf->pedidosCount(),
        'paginas' => $reportePdf->paginas,
        'tamaño_archivo' => $reportePdf->getReadableFileSize(),
      ]
    );

    $user->notify(new ReportePdfCreadoNotification($notificationData));
  }

  private function sendFailureNotification(
    User $user,
    ?Exception $exception,
  ): void {
    $notificationData = null;

    if ($exception instanceof JobException) {
      $notificationData = $exception->toNotification('Error al generar PDF');
    }

    $user->notify(new ReportePdfCreadoNotification(
      $notificationData ??
        NotificationDataDtoFactory::error(
          title: 'Error al generar PDF',
          message: 'Hubo un problema al generar tu reporte de etiquetas.',
        )
    ));
  }
}
