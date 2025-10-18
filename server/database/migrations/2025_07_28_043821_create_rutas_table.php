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
    Schema::create('rutas', function (Blueprint $table) {
      $table->uuid('id')->primary();
      $table->foreignUuid('repartidor_id')->constrained('perfiles_repartidor');
      $table->string('nombre')->nullable();
      $table->geography('punto_inicio', subtype: 'point', srid: 4326)->nullable();
      $table->geography('punto_final', subtype: 'point', srid: 4326)->nullable();
      $table->text('polyline_encoded')->nullable();
      $table->float('distancia_total_estimada')->nullable();
      $table->integer('tiempo_total_estimado')->nullable();
      $table->integer('cantidad_pedidos')->nullable();
      $table->timestamp('fecha_hora_calculo')->nullable();
      $table->timestamp('fecha_inicio')->nullable();
      $table->timestamp('fecha_completado')->nullable();
      $table->timestamps();

      $table->index('repartidor_id');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('rutas');
  }
};
