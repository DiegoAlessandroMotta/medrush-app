class GeocodingResult {
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String formattedAddress;

  const GeocodingResult({
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.formattedAddress,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      addressLine1: json['address_line_1'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      country: json['country'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_line_1': addressLine1,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'formatted_address': formattedAddress,
    };
  }

  @override
  String toString() {
    return 'GeocodingResult(addressLine1: $addressLine1, city: $city, state: $state, postalCode: $postalCode, country: $country)';
  }
}
