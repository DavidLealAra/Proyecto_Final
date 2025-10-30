import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant.dart';

class RestaurantMapView extends StatelessWidget {
  final Restaurant restaurant;
  final double fallbackLat;
  final double fallbackLng;

  const RestaurantMapView({
    super.key,
    required this.restaurant,
    this.fallbackLat = 42.2406,
    this.fallbackLng = -8.7207,
  });

  @override
  Widget build(BuildContext context) {
    final lat = restaurant.lat ?? fallbackLat;
    final lng = restaurant.lng ?? fallbackLng;
    final position = LatLng(lat, lng);

    // En escritorio abrimos Google Maps en el navegador externo
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return FilledButton.icon(
        onPressed: () async {
          final url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.map),
        label: const Text('Abrir mapa en el navegador'),
      );
    }

    // En Android/iOS usamos el mapa nativo
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: position,
            zoom: 14.5,
          ),
          markers: {
            Marker(
              markerId: MarkerId(restaurant.id),
              position: position,
              infoWindow: InfoWindow(
                title: restaurant.name,
                snippet: restaurant.address,
              ),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}
