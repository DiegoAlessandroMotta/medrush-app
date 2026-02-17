<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  /**
   * Run the migrations.
   * Elimina columnas de documento de identidad (Foto de ID) ya no usadas (solo licencia en EE.UU.).
   */
  public function up(): void
  {
    Schema::table('perfiles_repartidor', function (Blueprint $table) {
      $table->dropColumn(['dni_id_numero', 'foto_dni_id_path']);
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::table('perfiles_repartidor', function (Blueprint $table) {
      $table->string('dni_id_numero')->nullable()->after('codigo_iso_pais');
      $table->string('foto_dni_id_path', 512)->nullable()->after('dni_id_numero');
    });
  }
};
