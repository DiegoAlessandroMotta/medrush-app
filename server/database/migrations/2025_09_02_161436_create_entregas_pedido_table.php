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
    Schema::create('entregas_pedido', function (Blueprint $table) {
      $table->id();
      $table->foreignUuid('ruta_id')->constrained('rutas')->cascadeOnDelete();
      $table->foreignUuid('pedido_id')->constrained('pedidos')->cascadeOnDelete();
      $table->integer('orden_optimizado')->nullable();
      $table->integer('orden_personalizado');
      $table->integer('orden_recojo')->nullable();
      $table->boolean('optimizado')->default(false);

      $table->unique(['ruta_id', 'pedido_id']);
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('entregas_pedido');
  }
};
