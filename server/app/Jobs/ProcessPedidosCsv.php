<?php

namespace App\Jobs;

use App\Casts\AsPoint;
use App\Exceptions\Jobs\JobException;
use App\Helpers\OrderCodeGenerator;
use App\Models\Farmacia;
use App\Models\Pedido;
use App\Models\User;
use App\Notifications\CsvProcessingResultNotification;
use App\Validators\CsvPedidoRowValidator;
use Exception;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Collection;
use League\Csv\Reader;
use NotificationChannels\Fcm\FcmChannel;
use Str;
use Validator;

class ProcessPedidosCsv implements ShouldQueue
{
  use Dispatchable, Queueable, SerializesModels;

  public $tries = 2;
  public $timeout = 300;

  protected string $filePath;
  protected string $userId;
  protected string $farmaciaId;
  protected int $chunkSize;
  protected CsvPedidoRowValidator $rowValidator;

  public function __construct(
    string $filePath,
    string $userId,
    string $farmaciaId,
    ?int $chunkSize = 256
  ) {
    $this->filePath = $filePath;
    $this->userId = $userId;
    $this->farmaciaId = $farmaciaId;
    $this->chunkSize = $chunkSize;
    $this->rowValidator = new CsvPedidoRowValidator();
  }

  public function handle(): void
  {
    try {
      \Log::debug('Iniciando el procesamiento. - Memoria actual (MB): ' . round(memory_get_usage(true) / (1024 * 1024), 2));

      if (!file_exists($this->filePath)) {
        \Log::error('Archivo CSV no encontrado.', [
          'file_path' => $this->filePath,
          'errors' => 'file ' . $this->filePath . ' was not found.',
          'userId' => $this->userId,
        ]);

        $this->notifyUserOfError('General', ['file_path' => 'El archivo CSV no fue encontrado.']);
        return;
      }

      $farmaciaValidator = Validator::make(
        ['farmacia_id' => $this->farmaciaId],
        ['farmacia_id' => ['required', 'uuid']],
      );

      /** @var Farmacia|null $farmacia */
      $farmacia = Farmacia::find($this->farmaciaId);

      if ($farmaciaValidator->failed() || $farmacia === null) {
        $errorsArray = $farmaciaValidator->errors()->toArray();
        if (sizeof($errorsArray) === 0) {
          $errorsArray = ['farmacia_id' => 'La farmacia proporcionada no existe.'];
        }

        \Log::error('El ID de la farmacia proporcionado no es válido o la farmacia no existe.', [
          'farmacia_id' => $this->farmaciaId,
          'errors' => $farmaciaValidator->errors()->toArray(),
        ]);

        $this->notifyUserOfError('General', $errorsArray);

        if (file_exists($this->filePath)) {
          unlink($this->filePath);
        }

        return;
      }

      $csv = Reader::createFromPath($this->filePath, 'r');
      $csv->setHeaderOffset(0);

      $errors = [];
      $totalCreatedCount = 0;

      $processedRecords = 0;
      $csvRowIndex = 2;
      $validatedRecords = new Collection();

      $model = new Pedido();

      foreach ($csv->getIterator() as $indexInChunk => $record) {
        $processedRecords++;

        $validator = $this->rowValidator->validate($record);

        if ($validator->fails()) {
          $errors[] = [
            'row' => $csvRowIndex,
            'messages' => $validator->errors()->toArray(),
          ];
        } else {
          $validatedData = $validator->validated();

          $validatedData['id'] = Str::orderedUuid();

          $validatedData['codigo_barra'] = OrderCodeGenerator::generateOrderCode(
            offset: $csvRowIndex,
          );

          if ($validatedData['ubicacion_recojo'] !== null) {
            $validatedData['ubicacion_recojo'] = AsPoint::toRawExpression(AsPoint::pointFromArray($validatedData['ubicacion_recojo']));
          } else {
            $validatedData['ubicacion_recojo'] = AsPoint::toRawExpression($farmacia->ubicacion);
          }

          $validatedData['ubicacion_entrega'] = AsPoint::toRawExpression(AsPoint::pointFromArray($validatedData['ubicacion_entrega']));

          $validatedData['farmacia_id'] = $this->farmaciaId;

          $validatedData['codigo_iso_pais_entrega'] = $farmacia->codigo_iso_pais->value;

          $validatedRecords->push($validatedData);
        }

        $csvRowIndex++;

        if ($validatedRecords->count() >= $this->chunkSize) {
          \Log::debug("Fila {$processedRecords}: Memoria actual (MB): " . round(memory_get_usage(true) / (1024 * 1024), 2));

          $totalCreatedCount += $this->insertValidatedRecords(
            $validatedRecords,
            $errors,
            $csvRowIndex - $validatedRecords->count()
          );

          $validatedRecords = new Collection();
        }
      }

      if ($validatedRecords->isNotEmpty()) {
        \Log::debug("Fila {$csvRowIndex}: Memoria actual (MB): " . round(memory_get_usage(true) / (1024 * 1024), 2));
        $totalCreatedCount += $this->insertValidatedRecords(
          $validatedRecords,
          $errors,
          $csvRowIndex - $validatedRecords->count()
        );
      }

      $this->finalizeProcessing($errors, $totalCreatedCount, $processedRecords);
    } catch (\Throwable $e) {
      if ($e instanceof JobException) {
        return;
      }

      throw $e;
    }
  }

  private function insertValidatedRecords(
    Collection $records,
    array &$errors,
    int $startingCsvRowIndex
  ): int {
    $insertedCount = 0;

    try {
      $dataToInsert = $records->map(function ($record) {
        $now = now();
        return array_merge($record, [
          'created_at' => $now,
          'updated_at' => $now,
        ]);
      })->toArray();

      Pedido::insert($dataToInsert);
      $insertedCount = count($dataToInsert);
    } catch (Exception $e) {
      \Log::error('Error masivo al insertar pedidos en la base de datos.', [
        'exception' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
        'records_count' => $records->count(),
        'first_record_sample' => $records->first(),
      ]);

      $records->each(function ($record, $offset) use (
        &$errors,
        $startingCsvRowIndex,
        $e
      ) {
        $errors[] = [
          'row' => $startingCsvRowIndex + $offset,
          'messages' => [
            'general' =>
            'Error al guardar en la base de datos (parte de un lote): ' .
              $e->getMessage(),
          ],
        ];
      });

      throw new Exception('Unexpected error when trying to insert a chunk of data');
    }

    return $insertedCount;
  }

  private function finalizeProcessing(array $errors, int $totalCreatedCount, int $processedRecords): void
  {
    if (!empty($errors)) {
      \Log::error('Errores al procesar CSV de pedidos para usuario ' . $this->userId, [
        'file_path' => $this->filePath,
        'errors_summary' => count($errors) . ' errores encontrados.',
        'errors' => $errors,
        'userId' => $this->userId,
      ]);
    } else {
      \Log::info(
        "CSV de pedidos procesado para usuario {$this->userId}: {$totalCreatedCount} pedidos creados."
      );
    }

    $this->notifyUser(
      processedRecords: $processedRecords,
      successRecords: $totalCreatedCount,
      failedRecords: count($errors),
      errorDetails: $errors,
    );

    if (file_exists($this->filePath)) {
      unlink($this->filePath);
    }
  }

  /**
   * Helper method to send notification to user.
   */
  private function notifyUser(
    ?int $processedRecords = null,
    ?int $successRecords = null,
    ?int $failedRecords = null,
    ?array $errorDetails = null,
    array $channels = [FcmChannel::class, 'database'],
  ): void {
    /** @var User|null $user */
    $user = User::find($this->userId);
    $user?->notify(new CsvProcessingResultNotification(
      channels: $channels,
      processedRecords: $processedRecords,
      successRecords: $successRecords,
      failedRecords: $failedRecords,
      errorDetails: $errorDetails,
    ));
  }

  /**
   * Helper method to send a simple error notification to user.
   */
  private function notifyUserOfError(string $row, array $messages): void
  {
    $this->notifyUser(
      errorDetails: [
        [
          'row' => $row,
          'messages' => $messages,
        ]
      ]
    );
  }
}
