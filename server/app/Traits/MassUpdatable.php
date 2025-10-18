<?php

namespace App\Traits;

use Illuminate\Contracts\Support\Arrayable;
use Illuminate\Contracts\Support\Jsonable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Arr;
use Illuminate\Support\Enumerable;
use Illuminate\Support\Facades\DB;
use UnexpectedValueException;

trait MassUpdatable
{
  public function getMassUpdateKeyName(): array|string|null
  {
    return $this->getKeyName();
  }

  /**
   * @return int The number of records updated in the Database
   */
  public function scopeMassUpdate(
    Builder $query,
    array|Enumerable $values,
    array|string|null $uniqueBy = null,
  ): int {
    if (blank($values)) {
      return 0;
    }

    if ($uniqueBy !== null && blank($uniqueBy)) {
      throw new UnexpectedValueException(
        'Second parameter expects an array of column names, used to properly filter your mass updatable values, but no names were given.',
      );
    }

    $escape = function (mixed $value) use ($query) {
      if ($value instanceof Arrayable) {
        $value = $value->toArray();
      }

      if (is_array($value)) {
        $value = json_encode($value);
      }

      if ($value instanceof Jsonable) {
        $value = $value->toJson();
      }

      return $query->getConnection()->escape($value);
    };

    $uniqueBy = array_flip(Arr::wrap($uniqueBy ?? $this->getMassUpdateKeyName()));

    $whereIn = [];

    $preCompiledUpdateStatements = [];

    foreach ($values as $record) {
      if (empty($record)) {
        continue;
      }

      if ($record instanceof Model) {
        if ($record::class !== static::class) {
          throw new UnexpectedValueException(
            "Expected an array of [" .
              static::class .
              "] model instances. Found an instance of [" .
              $record::class .
              "].",
          );
        }

        if (! $record->isDirty()) {
          continue;
        }

        $uniqueAttributes = array_intersect_key($record->getAttributes(), $uniqueBy);
        $updatableAttributes = $record->getDirty();

        if (! empty($crossReferencedColumns = array_intersect_key($updatableAttributes, $uniqueBy))) {
          throw new UnexpectedValueException(
            'It appears that an Eloquent Model\'s column was updated ' .
              'and is being used at the same time for mass filtering. ' .
              'This may cause filtering issues and may not even update the value properly. ' .
              "Affected columns:\n - " .
              implode("\n - ", array_keys($crossReferencedColumns)),
          );
        }
      } else {
        $uniqueAttributes = array_intersect_key($record, $uniqueBy);
        $updatableAttributes = array_diff_key($record, $uniqueBy);
      }

      if (empty($uniqueAttributes)) {
        throw new UnexpectedValueException(
          "None of the specified 'uniqueBy' columns were found on the current record.",
        );
      }

      if (empty($updatableAttributes)) {
        throw new UnexpectedValueException(
          'No updatable columns were found for the current record.',
        );
      }

      if (count($missingColumns = array_diff_key($uniqueBy, $uniqueAttributes)) > 0) {
        throw new UnexpectedValueException(
          "One of your records is missing some of the specified 'uniqueBy' columns. Make sure to include them all:\n" .
            '[' .
            implode(', ', array_keys($missingColumns)) .
            ']',
        );
      }

      $preCompiledConditions = [];

      foreach ($uniqueAttributes as $column => $value) {
        $preCompiledConditions[] = "{$query->getGrammar()->wrap($column)} = {$escape($value)}";

        $whereIn[$column] ??= [];

        if (! in_array($value, $whereIn[$column])) {
          $whereIn[$column][] = $value;
        }
      }

      $preCompiledConditions = implode(' AND ', $preCompiledConditions);

      foreach ($updatableAttributes as $column => $value) {
        if (! is_string($column)) {
          throw new UnexpectedValueException(
            "An array key for an updatable column must be a string. Found a value without a string key: [" .
              (is_scalar($value) ? $value : gettype($value)) .
              "]",
          );
        }

        $preCompiledAssociation = "WHEN $preCompiledConditions THEN {$escape($value)}";

        $preCompiledUpdateStatements[$column] ??= [];

        if (! in_array($preCompiledAssociation, $preCompiledUpdateStatements[$column])) {
          $preCompiledUpdateStatements[$column][] = $preCompiledAssociation;
        }
      }
    }

    if (empty($preCompiledUpdateStatements)) {
      return 0;
    }

    foreach ($whereIn as $column => $values) {
      $query->whereIn($column, $values);
    }

    $compiledUpdateStatements = collect($preCompiledUpdateStatements)
      ->mapWithKeys(function (array $conditionalAssignments, string $column) use ($query) {
        $conditions = implode("\n", $conditionalAssignments);

        return [
          $column => DB::raw(<<<SQL
                    CASE $conditions
                    ELSE {$query->getGrammar()->wrap($column)}
                    END
                    SQL),
        ];
      })
      ->toArray();

    if ($this->usesTimestamps() && $this->getUpdatedAtColumn() !== null) {
      $compiledUpdateStatements[$this->getUpdatedAtColumn()] = $this->freshTimestampString();
    }

    return $query->update($compiledUpdateStatements);
  }
}
