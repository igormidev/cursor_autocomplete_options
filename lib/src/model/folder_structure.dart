// sealed class StructuredDataRoot<T> {
//   final StructuredDataType<T> data;

//   const StructuredDataRoot({required this.data});
// }

sealed class StructuredDataType<T> {
  const StructuredDataType();
}

class FolderStructure<T> extends StructuredDataType<T> {
  final T item;
  final List<StructuredDataType<T>> children;

  const FolderStructure({
    required this.item,
    required this.children,
  });
}

class FileStructureOptions<T> extends StructuredDataType<T> {
  final T item;

  const FileStructureOptions({
    required this.item,
  });
}

extension StructuredDataRootExtension<T> on StructuredDataType<T> {
  T get item => switch (this) {
        FolderStructure<T>(item: T item) => item,
        FileStructureOptions<T>(item: T item) => item,
      };
}
