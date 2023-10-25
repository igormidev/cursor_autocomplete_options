typedef ForEachMapper<T> = void Function(
    T value, bool isFirst, bool isLast, int index);

extension ListUtils<T> on List<T> {
  void forEachMapper(ForEachMapper<T> toElement) {
    asMap().entries.forEach((entry) {
      final index = entry.key;
      final value = entry.value;
      final isLast = (index + 1) == length;
      final isFirst = index == 0;
      toElement(value, isFirst, isLast, index);
    });
  }
}
