import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_flutter/shared_flutter.dart';

/// Captures the shop's GPS location. Auto-detects on entry; the user can pan the
/// map to fine-tune (the centre crosshair is the chosen point) before confirming.
class LocationPickScreen extends StatefulWidget {
  const LocationPickScreen({super.key, required this.onConfirmed});

  final void Function(double latitude, double longitude) onConfirmed;

  @override
  State<LocationPickScreen> createState() => _LocationPickScreenState();
}

class _LocationPickScreenState extends State<LocationPickScreen> {
  static const LatLng _defaultFallback = LatLng(14.7167, -17.4677); // Dakar

  final MapController _mapController = MapController();
  LatLng? _center;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _useFallback('Activez la localisation sur votre téléphone');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _useFallback('Autorisez la localisation pour continuer');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final c = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = c;
        _loading = false;
      });
      _mapController.move(c, 17);
    } catch (e) {
      _useFallback('Impossible de localiser. Déplacez la carte manuellement.');
    }
  }

  void _useFallback(String message) {
    if (!mounted) return;
    setState(() {
      _center = _defaultFallback;
      _loading = false;
      _error = message;
    });
  }

  void _confirm() {
    final c = _mapController.camera.center;
    widget.onConfirmed(c.latitude, c.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Position de la boutique'),
        backgroundColor: GasColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Détecter à nouveau',
            onPressed: _loading ? null : _detect,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_center != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center!,
                initialZoom: 17,
                minZoom: 4,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gasfinder.mobile_retailer',
                ),
              ],
            ),
          // Centre crosshair: the map moves under it; the dot is always the picked point.
          const Center(
            child: IgnorePointer(
              child: Icon(Icons.location_pin, size: 56, color: GasColors.out),
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: GasColors.primary)),
          if (_error != null)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Material(
                color: GasColors.low,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: BigButton(
              icon: Icons.check,
              label: 'Confirmer cette position',
              color: GasColors.available,
              onPressed: _loading ? null : _confirm,
            ),
          ),
        ],
      ),
    );
  }
}
