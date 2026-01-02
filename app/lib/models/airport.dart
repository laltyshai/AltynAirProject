class Airport {
  final String code;
  final String name;
  final String city;
  final String country;

  Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      code: json['code'],
      name: json['name'],
      city: json['city'],
      country: json['country'],
    );
  }

  @override
  String toString() => '$city ($code)';
}
