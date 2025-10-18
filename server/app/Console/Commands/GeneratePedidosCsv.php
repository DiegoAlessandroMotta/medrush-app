<?php

namespace App\Console\Commands;

use App\Casts\AsPoint;
use App\Enums\TiposPedidoEnum;
use App\Helpers\GeoHelper;
use App\Models\Farmacia;
use Faker\Factory as FakerFactory;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use League\Csv\Writer;

class GeneratePedidosCsv extends Command
{
  protected $signature = 'generate:pedidos-csv {count=10000 : The number of records to generate} {--filename=pedidos.csv : The name of the output CSV file}';
  protected $description = 'Generates a CSV file with dummy order data.';

  public function handle()
  {
    $count = (int) $this->argument('count');
    $filename = $this->option('filename');
    $faker = FakerFactory::create('es_PE');

    $this->info("Generando {$count} registros de pedidos con League\Csv...");

    /** @var Farmacia $farmacia */
    $farmacia = Farmacia::first() ?? Farmacia::factory()->create();

    $headers = [
      'paciente_nombre',
      'paciente_telefono',
      'paciente_email',
      'direccion_entrega_linea_1',
      'direccion_entrega_linea_2',
      'ciudad_entrega',
      'estado_region_entrega',
      'codigo_postal_entrega',
      'ubicacion_entrega',
      'ubicacion_recojo',
      'codigo_acceso_edificio',
      'medicamentos',
      'tipo_pedido',
      'observaciones',
      'requiere_firma_especial',
    ];

    $fullPath = Storage::disk('temp')->path($filename);

    // --- CAMBIO CLAVE: Usar League\Csv\Writer ---

    // 1. Crear una instancia de Writer
    // Es mejor crear el Writer a partir de la ruta del archivo directamente
    // o de un stream. Aquí usamos la ruta para escribir directamente al disco.
    try {
      $csv = Writer::createFromPath($fullPath, 'w+'); // 'w+' para crear/truncar y permitir lectura (si se necesitara)
    } catch (\Exception $e) {
      $this->error('No se pudo crear el Writer CSV: ' . $e->getMessage());
      return Command::FAILURE;
    }


    // 2. Configurar el Writer (delimitador, encapsulador, escape)
    // League\Csv ya tiene estos defaults, pero es buena práctica especificarlos
    $csv->setDelimiter(',');
    $csv->setEnclosure('"');
    $csv->setEscape('\\');

    // 3. Escribir los encabezados
    $csv->insertOne($headers);

    // Datos pre-calculados fuera del bucle
    $ubicacionRecojoString = $this->locationStringFromArray(AsPoint::serializeValue($farmacia->ubicacion));
    $medicamentosOptions = [
      'Paracetamol 500mg - 2 cajas de tabletas',
      'Ibuprofeno 400mg - 1 caja de tabletas, Omeprazol 20mg - 1 caja',
      'Amoxicilina 500mg - 1 caja + Paracetamol 500mg - 1 caja',
      'Losartán 50mg - 30 tabletas',
      'Metformina 850mg - 2 cajas, Atorvastatina 1 caja',
      'Diclofenaco 50mg - 1 caja, Ranitidina 300mg - 1 caja',
      'Naproxeno 550mg - 1 caja + Omeprazol 20mg - 14 cápsulas',
      'Azitromicina 500mg - 3 tabletas',
      'Dexametasona 4mg - 1 caja + Loratadina 10mg - 1 caja',
    ];
    $ciudadesEntregaOptions = [
      'San Isidro',
      'Miraflores',
      'San Borja',
      'Surco',
      'La Molina',
      'Jesús María',
      'Lince',
      'San Miguel',
      'Magdalena',
      'Pueblo Libre',
    ];

    // --- Generador para producir las filas de datos ---
    // Esto es muy eficiente porque los datos se generan y se envían a League\Csv
    // de uno en uno, sin cargar todas las 20,000 filas en memoria.
    $dataGenerator = function (
      int $count,
      \Faker\Generator $faker,
      array $medicamentosOptions,
      array $ciudadesEntregaOptions,
      string $ubicacionRecojoString,
      array $headers
    ) {
      for ($i = 0; $i < $count; $i++) {
        $randomLocation = GeoHelper::generateRandomPointInRadius();
        $medicamentos = $faker->randomElement($medicamentosOptions);

        $rowData = [
          'paciente_nombre' => $faker->name(),
          'paciente_telefono' => '+51' . $faker->numerify('#########'),
          'paciente_email' => $faker->optional(0.7)->safeEmail(),
          'direccion_entrega_linea_1' => $faker->streetAddress,
          'direccion_entrega_linea_2' => $faker->optional(0.6)->secondaryAddress,
          'ciudad_entrega' => $faker->randomElement($ciudadesEntregaOptions),
          'estado_region_entrega' => 'Lima',
          'codigo_postal_entrega' => $faker->numberBetween(1, 51),
          'ubicacion_entrega' => $this->locationStringFromArray($randomLocation),
          'ubicacion_recojo' => $ubicacionRecojoString,
          'codigo_acceso_edificio' => $faker->optional(0.3)->numerify('######'),
          'medicamentos' => str_replace("\n", ' ', $medicamentos),
          'tipo_pedido' => $faker->randomElement(TiposPedidoEnum::cases())->value,
          'observaciones' => $faker->optional(0.4)->sentence(),
          'requiere_firma_especial' => $faker->boolean(20) ? 'true' : 'false',
        ];

        // Mapear los datos al orden de los encabezados
        $orderedData = [];
        foreach ($headers as $header) {
          $orderedData[] = $rowData[$header] ?? '';
        }
        yield $orderedData;
      }
    };

    // 4. Escribir todas las filas usando el generador
    // insertAll() puede recibir un array, un Traversable o un Generator.
    // Esto es increíblemente eficiente para grandes conjuntos de datos.
    $rowsWritten = 0;
    foreach (
      $dataGenerator(
        $count,
        $faker,
        $medicamentosOptions,
        $ciudadesEntregaOptions,
        $ubicacionRecojoString,
        $headers
      ) as $dataRow
    ) {
      $csv->insertOne($dataRow); // Escribir una fila a la vez
      $rowsWritten++; // Incrementar el contador de filas
      if ($rowsWritten % 1000 === 0) {
        $this->info("Generados " . $rowsWritten . " registros...");
      }
    }

    $this->info("Archivo CSV generado exitosamente en: " . $fullPath);
    $this->info("Se escribieron {$rowsWritten} filas.");
    return Command::SUCCESS;
  }

  /**
   * Convierte un array de latitud/longitud a una cadena "latitud,longitud".
   *
   * @param array{latitude: float, longitude: float} $location
   * @return string
   */
  private function locationStringFromArray(array $location): string
  {
    return $location['latitude'] . ',' . $location['longitude'];
  }
}
