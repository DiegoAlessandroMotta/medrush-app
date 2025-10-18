<?php

namespace App\Helpers;

class NotificationMessageBuilder
{
  /**
   * Construye el mensaje Markdown para resultados exitosos del procesamiento CSV.
   *
   * @param int $processedRecords
   * @param int $successRecords
   * @return string
   */
  public static function buildCsvSuccessMessage(int $processedRecords, int $successRecords): string
  {
    return <<<MARKDOWN
¡Excelente! Tu archivo CSV ha sido procesado **exitosamente**.

*   **Registros procesados:** {$processedRecords}
*   **Registros importados:** {$successRecords}

Todo listo. ¡Gracias por usar nuestra plataforma!
MARKDOWN;
  }

  /**
   * Construye el mensaje Markdown para resultados parciales del procesamiento CSV (con errores).
   *
   * @param int $processedRecords
   * @param int $successRecords
   * @param int $failedRecords
   * @param array $errorDetails Detalles de los errores. Cada error debe ser un array con 'row', 'message', etc.
   * @return string
   */
  public static function buildCsvWarningMessage(
    int $processedRecords,
    int $successRecords,
    int $failedRecords,
    array $errorDetails
  ): string {
    $errorListMarkdown = '';
    if (!empty($errorDetails)) {
      $displayLimit = 5;
      $errorsToDisplay = array_slice($errorDetails, 0, $displayLimit);

      foreach ($errorsToDisplay as $error) {
        $row = $error['row'] ?? 'N/A';
        $message = $error['message'] ?? 'Error desconocido';
        $details = $error['details'] ?? null;

        $errorLine = "- Fila {$row}: {$message}";
        if ($details) {
          $errorLine .= " ({$details})";
        }
        $errorListMarkdown .= $errorLine . "\n";
      }

      if (count($errorDetails) > $displayLimit) {
        $remainingErrors = count($errorDetails) - $displayLimit;
        $errorListMarkdown .= "\n... y **{$remainingErrors}** errores más. Revisa el log o contacta a soporte para más detalles.";
      }
    } else {
      $errorListMarkdown = "No se encontraron detalles específicos de los errores, por favor, contacta a soporte.";
    }


    return <<<MARKDOWN
¡Atención! Tu archivo CSV fue procesado, pero se encontraron algunos **errores**.

*   **Registros procesados:** {$processedRecords}
*   **Registros importados:** {$successRecords}
*   **Registros con errores:** {$failedRecords}

**Detalles de los errores más relevantes:**
{$errorListMarkdown}

Por favor, revisa los registros con errores para corregirlos.
MARKDOWN;
  }

  /**
   * Construye el mensaje Markdown para errores críticos en el procesamiento CSV.
   *
   * @param string $supportContactInfo Información de contacto de soporte (e.g., email, teléfono, URL).
   * @return string
   */
  public static function buildCsvErrorMessage(string $supportContactInfo = 'nuestro equipo de soporte'): string
  {
    return <<<MARKDOWN
¡Error crítico!

No pudimos procesar tu archivo CSV debido a un problema inesperado.

*   No se pudo importar ningún registro.
*   Por favor, verifica el formato de tu archivo y vuelve a intentarlo.

Si el problema persiste, contacta a {$supportContactInfo} para asistencia.
MARKDOWN;
  }

  /**
   * @param string $reportId ID del reporte (si aplica)
   * @param string $reportUrl URL para descargar el reporte de errores (si aplica)
   * @return string
   */
  public static function buildCsvProcessingReportLink(string $reportId, string $reportUrl): string
  {
    return <<<MARKDOWN
Puedes descargar un informe detallado de este procesamiento aquí:
[Reporte #{$reportId}]({$reportUrl})
MARKDOWN;
  }
}
