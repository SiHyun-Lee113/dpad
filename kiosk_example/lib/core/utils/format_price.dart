String formatPrice(int price) {
  final String raw = price.toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final int fromEnd = raw.length - i;
    buffer.write(raw[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
