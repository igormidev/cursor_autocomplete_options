// sealed class StructuredDataRoot<T> {
//   final StructuredDataType<T> data;

//   const StructuredDataRoot({required this.data});
// }

sealed class StructuredDataType<F, T> {
  const StructuredDataType();
}

class FolderStructure<F, T> extends StructuredDataType<F, T> {
  final F item;
  final List<StructuredDataType<F, T>> children;

  const FolderStructure({
    required this.item,
    required this.children,
  });
}

class FileStructureOptions<F, T> extends StructuredDataType<F, T> {
  final T item;

  const FileStructureOptions({
    required this.item,
  });
}

// extension StructuredDataRootExtension<T> on StructuredDataType<T> {
//   T get item => switch (this) {
//         FolderStructure<T>(item: T item) => item,
//         FileStructureOptions<T>(item: T item) => item,
//       };
// }
