<?php

namespace App\Casts;

use App\Helpers\PrepareData;
use DB;
use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use Illuminate\Contracts\Database\Eloquent\SerializesCastableAttributes;
use Illuminate\Contracts\Database\Query\Expression as ExpressionContract;
use Illuminate\Database\Eloquent\Model;
use InvalidArgumentException;
use MatanYadaev\EloquentSpatial\Enums\Srid;
use MatanYadaev\EloquentSpatial\GeometryCast;
use MatanYadaev\EloquentSpatial\Objects\Point;

class AsPoint implements CastsAttributes, SerializesCastableAttributes
{
  protected GeometryCast $geometryCast;
  protected int $srid;

  /**
   * @param array<int, string> $arguments Argumentos pasados al cast en el modelo, e.g., 'location' => AsPoint::class.':4326'
   */
  public function __construct(array $arguments = [])
  {
    $this->srid = (int) ($arguments[0] ?? Srid::WGS84->value);
    $this->geometryCast = new GeometryCast(Point::class, ['srid' => $this->srid]);
  }

  /**
   * @param array{latitude: float, longitude: float} $value
   */
  public static function pointFromArray(array $value): Point
  {
    if (!isset($value['latitude']) || !isset($value['longitude'])) {
      throw new \Exception('Both latitude and longitude must be provided in the array.');
    }

    return new Point($value['latitude'], $value['longitude']);
  }

  /**
   * @param array{latitude: float, longitude: float} $value
   * @param int|Srid|null $srid
   */
  public static function fromArray(array $value, int|Srid|null $srid = Srid::WGS84): Point
  {
    if (!isset($value['latitude']) || !isset($value['longitude'])) {
      throw new \Exception('Both latitude and longitude must be provided in the array.');
    }

    return new Point($value['latitude'], $value['longitude'], $srid);
  }

  public function get(Model $model, string $key, mixed $value, array $attributes): ?Point
  {
    $point = $this->geometryCast->get($model, $key, $value, $attributes);

    if (!($point instanceof Point)) {
      return null;
    }

    return $point;
  }

  public function set(Model $model, string $key, mixed $value, array $attributes): ?ExpressionContract
  {
    if ($value === null) {
      return null;
    }

    if (is_array($value)) {
      $coords = PrepareData::location($value);

      if ($coords === null) {
        return null;
      }

      $value = self::fromArray($coords);
    }

    if (!($value instanceof Point)) {
      throw new InvalidArgumentException(sprintf('Expected %s, %s given.', Point::class, get_debug_type($value)));
    }

    return $this->geometryCast->set($model, $key, $value, $attributes);
  }

  public static function serializeValue(mixed $value)
  {
    if ($value instanceof Point) {
      return [
        'latitude' => $value->latitude,
        'longitude' => $value->longitude,
      ];
    }

    return PrepareData::location($value);
  }

  public function serialize(
    Model $model,
    string $key,
    mixed $value,
    array $attributes,
  ) {
    return self::serializeValue($value);
  }

  public static function toRawExpression(Point $point): ExpressionContract
  {
    $connection = DB::connection();

    return $point->toSqlExpression($connection);
  }

  public static function toMySqlRawExpression(Point $point): ExpressionContract
  {
    $wkt = $point->toWkt();

    return DB::raw("ST_GeomFromText('{$wkt}', {$point->srid})");
  }

  public static function toPostgreSqlRawExpression(Point $point): ExpressionContract
  {
    $wkt = $point->toWkt();

    return DB::raw("ST_GeomFromText('{$wkt}', {$point->srid})::geometry");
  }
}
