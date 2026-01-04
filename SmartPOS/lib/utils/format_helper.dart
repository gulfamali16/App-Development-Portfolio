/// Utility class for formatting money and numbers
class FormatHelper {
  /// Formats money to prevent overflow
  /// $1,500 -> $1.5K
  /// $25,000 -> $25K
  /// $1,500,000 -> $1.5M
  static String formatMoney(double value, {bool showSign = false}) {
    String sign = '';
    if (showSign && value > 0) sign = '+';
    if (value < 0) {
      sign = '-';
      value = value.abs();
    }
    
    if (value >= 1000000) {
      return '$sign\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '$sign\$${(value / 1000).toStringAsFixed(1)}K';
    } else if (value >= 100) {
      return '$sign\$${value.toStringAsFixed(0)}';
    }
    return '$sign\$${value.toStringAsFixed(2)}';
  }
  
  /// Format number without dollar sign
  static String formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
  
  /// Format percentage
  static String formatPercentage(double value) {
    if (value.isNaN || value.isInfinite) return '0%';
    String sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }
}
