<?php

use App\Enums\EventosPedidoEnum;
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
    Schema::create('eventos_pedido', function (Blueprint $table) {
      $table->id();
      $table->foreignUuid('pedido_id')->constrained('pedidos')->onDelete('cascade');
      $table->foreignUuid('user_id')->nullable()->constrained('users')->onDelete('set null');
      $table->string('tipo_evento')->default(EventosPedidoEnum::PEDIDO_CREADO->value);
      $table->string('descripcion')->nullable();
      $table->jsonb('metadata')->nullable();
      $table->geography('ubicacion', subtype: 'point', srid: 4326)->nullable();
      $table->timestamps();

      $table->index('pedido_id');
      $table->index('user_id');
      $table->index('tipo_evento');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('eventos_pedido');
  }
};
