<?php

namespace App\Helpers;

class ArrayToMarkdown
{
  public static function convert(array $data, string $title = ''): string
  {
    $message = '';

    if (!empty($title)) {
      $message .= '## ' . $title . "\n\n";
    }

    foreach ($data as $key => $value) {
      $message .= self::formatKeyValuePair($key, $value, 0);
    }

    return $message;
  }

  private static function formatKeyValuePair(
    string $key,
    mixed $value,
    int $indent
  ): string {
    $indentation = str_repeat('  ', $indent);
    $line = '';
    $formattedKey = self::formatKey($key);

    if (is_array($value)) {
      if (self::isAssociative($value)) {
        $line .= $indentation . "- **" . $formattedKey . "**: \n";
        foreach ($value as $subKey => $subValue) {
          $line .= self::formatKeyValuePair(
            $subKey,
            $subValue,
            $indent + 1
          );
        }
      } else {
        $line .= $indentation . "- **" . $formattedKey . "**: \n";
        foreach ($value as $index => $item) {
          $line .=
            $indentation .
            '  - ' .
            self::formatScalarValue($item) .
            "\n";
        }
      }
    } else {
      $line .=
        $indentation .
        "- **" .
        $formattedKey .
        "**: " .
        self::formatScalarValue($value) .
        "\n";
    }

    return $line;
  }

  private static function formatKey(string $key): string
  {
    // Convertir snake_case a palabras separadas por espacios
    if (strpos($key, '_') !== false) {
      $key = str_replace('_', ' ', $key);
    }

    // Convertir camelCase a palabras separadas por espacios
    // Agregar espacio antes de letras mayúsculas (excepto la primera)
    $key = preg_replace('/(?<!^)([A-Z])/', ' $1', $key);

    // Capitalizar la primera letra de cada palabra
    return ucwords(strtolower($key));
  }

  private static function formatScalarValue(mixed $value): string
  {
    if (is_bool($value)) {
      return $value ? 'Sí' : 'No';
    }
    if (is_null($value)) {
      return '_Nulo_';
    }
    if (is_string($value) && empty($value)) {
      return '_Vacío_';
    }
    return (string) $value;
  }

  private static function isAssociative(array $arr): bool
  {
    if ([] === $arr) {
      return false;
    }

    return array_keys($arr) !== range(0, count($arr) - 1);
  }
}
