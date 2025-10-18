<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('google_api_usages', function (Blueprint $table) {
      $table->id();
      $table->foreignUuid('user_id')->nullable()->constrained('users')->nullOnDelete();
      $table->string('type');
      $table->timestamps();
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('google_api_usages');
  }
};
