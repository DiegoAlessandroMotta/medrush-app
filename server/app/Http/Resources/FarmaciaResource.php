<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Str;

class FarmaciaResource extends JsonResource
{
  /**
   * Transform the resource into an array.
   *
   * @return array<string, mixed>
   */
  public function toArray(Request $request): array
  {
    $data = parent::toArray($request);
    // $camelCaseData = [];

    // foreach ($data as $key => $value) {
    //   $camelCaseKey = Str::camel($key);
    //   $camelCaseData[$camelCaseKey] = $value;
    // }

    return $data;
  }
}
