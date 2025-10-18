<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use League\Csv\Writer;
use Storage;

class GenerateCsvTemplates extends Command
{
  protected $signature = 'csv:generate-templates';

  protected $description = 'Genera archivos CSV plantilla para la carga masiva de datos.';

  public const BASE_CSV_TEMPLATES_DIR = 'templates/csv';

  public function handle()
  {
    $allTemplates = config('csv_templates');

    if (empty($allTemplates)) {
      $this->error("No se encontraron plantillas CSV definidas en la configuración 'csv_templates'.");
      return Command::FAILURE;
    }

    $successfulGenerations = 0;
    $failedGenerations = 0;

    $absoluteBaseDir = Storage::path(self::BASE_CSV_TEMPLATES_DIR);

    foreach ($allTemplates as $langCode => $templatesByLang) {
      if (!is_array($templatesByLang) || empty($templatesByLang)) {
        $this->warn("No se encontraron plantillas para el idioma '{$langCode}'.");
        continue;
      }

      foreach ($templatesByLang as $templateKey => $columns) {
        if (!is_array($columns) || empty($columns)) {
          $this->warn("La configuración para la plantilla '{$templateKey}' en el idioma '{$langCode}' no contiene columnas válidas.");
          $failedGenerations++;
          continue;
        }

        $filePath = "{$absoluteBaseDir}/{$langCode}_{$templateKey}_template.csv";

        $directory = dirname($filePath);
        if (!is_dir($directory)) {
          if (!mkdir($directory, 0755, true)) {
            $this->error("No se pudo crear el directorio: {$directory}");
            $failedGenerations++;
            continue;
          }
        }

        try {
          $csv = Writer::createFromPath($filePath, 'w+');

          $csv->insertOne($columns);

          $this->info("Plantilla CSV '{$langCode}_{$templateKey}_template.csv' generada exitosamente: " . $filePath);
          $successfulGenerations++;
        } catch (\Exception $e) {
          $this->error(
            "Error al generar la plantilla CSV '{$templateKey}' en '{$langCode}': " . $e->getMessage()
          );

          $failedGenerations++;
        }
      }
    }

    if ($successfulGenerations > 0) {
      $this->info("Se generaron {$successfulGenerations} plantillas CSV con éxito.");
    }

    if ($failedGenerations > 0) {
      $this->error("Hubo {$failedGenerations} fallas al generar plantillas CSV.");
      return Command::FAILURE;
    }

    return Command::SUCCESS;
  }
}
