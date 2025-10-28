<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ClientErrorReportRequest extends FormRequest
{
  public function rules(): array
  {
    return [
      'context' => ['required', 'array'],
    ];
  }

  public function getContext(): array
  {
    return $this->validated('context');
  }
}
