<?php

use App\Enums\EstadosRepartidorEnum;
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
    Schema::create('perfiles_repartidor', function (Blueprint $table) {
      $table->foreignUuid('id')->primary()->constrained('users')->onDelete('cascade');
      $table->foreignUuid('farmacia_id')->nullable()->constrained('farmacias')->onDelete('set null');
      $table->string('codigo_iso_pais', 3);
      $table->string('dni_id_numero')->nullable();
      $table->string('foto_dni_id_path', 512)->nullable();
      $table->string('telefono')->nullable();
      $table->string('licencia_numero')->nullable();
      $table->date('licencia_vencimiento')->nullable();
      $table->string('foto_licencia_path', 512)->nullable();
      $table->string('foto_seguro_vehiculo_path', 512)->nullable();
      $table->string('vehiculo_placa')->nullable();
      $table->string('vehiculo_marca')->nullable();
      $table->string('vehiculo_modelo')->nullable();
      $table->string('estado')->default(EstadosRepartidorEnum::DISPONIBLE->value);
      $table->boolean('verificado')->default(false);
      $table->timestamps();
      $table->softDeletes();

      $table->index('farmacia_id');
      $table->index('estado');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('perfiles_repartidor');
  }
};
