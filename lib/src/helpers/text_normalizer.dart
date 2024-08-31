extension TextNormalizerMixin on String {
  String get normalizeText {
    return toLowerCase().replaceAll(' ', '').normalizeSpecialCaracters;
  }

  /// Cast will try to transform caracters to that valid caracters
  /// Exemple:
  /// ç => c
  /// á => a
  /// à => a
  /// ô => o
  /// etc...
  String get normalizeSpecialCaracters {
    final validRegex = RegExp(r'^[a-zA-Z ]+$');

    final newValue = replaceAll(RegExp('ã|à|á|â|ă|å|ä|ā|æ|ą'), 'a')
        .replaceAll(RegExp('Ã|À|Á|Â|Ă|Å|Ä|Ā|Æ|Ą'), 'A')
        .replaceAll(RegExp('ó|ò|ô|ö|õ|ō|ø|œ'), 'o')
        .replaceAll(RegExp('Ó|Ò|Ô|Ö|Õ|Ō|Ø|Œ'), 'O')
        .replaceAll(RegExp('ú|ù|ū'), 'u')
        .replaceAll(RegExp('Ú|Ù|Ū'), 'U')
        .replaceAll(RegExp('í|ì|ī|î|ï'), 'i')
        .replaceAll(RegExp('Í|Ì|Ī|Î|Ï'), 'I')
        .replaceAll(RegExp('é|ē'), 'e')
        .replaceAll(RegExp('É|Ē'), 'E')
        .replaceAll(RegExp('ç'), 'c')
        .replaceAll(RegExp('Ç'), 'C')
        .replaceAll(RegExp('ñ'), 'n')
        .replaceAll(RegExp('Ñ'), 'N')
        .replaceAll(RegExp('ý|ÿ'), 'y')
        .replaceAll(RegExp('Ý|Ÿ'), 'Y')
        .replaceAll(RegExp('ð'), 'd')
        .replaceAll(RegExp('Ð'), 'D')
        .replaceAll(RegExp('[?]'), '')
        .replaceAll(RegExp('¿|¡|ß'), '');

    if (newValue.isNotEmpty && validRegex.hasMatch(newValue)) {
      return newValue;
    }

    return this;
  }
}
