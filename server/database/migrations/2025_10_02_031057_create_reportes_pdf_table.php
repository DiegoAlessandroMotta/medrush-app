<?php

use App\Enums\EstadoReportePdfEnum;
use App\Enums\PageSizeEnum;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('reportes_pdf', function (Blueprint $table) {
      $table->uuid('id')->primary();
      $table->foreignUuid('user_id')->constrained()->onDelete('cascade');
      $table->string('nombre')->unique();
      $table->string('file_path')->nullable();
      $table->integer('file_size')->nullable();
      $table->integer('paginas')->nullable();
      $table->enum('page_size', PageSizeEnum::cases())->default(PageSizeEnum::A5);
      $table->jsonb('pedidos');
      $table->enum('status', EstadoReportePdfEnum::cases())->default(EstadoReportePdfEnum::EN_PROCESO);
      $table->timestamps();
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('reportes_pdf');
  }
};
