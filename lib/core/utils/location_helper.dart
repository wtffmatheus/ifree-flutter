import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  // â”â‚¬â”â‚¬ PermissÃƒÂ£o e posiÃƒÂ§ÃƒÂ£o atual â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // geolocator v13 ââ‚¬” desiredAccuracy mantido (upgrade v14 pendente)
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  // â”â‚¬â”â‚¬ EndereÃƒÂ§o legÃƒÂ­vel a partir da posiÃƒÂ§ÃƒÂ£o â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬
  static Future<String?> getCurrentAddress() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = <String>[];
      if (p.subLocality != null && p.subLocality!.isNotEmpty)
        parts.add(p.subLocality!);
      if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  // â”â‚¬â”â‚¬ Coordenadas do usuário para cÃƒÂ¡lculo de distÃƒÂ¢ncia â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬
  static Future<Position?> getUserCoords() => getCurrentPosition();

  // â”â‚¬â”â‚¬ DistÃƒÂ¢ncia em km entre dois pontos â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬â”â‚¬
  static double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final meters = Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
    return meters / 1000;
  }

  /// Formata a distÃƒÂ¢ncia: "0.8 km" ou "12 km"
  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }
}
