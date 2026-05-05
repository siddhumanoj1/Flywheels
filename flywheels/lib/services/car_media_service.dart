abstract final class CarMediaService {
  static String imageForModel(String model, {int? year}) {
    final normalized = model.toLowerCase();
    final query = Uri.encodeComponent(
      '${year ?? ''} $model car exterior'.trim(),
    );

    if (normalized.contains('mg') && normalized.contains('hector')) {
      return 'https://source.unsplash.com/1200x800/?$query';
    }
    if (normalized.contains('hyundai') && normalized.contains('creta')) {
      return 'https://source.unsplash.com/1200x800/?$query';
    }
    if (normalized.contains('maruti') || normalized.contains('swift')) {
      return 'https://source.unsplash.com/1200x800/?$query';
    }
    if (normalized.contains('toyota') || normalized.contains('innova')) {
      return 'https://source.unsplash.com/1200x800/?$query';
    }
    if (normalized.contains('kia') || normalized.contains('seltos')) {
      return 'https://source.unsplash.com/1200x800/?$query';
    }
    if (normalized.contains('mahindra') || normalized.contains('xuv')) {
      return 'https://source.unsplash.com/1200x800/?$query';
    }
    if (normalized.contains('honda') || normalized.contains('city')) {
      return 'https://source.unsplash.com/1200x800/?$query';
    }
    if (normalized.contains('tata') || normalized.contains('nexon')) {
      return 'https://source.unsplash.com/1200x800/?$query';
    }
    if ((year ?? 0) >= 2022) {
      return 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=1200&q=80';
    }
    return 'https://source.unsplash.com/1200x800/?${query.isEmpty ? 'car' : query}';
  }
}
