<?php

namespace App\Models;

use App\Casts\AsPoint;
use App\Enums\CodigosIsoPaisEnum;
use App\Enums\EstadosPedidoEnum;
use App\Enums\MotivosFalloPedidoEnum;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasOneThrough;

/**
 * @property string $id
 * @property string $codigo_barra
 * @property string|null $farmacia_id
 * @property string|null $repartidor_id
 * @property string $paciente_nombre
 * @property string $paciente_telefono
 * @property string|null $paciente_email
 * @property CodigosIsoPaisEnum $codigo_iso_pais_entrega
 * @property string $direccion_entrega_linea_1
 * @property string|null $direccion_entrega_linea_2
 * @property string $ciudad_entrega
 * @property string|null $estado_region_entrega
 * @property string|null $codigo_postal_entrega
 * @property \MatanYadaev\EloquentSpatial\Objects\Point|null $ubicacion_recojo
 * @property \MatanYadaev\EloquentSpatial\Objects\Point|null $ubicacion_entrega
 * @property string|null $codigo_acceso_edificio
 * @property string|null $medicamentos
 * @property string $tipo_pedido
 * @property string|null $observaciones
 * @property bool $requiere_firma_especial
 * @property EstadosPedidoEnum $estado
 * @property string|null $firma_digital
 * @property string|null $foto_entrega_path
 * @property string|null $firma_documento_consentimiento
 * @property MotivosFalloPedidoEnum|null $motivo_fallo
 * @property string|null $observaciones_fallo
 * @property \Illuminate\Support\Carbon|null $fecha_asignacion
 * @property \Illuminate\Support\Carbon|null $fecha_recogida
 * @property \Illuminate\Support\Carbon|null $fecha_entrega
 * @property int|null $tiempo_entrega_estimado
 * @property float|null $distancia_estimada
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\EntregaPedido|null $entregaPedido
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\EventoPedido> $eventosPedido
 * @property-read int|null $eventos_pedido_count
 * @property-read \App\Models\Farmacia|null $farmacia
 * @property-read \App\Models\PerfilRepartidor|null $repartidor
 * @property-read \App\Models\Ruta|null $ruta
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\UbicacionRepartidor> $ubicacionesRepartidor
 * @property-read int|null $ubicaciones_repartidor_count
 * @method static \Database\Factories\PedidoFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereCiudadEntrega($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereCodigoAccesoEdificio($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereCodigoBarra($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereCodigoIsoPaisEntrega($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereCodigoPostalEntrega($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereDireccionEntregaLinea1($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereDireccionEntregaLinea2($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereDistanciaEstimada($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereEstado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereEstadoRegionEntrega($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereFarmaciaId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereFechaAsignacion($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereFechaEntrega($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereFechaRecogida($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereFirmaDigital($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereFirmaDocumentoConsentimiento($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereFotoEntregaPath($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereMedicamentos($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereMotivoFallo($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereObservaciones($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereObservacionesFallo($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido wherePacienteEmail($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido wherePacienteNombre($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido wherePacienteTelefono($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereRepartidorId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereRequiereFirmaEspecial($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereTiempoEntregaEstimado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereTipoPedido($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereUbicacionEntrega($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereUbicacionRecojo($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Pedido whereUpdatedAt($value)
 * @mixin \Eloquent
 */
class Pedido extends Model
{
  use HasUuids, HasFactory;

  protected $table = 'pedidos';
  protected $keyType = 'string';
  public $incrementing = false;

  protected $fillable = [
    'codigo_barra',
    'farmacia_id',
    'repartidor_id',
    'paciente_nombre',
    'paciente_telefono',
    'paciente_email',
    'codigo_iso_pais_entrega',
    'direccion_entrega_linea_1',
    'direccion_entrega_linea_2',
    'ciudad_entrega',
    'estado_region_entrega',
    'codigo_postal_entrega',
    'ubicacion_recojo',
    'ubicacion_entrega',
    'codigo_acceso_edificio',
    'medicamentos',
    'tipo_pedido',
    'observaciones',
    'requiere_firma_especial',
    'estado',
    'firma_digital',
    'foto_entrega_path',
    'firma_documento_consentimiento',
    'motivo_fallo',
    'observaciones_fallo',
    'fecha_asignacion',
    'fecha_recogida',
    'fecha_entrega',
    'tiempo_entrega_estimado',
    'distancia_estimada',
  ];

  protected function casts(): array
  {
    return [
      'codigo_iso_pais_entrega' => CodigosIsoPaisEnum::class,
      'ubicacion_recojo' => AsPoint::class,
      'ubicacion_entrega' => AsPoint::class,
      'requiere_firma_especial' => 'boolean',
      'estado' => EstadosPedidoEnum::class,
      'motivo_fallo' => MotivosFalloPedidoEnum::class,
      'fecha_asignacion' => 'datetime',
      'fecha_recogida' => 'datetime',
      'fecha_entrega' => 'datetime',
      'distancia_estimada' => 'float',
    ];
  }

  public function farmacia(): BelongsTo
  {
    return $this->belongsTo(Farmacia::class, 'farmacia_id');
  }

  public function repartidor(): BelongsTo
  {
    return $this->belongsTo(PerfilRepartidor::class, 'repartidor_id');
  }

  public function eventosPedido(): HasMany
  {
    return $this->hasMany(EventoPedido::class, 'pedido_id');
  }

  public function ubicacionesRepartidor(): HasMany
  {
    return $this->hasMany(UbicacionRepartidor::class, 'pedido_id');
  }

  public function entregaPedido(): HasOne
  {
    return $this->hasOne(EntregaPedido::class, 'pedido_id');
  }

  public function ruta(): HasOneThrough
  {
    return $this->hasOneThrough(
      Ruta::class,
      EntregaPedido::class,
      'pedido_id',
      'id',
      'id',
      'ruta_id'
    );
  }
}
