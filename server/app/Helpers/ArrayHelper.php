<?php

namespace App\Helpers;

class ArrayHelper
{
  public static function filterByBackedEnum(
    array $values,
    string $enumClassName
  ): ?array {
    if (!enum_exists($enumClassName) || !is_subclass_of($enumClassName, \BackedEnum::class)) {
      throw new \InvalidArgumentException(
        "La clase '$enumClassName' no es un Baked Enum válido."
      );
    }

    $uniqueValues = array_unique($values);
    $enumValues = array_column($enumClassName::cases(), 'value');
    $intersection = array_intersect($uniqueValues, $enumValues);

    return empty($intersection) ? null : $intersection;
  }

  public static function filterStringArrayByBackedEnum(
    string $stringArray,
    string $enumClassName,
    string $separator = ',',
  ): ?array {
    $values = self::arrayFromString($stringArray, $separator);

    return self::filterByBackedEnum($values, $enumClassName);
  }

  public static function arrayFromString(
    string $stringArray,
    string $separator = ',',
  ): array {
    return array_map('trim', explode($separator, $stringArray));
  }
}
