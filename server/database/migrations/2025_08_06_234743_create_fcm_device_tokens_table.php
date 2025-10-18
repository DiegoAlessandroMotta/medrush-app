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
    Schema::create('fcm_device_tokens', function (Blueprint $table) {
      $table->id();
      $table->foreignUuid('user_id')->nullable()->index()->constrained('users')->onDelete('cascade');
      $table->foreignId('session_id')->nullable()->constrained('personal_access_tokens')->onDelete('cascade');
      $table->string('token')->unique();
      $table->string('platform');
      $table->timestamp('last_used_at')->nullable();
      $table->timestamps();
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('fcm_device_tokens');
  }
};
