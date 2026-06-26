abstract final class GoogleMapsLinkService {
  static String mapUrlForCoordinates({
    required double latitude,
    required double longitude,
  }) {
    final query =
        '${_formatCoordinate(latitude)},${_formatCoordinate(longitude)}';
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    }).toString();
  }

  static Uri mapUriForCoordinates({
    required double latitude,
    required double longitude,
  }) {
    return Uri.parse(
      mapUrlForCoordinates(latitude: latitude, longitude: longitude),
    );
  }

  static Uri mapUriForAddress(String address) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address.trim(),
    });
  }

  static String _formatCoordinate(double value) => value.toStringAsFixed(6);
}
