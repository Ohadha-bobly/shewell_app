import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/clinic.dart';

class ClinicDetailsScreen extends StatelessWidget {
  final Clinic clinic;

  const ClinicDetailsScreen({super.key, required this.clinic});

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: clinic.phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchWebsite() async {
    final Uri websiteUri = Uri.parse(clinic.website);
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(clinic.name),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.pinkAccent.withOpacity(0.1),
              child: const Icon(
                Icons.local_hospital,
                size: 80,
                color: Colors.pinkAccent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinic.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on, clinic.address),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time, clinic.operatingHours),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.description, clinic.description),
                  const SizedBox(height: 24),
                  const Text(
                    'Services Offered',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: clinic.services.map((service) {
                      return Chip(
                        label: Text(service),
                        backgroundColor: Colors.pinkAccent.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _launchPhone,
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _launchWebsite,
                          icon: const Icon(Icons.language),
                          label: const Text('Website'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.pinkAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.pinkAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
