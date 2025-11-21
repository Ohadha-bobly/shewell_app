class Clinic {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String website;
  final List<String> services;
  final String operatingHours;
  final String description;
  final String? imageUrl;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.website,
    required this.services,
    required this.operatingHours,
    required this.description,
    this.imageUrl,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String,
      website: json['website'] as String,
      services: List<String>.from(json['services'] as List),
      operatingHours: json['operating_hours'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'website': website,
      'services': services,
      'operating_hours': operatingHours,
      'description': description,
      'image_url': imageUrl,
    };
  }
}

class SampleClinics {
  static List<Clinic> getSampleClinics() {
    return [
      Clinic(
        id: 'clinic_1',
        name: 'Women\'s Health Center',
        address: '123 Main Street, Downtown',
        latitude: 40.7128,
        longitude: -74.0060,
        phone: '+1-555-0101',
        website: 'https://womenshealthcenter.example.com',
        services: ['Gynecology', 'Mental Health', 'Prenatal Care'],
        operatingHours: 'Mon-Fri: 8AM-6PM, Sat: 9AM-2PM',
        description: 'Comprehensive women\'s health services with experienced professionals.',
        imageUrl: null,
      ),
      Clinic(
        id: 'clinic_2',
        name: 'Safe Space Wellness Clinic',
        address: '456 Oak Avenue, Midtown',
        latitude: 40.7580,
        longitude: -73.9855,
        phone: '+1-555-0202',
        website: 'https://safespace.example.com',
        services: ['Counseling', 'Support Groups', 'Crisis Intervention'],
        operatingHours: 'Mon-Sun: 24/7 Hotline, Clinic: 9AM-5PM',
        description: 'Safe and supportive environment for women in need.',
        imageUrl: null,
      ),
      Clinic(
        id: 'clinic_3',
        name: 'Family Planning & Wellness',
        address: '789 Elm Street, Uptown',
        latitude: 40.7829,
        longitude: -73.9654,
        phone: '+1-555-0303',
        website: 'https://familyplanning.example.com',
        services: ['Family Planning', 'STI Testing', 'Health Education'],
        operatingHours: 'Mon-Fri: 9AM-7PM, Sat: 10AM-4PM',
        description: 'Confidential reproductive health services and education.',
        imageUrl: null,
      ),
      Clinic(
        id: 'clinic_4',
        name: 'Mental Wellness Institute',
        address: '321 Pine Road, Suburbs',
        latitude: 40.7489,
        longitude: -73.9680,
        phone: '+1-555-0404',
        website: 'https://mentalwellness.example.com',
        services: ['Therapy', 'Psychiatric Services', 'Wellness Programs'],
        operatingHours: 'Mon-Fri: 8AM-8PM, Sat: 10AM-3PM',
        description: 'Dedicated mental health support for women and families.',
        imageUrl: null,
      ),
    ];
  }
}
