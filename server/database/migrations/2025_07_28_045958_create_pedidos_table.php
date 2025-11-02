<?php

use App\Enums\EstadosPedidoEnum;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  /**
   * Run the migrations.
   */
  public function up(): void
  {
    Schema::create('pedidos', function (Blueprint $table) {
      $table->uuid('id')->primary();
      $table->string('codigo_barra')->unique();
      $table->foreignUuid('farmacia_id')->nullable()->constrained('farmacias')->nullOnDelete();
      $table->foreignUuid('repartidor_id')->nullable()->constrained('perfiles_repartidor')->nullOnDelete();

      $table->string('paciente_nombre');
      $table->string('paciente_telefono'); // Formato E.164
      $table->string('paciente_email')->nullable();

      $table->string('codigo_iso_pais_entrega', 3);
      $table->string('direccion_entrega_linea_1');
      $table->string('direccion_entrega_linea_2')->nullable();
      $table->string('ciudad_entrega');
      $table->string('estado_region_entrega')->nullable();
      $table->string('codigo_postal_entrega')->nullable();
      $table->geography('ubicacion_recojo', subtype: 'point', srid: 4326)->nullable();
      $table->geography('ubicacion_entrega', subtype: 'point', srid: 4326)->nullable();

      $table->string('codigo_acceso_edificio')->nullable();

      $table->text('medicamentos')->nullable();
      $table->string('tipo_pedido');
      $table->text('observaciones')->nullable();
      $table->boolean('requiere_firma_especial')->default(false);
      $table->string('estado')->default(EstadosPedidoEnum::PENDIENTE->value);

      $table->text('firma_digital')->nullable();
      $table->string('foto_entrega_path', 512)->nullable();
      $table->text('firma_documento_consentimiento')->nullable();

      $table->string('motivo_fallo')->nullable();
      $table->text('observaciones_fallo')->nullable();

      $table->timestamp('fecha_asignacion')->nullable();
      $table->timestamp('fecha_recogida')->nullable();
      $table->timestamp('fecha_entrega')->nullable();
      $table->integer('tiempo_entrega_estimado')->nullable();
      $table->decimal('distancia_estimada', 10, 2)->nullable();
      $table->timestamps();

      // Indexes
      $table->index('farmacia_id');
      $table->index('repartidor_id');
      $table->index('estado');
      $table->index('codigo_iso_pais_entrega');
      $table->index('ciudad_entrega');
      $table->index('estado_region_entrega');
      $table->index('codigo_postal_entrega');
      // $table->spatialIndex('ubicacion_entrega');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('pedidos');
  }
};
