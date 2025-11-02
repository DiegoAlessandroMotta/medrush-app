<?php

namespace App\Validators;

use App\Helpers\PrepareData;
use App\Rules\LocationArray;
use App\Rules\PhoneNumberE164;
use Illuminate\Contracts\Validation\Validator as ValidatorContract;
use Validator;

class CsvPedidoRowValidator
{
  protected array $columnMapping = [
    // English
    'patient_name' => 'paciente_nombre',
    'patient_phone' => 'paciente_telefono',
    'patient_email' => 'paciente_email',
    'delivery_address_line_1' => 'direccion_entrega_linea_1',
    'delivery_address_line_2' => 'direccion_entrega_linea_2',
    'delivery_city' => 'ciudad_entrega',
    'delivery_state_region' => 'estado_region_entrega',
    'delivery_postal_code' => 'codigo_postal_entrega',
    'pickup_location' => 'ubicacion_recojo',
    'delivery_location' => 'ubicacion_entrega',
    'building_access_code' => 'codigo_acceso_edificio',
    'medications' => 'medicamentos',
    'order_type' => 'tipo_pedido',
    'observations' => 'observaciones',
    'requires_special_signature' => 'requiere_firma_especial',
    // Spanish
    'paciente_nombre' => 'paciente_nombre',
    'paciente_telefono' => 'paciente_telefono',
    'paciente_email' => 'paciente_email',
    'direccion_entrega_linea_1' => 'direccion_entrega_linea_1',
    'direccion_entrega_linea_2' => 'direccion_entrega_linea_2',
    'ciudad_entrega' => 'ciudad_entrega',
    'estado_region_entrega' => 'estado_region_entrega',
    'codigo_postal_entrega' => 'codigo_postal_entrega',
    'ubicacion_recojo' => 'ubicacion_recojo',
    'ubicacion_entrega' => 'ubicacion_entrega',
    'codigo_acceso_edificio' => 'codigo_acceso_edificio',
    'medicamentos' => 'medicamentos',
    'tipo_pedido' => 'tipo_pedido',
    'observaciones' => 'observaciones',
    'requiere_firma_especial' => 'requiere_firma_especial',
  ];

  public function rules(): array
  {
    return [
      'paciente_nombre' => ['required', 'string', 'max:255'],
      'paciente_telefono' => ['required', new PhoneNumberE164],
      'paciente_email' => ['sometimes', 'nullable', 'email', 'max:255'],
      'direccion_entrega_linea_1' => ['required', 'string', 'max:255'],
      'direccion_entrega_linea_2' => ['sometimes', 'nullable', 'string', 'max:255'],
      'ciudad_entrega' => ['required', 'string', 'max:255'],
      'estado_region_entrega' => ['sometimes', 'nullable', 'string', 'max:255'],
      'codigo_postal_entrega' => ['sometimes', 'nullable', 'string', 'max:20'],
      'ubicacion_recojo' => ['sometimes', 'nullable', new LocationArray],
      'ubicacion_entrega' => ['sometimes', 'nullable', new LocationArray],
      'codigo_acceso_edificio' => ['sometimes', 'nullable', 'string', 'max:20'],
      'medicamentos' => ['required', 'string', 'max:1000'],
      'tipo_pedido' => ['required', 'string', 'max:255'],
      'observaciones' => ['sometimes', 'nullable', 'string', 'max:1000'],
      'requiere_firma_especial' => ['sometimes', 'nullable', 'boolean'],
    ];
  }

  public function messages(): array
  {
    return [
      'paciente_nombre.required' => 'El nombre del paciente es obligatorio.',
      'paciente_telefono.required' => 'El teléfono del paciente es obligatorio.',
      'ubicacion_entrega.required' => 'La ubicación de entrega es obligatoria.',
      'ubicacion_entrega.latitude.required' => 'La latitud de entrega es obligatoria.',
      'ubicacion_entrega.longitude.required' => 'La longitud de entrega es obligatoria.',
      'medicamentos.required' => 'Los medicamentos son obligatorios.',
      'tipo_pedido.required' => 'El tipo de pedido es obligatorio.',
    ];
  }

  protected function prepareForValidation(array $record): array
  {
    $normalized = [];

    foreach ($record as $key => $value) {
      $normalizedKey = strtolower(trim($key));

      $targetKey = $this->columnMapping[$normalizedKey] ?? null;

      if ($targetKey) {
        $trimmedValue = trim((string) $value);
        $normalized[$targetKey] = $trimmedValue !== '' ? $trimmedValue : null;
      }
    }

    $ubicacionRecojoKey = 'ubicacion_recojo';
    if (isset($normalized[$ubicacionRecojoKey])) {
      $normalized[$ubicacionRecojoKey] = PrepareData::location($normalized[$ubicacionRecojoKey]);
    }

    $ubicacionEntregaKey = 'ubicacion_entrega';
    if (isset($normalized[$ubicacionEntregaKey])) {
      $normalized[$ubicacionEntregaKey] = PrepareData::location($normalized[$ubicacionEntregaKey]);
    }

    $firmaEspecialKey = 'requiere_firma_especial';
    if (isset($normalized[$firmaEspecialKey])) {
      $normalized[$firmaEspecialKey] = PrepareData::boolean($normalized[$firmaEspecialKey]);
    }

    return $normalized;
  }

  public function validate(array $data): ValidatorContract
  {
    $preparedData = $this->prepareForValidation($data);
    return Validator::make($preparedData, $this->rules(), $this->messages());
  }
}
