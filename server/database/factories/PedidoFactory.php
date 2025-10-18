<?php

namespace Database\Factories;

use App\Casts\AsPoint;
use App\Enums\CodigosIsoPaisEnum;
use App\Enums\EstadosPedidoEnum;
use App\Enums\EventosPedidoEnum;
use App\Enums\MotivosFalloPedidoEnum;
use App\Enums\TiposPedidoEnum;
use App\Helpers\GeoHelper;
use App\Helpers\OrderCodeGenerator;
use App\Models\EventoPedido;
use App\Models\Farmacia;
use App\Models\Pedido;
use App\Models\PerfilRepartidor;
use Faker\Factory as FakerFactory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Pedido>
 */
class PedidoFactory extends Factory
{
  protected $model = Pedido::class;

  public function definition(): array
  {
    $faker = FakerFactory::create('es_PE');

    /** @var Farmacia $farmacia */
    $farmacia = Farmacia::first() ?? Farmacia::factory()->create();
    $randomLocation = GeoHelper::generateRandomPointInRadius();

    $medicamentos = $faker->randomElement([
      'Paracetamol 500mg - 2 cajas de tabletas',
      'Ibuprofeno 400mg - 1 caja de tabletas, Omeprazol 20mg - 1 caja',
      'Amoxicilina 500mg - 1 caja + Paracetamol 500mg - 1 caja',
      'Losartán 50mg - 30 tabletas',
      'Metformina 850mg - 2 cajas, Atorvastatina 20mg - 1 caja',
      'Diclofenaco 50mg - 1 caja, Ranitidina 300mg - 1 caja',
      'Naproxeno 550mg - 1 caja + Omeprazol 20mg - 14 cápsulas',
      'Azitromicina 500mg - 3 tabletas',
      'Dexametasona 4mg - 1 caja + Loratadina 10mg - 1 caja'
    ]);

    $tipoPedido = $faker->randomElement([
      'medicamentos',
      'insumos_medicos',
      'equipos_medicos',
      'medicamentos_controlados',
    ]);

    return [
      'codigo_barra' => OrderCodeGenerator::generateOrderCode(),
      'farmacia_id' => $farmacia->id,
      'repartidor_id' => null,
      'paciente_nombre' => $faker->name(),
      'paciente_telefono' => '+51' . $faker->numerify('#########'),
      'paciente_email' => $faker->optional(0.7)->safeEmail(),
      'codigo_iso_pais_entrega' => CodigosIsoPaisEnum::PERU,
      'direccion_entrega_linea_1' => $faker->streetAddress,
      'direccion_entrega_linea_2' => $faker->optional(0.6)->secondaryAddress,
      'ciudad_entrega' => $faker->randomElement([
        'San Isidro',
        'Miraflores',
        'San Borja',
        'Surco',
        'La Molina',
        'Jesús María',
        'Lince',
        'San Miguel',
        'Magdalena',
        'Pueblo Libre'
      ]),
      'estado_region_entrega' => 'Lima',
      'codigo_postal_entrega' => $faker->numberBetween(1, 51),
      'ubicacion_recojo' => $farmacia->ubicacion,
      'ubicacion_entrega' => AsPoint::pointFromArray($randomLocation),
      'codigo_acceso_edificio' => $faker->optional(0.3)->numerify('######'),
      'tipo_pedido' => $tipoPedido,
      'medicamentos' => $medicamentos,
      'observaciones' => $faker->optional(0.4)->sentence(),
      'requiere_firma_especial' => $faker->boolean(20),
      'estado' => EstadosPedidoEnum::PENDIENTE,
      'motivo_fallo' => null,
      'observaciones_fallo' => null,
      'firma_digital' => null,
      'foto_entrega_path' => null,
      'firma_documento_consentimiento' => null,
      'fecha_asignacion' => null,
      'fecha_recogida' => null,
      'fecha_entrega' => null,
      'tiempo_entrega_estimado' => $faker->numberBetween(20, 60),
      'distancia_estimada' => $faker->randomFloat(2, 0.5, 8.0),
    ];
  }

  public function pendiente(): static
  {
    return $this->state(
      fn(array $attributes) => [
        'estado' => EstadosPedidoEnum::PENDIENTE,
        'repartidor_id' => null,
        'fecha_asignacion' => null,
        'fecha_recogida' => null,
        'fecha_entrega' => null,
        'motivo_fallo' => null,
        'observaciones_fallo' => null,
      ]
    );
  }

  public function asignado(): static
  {
    return $this->state(function (array $attributes) {
      $repartidorId = $attributes['repartidor_id'] ?? (PerfilRepartidor::first() ?? PerfilRepartidor::factory()->create())->id;

      return [
        'estado' => EstadosPedidoEnum::ASIGNADO,
        'repartidor_id' => $repartidorId,
        'fecha_asignacion' => now()->subMinutes(
          fake()->numberBetween(10, 60)
        ),
        'fecha_recogida' => null,
        'fecha_entrega' => null,
        'motivo_fallo' => null,
        'observaciones_fallo' => null,
      ];
    });
  }

  public function recogido(): static
  {
    return $this->state(function (array $attributes) {
      $repartidor = PerfilRepartidor::first() ?? PerfilRepartidor::factory()->create();
      $fechaAsignacion = now()->subMinutes(fake()->numberBetween(60, 120));

      return [
        'estado' => EstadosPedidoEnum::RECOGIDO,
        'repartidor_id' => $repartidor->id,
        'fecha_asignacion' => $fechaAsignacion,
        'fecha_recogida' => $fechaAsignacion->addMinutes(
          fake()->numberBetween(10, 30)
        ),
        'fecha_entrega' => null,
        'motivo_fallo' => null,
        'observaciones_fallo' => null,
      ];
    });
  }

  public function enRuta(): static
  {
    return $this->state(function (array $attributes) {
      $repartidor = PerfilRepartidor::first() ?? PerfilRepartidor::factory()->create();
      $fechaAsignacion = now()->subMinutes(fake()->numberBetween(60, 120));

      return [
        'estado' => EstadosPedidoEnum::EN_RUTA,
        'repartidor_id' => $repartidor->id,
        'fecha_asignacion' => $fechaAsignacion,
        'fecha_recogida' => $fechaAsignacion->addMinutes(
          fake()->numberBetween(10, 30)
        ),
        'fecha_entrega' => null,
        'motivo_fallo' => null,
        'observaciones_fallo' => null,
      ];
    });
  }

  public function entregado(): static
  {
    return $this->state(function (array $attributes) {
      $faker = FakerFactory::create('es_PE');
      $repartidor = PerfilRepartidor::first() ?? PerfilRepartidor::factory()->create();
      $fechaAsignacion = now()->subMinutes(fake()->numberBetween(120, 240));
      $fechaRecogida = $fechaAsignacion->addMinutes(
        fake()->numberBetween(10, 30)
      );
      $fechaEntrega = $fechaRecogida->addMinutes(
        fake()->numberBetween(30, 90)
      );

      return [
        'estado' => EstadosPedidoEnum::ENTREGADO,
        'repartidor_id' => $repartidor->id,
        'fecha_asignacion' => $fechaAsignacion,
        'fecha_recogida' => $fechaRecogida,
        'fecha_entrega' => $fechaEntrega,
        'firma_digital' => $faker->imageUrl(640, 480, 'signature'),
        'foto_entrega_path' => $faker->imageUrl(640, 480, 'delivery'),
        'firma_documento_consentimiento' => $attributes['requiere_firma_especial'] ? $faker->imageUrl(640, 480, 'document') : null,
        'motivo_fallo' => null,
        'observaciones_fallo' => null,
      ];
    });
  }

  public function fallido(): static
  {
    return $this->state(function (array $attributes) {
      $faker = FakerFactory::create('es_PE');
      $repartidor = PerfilRepartidor::first() ?? PerfilRepartidor::factory()->create();
      $fechaAsignacion = now()->subMinutes(fake()->numberBetween(60, 120));

      return [
        'estado' => EstadosPedidoEnum::FALLIDO,
        'repartidor_id' => $repartidor->id,
        'motivo_fallo' => fake()->randomElement(MotivosFalloPedidoEnum::cases()),
        'observaciones_fallo' => $faker->randomElement([
          'Cliente no se encuentra en domicilio',
          'Dirección no encontrada',
          'Cliente rechaza el pedido',
          'No hay quien firme el documento especial',
          'Zona de alto riesgo',
          'Fuera del área de cobertura',
          'Cliente no responde al teléfono'
        ]),
        'fecha_asignacion' => $fechaAsignacion,
        'fecha_recogida' => $fechaAsignacion->addMinutes(
          fake()->numberBetween(10, 30)
        ),
        'fecha_entrega' => null,
        'foto_entrega_path' => $faker->optional(0.3)->imageUrl(640, 480, 'evidence'),
      ];
    });
  }

  public function cancelado(): static
  {
    return $this->state(function (array $attributes) {
      return [
        'estado' => EstadosPedidoEnum::CANCELADO,
        'repartidor_id' => null,
        'motivo_fallo' => null,
        'observaciones_fallo' => null,
        'fecha_asignacion' => null,
        'fecha_recogida' => null,
        'fecha_entrega' => null,
        'foto_entrega_path' => null,
      ];
    });
  }

  public function configure(): static
  {
    return $this->afterCreating(function (Pedido $pedido) {
      $tipoEvento = EventosPedidoEnum::PEDIDO_CREADO;

      EventoPedido::create([
        'pedido_id' => $pedido->id,
        'user_id' => null,
        'tipo_evento' => $tipoEvento,
        'descripcion' => $tipoEvento->getDescription(),
        'metadata' => null,
        'ubicacion' => null,
      ]);
    });
  }
}
