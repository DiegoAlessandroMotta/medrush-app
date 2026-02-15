<?php

namespace App\Services\Disk;

use Intervention\Image\ImageManager;
use Storage;
use Str;

class PrivateUploadsDiskService
{
  public const DISK_NAME = 'private_uploads';

  public static function getSignedUrl(
    ?string $filePath = null,
    int $expirationMinutes = 30,
  ): ?string {
    if ($filePath === null || empty($filePath) || !Storage::disk(self::DISK_NAME)->exists($filePath)) {
      return null;
    }

    return Storage::disk(self::DISK_NAME)->temporaryUrl(
      $filePath,
      now()->addMinutes($expirationMinutes)
    );
  }

  public static function saveImage(
    string $imgPath,
    string $prefix = '',
    ?string $name = null,
    ?int $width = null,
    ?int $height = null,
    bool $crop = false
  ): ?string {
    $result = self::saveImageWithDriver($imgPath, $prefix, $name, $width, $height, $crop, 'imagick');
    if ($result !== null) {
      return $result;
    }
    return self::saveImageWithDriver($imgPath, $prefix, $name, $width, $height, $crop, 'gd');
  }

  private static function saveImageWithDriver(
    string $imgPath,
    string $prefix,
    ?string $name,
    ?int $width,
    ?int $height,
    bool $crop,
    string $driver
  ): ?string {
    try {
      $manager = $driver === 'imagick' ? ImageManager::imagick() : ImageManager::gd();
      $image = $manager->read($imgPath);

      $originalWidth = $image->width();
      $originalHeight = $image->height();

      if (
        $crop && $width !== null && $height !== null
        && ($originalWidth > $width || $originalHeight > $height)
      ) {
        $image->cover($width, $height);
      } elseif ($width !== null || $height !== null) {
        $image->scaleDown($width, $height);
      }

      $webpImage = $image->toWebp(75);

      $fileName = $name;
      if ($fileName === null) {
        $fileName = $prefix . Str::uuid()->toString() . '.webp';
      } else {
        $fileName .= '.webp';
      }

      if (Storage::disk(self::DISK_NAME)->put($fileName, $webpImage)) {
        return $fileName;
      }

      return null;
    } catch (\Throwable $e) {
      \Log::warning("Error saving image with driver [{$driver}]: " . $e->getMessage());
      return null;
    }
  }

  public static function delete(string $fileName): bool
  {
    return Storage::disk(self::DISK_NAME)->delete($fileName);
  }

  public static function getPath(string $fileName): string
  {
    return Storage::disk(self::DISK_NAME)->path($fileName);
  }
}
