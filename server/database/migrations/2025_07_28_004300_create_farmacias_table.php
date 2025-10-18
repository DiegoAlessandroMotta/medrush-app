<?php

use App\Enums\EstadosFarmaciaEnum;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('farmacias', function (Blueprint $table) {
      $table->uuid("id")->primary();
      $table->string('nombre');
      $table->string('razon_social')->nullable();
      $table->string('ruc_ein')->nullable()->unique(); // RUC || EIN

      $table->string('direccion_linea_1');
      $table->string('direccion_linea_2')->nullable();
      $table->string('ciudad');
      $table->string('estado_region')->nullable();
      $table->string('codigo_postal')->nullable();
      $table->string('codigo_iso_pais', 3);
      $table->geography('ubicacion', subtype: 'point', srid: 4326)->nullable();

      $table->string('telefono')->nullable(); // Formato E.164
      $table->string('email')->nullable();
      $table->string('contacto_responsable')->nullable();
      $table->string('telefono_responsable')->nullable(); // Formato E.164
      $table->string('cadena')->nullable();
      $table->string('horario_atencion')->nullable();
      $table->boolean('delivery_24h')->default(false);
      $table->string('estado')->default(EstadosFarmaciaEnum::EN_REVISION->value);
      $table->timestamps();

      // Indexes
      $table->index('nombre');
      $table->index('razon_social');
      $table->index('ciudad');
      $table->index('estado_region');
      $table->index('codigo_iso_pais');
      $table->index('estado');
      // $table->spatialIndex('ubicacion');
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('farmacias');
  }
};
