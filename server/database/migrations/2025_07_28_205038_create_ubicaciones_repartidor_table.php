<?php

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
    Schema::create('ubicaciones_repartidor', function (Blueprint $table) {
      $table->id();
      $table->foreignUuid('repartidor_id')->constrained('perfiles_repartidor');
      $table->foreignUuid('pedido_id')->nullable()->constrained('pedidos');
      $table->foreignUuid('ruta_id')->nullable()->constrained('rutas');
      $table->geography('ubicacion', subtype: 'point', srid: 4326);
      $table->float('precision_m')->nullable();
      $table->float('velocidad_ms')->nullable();
      $table->float('direccion')->nullable();
      $table->timestamp('fecha_registro')->nullable();
      $table->timestamp('created_at')->nullable();

      $table->index(['ruta_id', 'created_at'], 'idx_ruta_created_at');
      $table->index(['pedido_id', 'created_at'], 'idx_pedido_created_at');
      $table->index(['repartidor_id', 'pedido_id', 'created_at'], 'idx_repartidor_pedido_created_at');
      $table->index(['repartidor_id', 'ruta_id', 'created_at'], 'idx_repartidor_ruta_created_at');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('ubicaciones_repartidor');
  }
};
