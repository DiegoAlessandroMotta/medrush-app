<?php

namespace App\Models;

use App\Enums\EstadoReportePdfEnum;
use App\Enums\PageSizeEnum;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Storage;

/**
 * @property string $id
 * @property string $user_id
 * @property string $nombre
 * @property string|null $file_path
 * @property int|null $file_size
 * @property int|null $paginas
 * @property PageSizeEnum $page_size
 * @property array<array-key, mixed> $pedidos
 * @property EstadoReportePdfEnum $status
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf whereFilePath($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf whereFileSize($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf whereNombre($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf wherePageSize($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf wherePaginas($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf wherePedidos($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf whereStatus($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ReportePdf whereUserId($value)
 * @mixin \Eloquent
 */
class ReportePdf extends Model
{
  use HasUuids;

  protected $table = 'reportes_pdf';

  protected $fillable = [
    'user_id',
    'nombre',
    'file_path',
    'file_size',
    'paginas',
    'page_size',
    'pedidos',
    'status',
  ];

  protected $casts = [
    'file_size' => 'integer',
    'paginas' => 'integer',
    'page_size' => PageSizeEnum::class,
    'pedidos' => 'array',
    'status' => EstadoReportePdfEnum::class,
  ];

  public function user(): BelongsTo
  {
    return $this->belongsTo(User::class);
  }

  public function pedidosCount(): int
  {
    return is_array($this->pedidos) ? count($this->pedidos) : 0;
  }

  public function markAsInProcess(): void
  {
    $this->update([
      'status' => EstadoReportePdfEnum::EN_PROCESO,
      'file_path' => null,
      'file_size' => null,
      'paginas' => null,
    ]);
  }

  public function markAsCreated(
    string $filePath,
    int $fileSize,
    int $totalPages,
  ): void {
    $this->update([
      'status' => EstadoReportePdfEnum::CREADO,
      'file_path' => $filePath,
      'file_size' => $fileSize,
      'paginas' => $totalPages,
    ]);
  }

  public function markAsFailed(): void
  {
    $this->update([
      'status' => EstadoReportePdfEnum::FALLIDO,
      'file_path' => null,
      'file_size' => null,
      'paginas' => null,
    ]);
  }

  public function markAsExpired(): void
  {
    $this->update([
      'status' => EstadoReportePdfEnum::EXPIRADO,
      'file_path' => null,
      'file_size' => null,
      'paginas' => null,
    ]);
  }

  public function deleteFromDisk(): bool
  {
    if ($this->file_path === null) {
      return true;
    }

    if (!self::getDiskInstance()->exists($this->file_path)) {
      return true;
    }

    return self::getDiskInstance()->delete($this->file_path);
  }

  public function existsOnDisk(): bool
  {
    return $this->file_path !== null && self::getDiskInstance()->exists($this->file_path);
  }

  public function sizeOnDisk(): int
  {
    return $this->file_path !== null ? self::getDiskInstance()->size($this->file_path) : 0;
  }

  public function getReadableFileSize(): string
  {
    $bytes = $this->file_size ?? 0;

    if ($bytes === 0) {
      return '0 B';
    }

    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    $unitIndex = 0;
    $size = $bytes;

    while ($size >= 1024 && $unitIndex < count($units) - 1) {
      $size /= 1024;
      $unitIndex++;
    }

    $decimals = $unitIndex === 0 ? 0 : 1;

    return number_format($size, $decimals) . ' ' . $units[$unitIndex];
  }

  public function getSignedUrl(): ?string
  {
    $filePath = $this->file_path;

    if ($filePath === null) {
      return null;
    }

    return self::getDiskInstance()->temporaryUrl($filePath, now()->addMinutes(60));
  }

  public static function saveToDisk(string $fileName, $content): ?string
  {
    $filePath = "reportes/pdf/{$fileName}";

    return self::getDiskInstance()->put($filePath, $content) ? $filePath : null;
  }

  public static function getDiskInstance()
  {
    return Storage::disk();
  }
}
