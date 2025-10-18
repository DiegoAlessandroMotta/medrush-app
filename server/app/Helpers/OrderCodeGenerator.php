<?php

namespace App\Helpers;

use Exception;
use InvalidArgumentException;

class OrderCodeGenerator
{
  protected const BASE62_ALPHABET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  protected const BASE62_LENGTH = 62;

  /**
   * Genera un código de pedido único y ordenable.
   *
   * @param int $randomSuffixLength La longitud del sufijo aleatorio en Base62. Mínimo 1. (Opcional, 4 por defecto)
   * @param $timestampPrecision La precisión del timestamp ('seconds' o 'milliseconds'). (Opcional, 'milliseconds' por defecto)
   * @param int $offset Un valor entero a sumar al timestamp base.
   *                    Útil para generar códigos distintos si múltiples se crean en el mismo instante,
   *                    actuando como un contador o identificador secuencial dentro de un lote.
   * @return string El código de pedido generado.
   * @throws InvalidArgumentException Si los parámetros de entrada son inválidos.
   * @throws Exception Si no se puede generar suficiente aleatoriedad.
   */
  public static function generateOrderCode(
    int $randomSuffixLength = 6,
    string $timestampPrecision = 'milliseconds',
    int $offset = 0,
  ): string {
    if (!is_int($randomSuffixLength) || $randomSuffixLength < 1) {
      throw new InvalidArgumentException('El parámetro `randomSuffixLength` es requerido y debe ser un entero positivo.');
    }

    if (!in_array($timestampPrecision, ['seconds', 'milliseconds'])) {
      throw new InvalidArgumentException('El parámetro `timestampPrecision` debe ser "seconds" o "milliseconds".');
    }

    if (!is_int($offset) || $offset < 0) {
      throw new InvalidArgumentException('El parámetro `offset` debe ser un entero no negativo.');
    }

    $timestamp = self::getTimestamp($timestampPrecision);
    $offsetTimestamp = $timestamp + $offset;

    $timestampBase62 = self::toBase62($offsetTimestamp);
    $randomSuffix = self::generateRandomBase62String($randomSuffixLength);

    return $timestampBase62 . $randomSuffix;
  }

  /**
   * Codifica un número entero a Base62.
   *
   * @param int $number El número a codificar.
   * @return string El número codificado en Base62.
   */
  protected static function toBase62(int $number): string
  {
    if ($number < 0) {
      throw new InvalidArgumentException('Solo se pueden codificar números no negativos a Base62.');
    }

    if ($number === 0) {
      return self::BASE62_ALPHABET[0];
    }

    $result = '';
    while ($number > 0) {
      $remainder = $number % self::BASE62_LENGTH;
      $result = self::BASE62_ALPHABET[$remainder] . $result;
      $number = (int) ($number / self::BASE62_LENGTH);
    }

    return $result;
  }

  /**
   * Obtiene el timestamp actual en la precisión especificada.
   *
   * @param string $precision 'seconds' o 'milliseconds'.
   * @return int El timestamp.
   */
  protected static function getTimestamp(string $precision): int
  {
    if ($precision === 'milliseconds') {
      return (int) (microtime(true) * 1000);
    }

    return time();
  }

  /**
   * Genera una cadena aleatoria de caracteres Base62.
   *
   * @param int $length La longitud de la cadena aleatoria.
   * @return string La cadena aleatoria Base62.
   * @throws Exception Si no se puede generar suficiente aleatoriedad
   */
  protected static function generateRandomBase62String(int $length): string
  {
    $randomString = '';

    for ($i = 0; $i < $length; $i++) {
      try {
        $randomIndex = random_int(0, self::BASE62_LENGTH - 1);
      } catch (Exception $e) {
        throw new Exception('No se pudo generar suficiente aleatoriedad: ' . $e->getMessage());
      }
      $randomString .= self::BASE62_ALPHABET[$randomIndex];
    }

    return $randomString;
  }
}
