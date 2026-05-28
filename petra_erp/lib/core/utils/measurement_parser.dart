class MeasurementParser {
  static String _resolve(
    Map map,
    String primaryKey,
    String fallbackKey,
    String defaultValue,
  ) {
    return (map[primaryKey] ?? map[fallbackKey] ?? defaultValue).toString();
  }

  static List<Map<String, String>> parse(
    Map<String, dynamic> measurements, {
    String defaultValue = '-',
  }) {
    final List<Map<String, String>> rows = [];
    if (measurements.containsKey('items') && measurements['items'] is List) {
      final list = measurements['items'] as List;
      for (final item in list) {
        if (item is Map) {
          rows.add(_buildRow(item, defaultValue));
        }
      }
    } else {
      final hasKeys = measurements.containsKey('width') ||
          measurements.containsKey('largura') ||
          measurements.containsKey('height') ||
          measurements.containsKey('altura') ||
          measurements.containsKey('thickness') ||
          measurements.containsKey('espessura');
      if (hasKeys) {
        rows.add(_buildRow(measurements, defaultValue));
      }
    }
    return rows;
  }

  static Map<String, String> _buildRow(Map map, String defaultValue) {
    return {
      'width': _resolve(map, 'width', 'largura', defaultValue),
      'height': _resolve(map, 'height', 'altura', defaultValue),
      'thickness': _resolve(map, 'thickness', 'espessura', defaultValue),
      'format': _resolve(map, 'format', 'formato', defaultValue),
      'details': _resolve(map, 'details', 'detalhes', defaultValue),
    };
  }
}
