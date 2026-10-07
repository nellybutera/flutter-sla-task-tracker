class DateText {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String deadline(DateTime date, {required DateTime now}) {
    final day =
        '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';
    final year = date.year == now.year ? '' : ' ${date.year}';
    return '$day$year, ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  static String relative(DateTime deadline, {required DateTime now}) {
    final difference = deadline.difference(now);
    if (difference.inMinutes == 0) {
      return 'due now';
    }
    final amount = _amount(difference.abs());
    return difference.isNegative ? '$amount late' : 'in $amount';
  }

  static String _amount(Duration duration) {
    if (duration.inDays >= 1) {
      return duration.inDays == 1 ? '1 day' : '${duration.inDays} days';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours} h';
    }
    return '${duration.inMinutes} min';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
