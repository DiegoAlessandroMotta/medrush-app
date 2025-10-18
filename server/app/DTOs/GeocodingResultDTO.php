<?php

namespace App\DTOs;

class GeocodingResultDTO
{
  public function __construct(
    public readonly string $addressLine1,
    public readonly string $city,
    public readonly string $state,
    public readonly string $postalCode,
    public readonly string $country,
    public readonly string $formattedAddress
  ) {}

  public function toArray(): array
  {
    return [
      'address_line_1' => $this->addressLine1,
      'city' => $this->city,
      'state' => $this->state,
      'postal_code' => $this->postalCode,
      'country' => $this->country,
      'formatted_address' => $this->formattedAddress,
    ];
  }

  public static function fromArray(array $data): self
  {
    return new self(
      addressLine1: $data['address_line_1'] ?? '',
      city: $data['city'] ?? '',
      state: $data['state'] ?? '',
      postalCode: $data['postal_code'] ?? '',
      country: $data['country'] ?? '',
      formattedAddress: $data['formatted_address'] ?? ''
    );
  }
}
