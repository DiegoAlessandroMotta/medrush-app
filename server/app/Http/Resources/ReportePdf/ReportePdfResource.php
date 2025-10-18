<?php

namespace App\Http\Resources\ReportePdf;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Storage;

class ReportePdfResource extends JsonResource
{
  public function toArray(Request $request): array
  {
    return [
      'id' => $this->id,
      'user_id' => $this->user_id,
      'nombre' => $this->nombre,
      'file_url' => $this->getSignedUrl(),
      'file_size' => $this->file_size,
      'page_size' => $this->page_size,
      'paginas' => $this->paginas,
      'pedidos' => $this->pedidos,
      'status' => $this->status,
      'created_at' => $this->created_at,
      'updated_at' => $this->updated_at,
    ];
  }
}
