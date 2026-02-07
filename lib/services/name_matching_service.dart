/// Service untuk fuzzy name matching
/// Detect nama yang mirip dengan typo, spasi, atau kapitalisasi berbeda
class NameMatchingService {
  /// Normalize nama untuk comparison
  static String normalizeName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Replace multiple spaces with single
  }

  /// Calculate Levenshtein Distance (edit distance)
  /// Returns number of edits needed to transform s1 to s2
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;
    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    // Initialize first row and column
    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Calculate distances
    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Calculate similarity percentage (0-100)
  static double calculateSimilarity(String name1, String name2) {
    final normalized1 = normalizeName(name1);
    final normalized2 = normalizeName(name2);

    if (normalized1 == normalized2) return 100.0;

    final distance = levenshteinDistance(normalized1, normalized2);
    final maxLength = normalized1.length > normalized2.length
        ? normalized1.length
        : normalized2.length;

    if (maxLength == 0) return 100.0;

    final similarity = ((maxLength - distance) / maxLength) * 100;
    return similarity;
  }

  /// Check if two names are similar enough to be the same person
  /// Returns true if similarity >= threshold (default 80%)
  static bool isSimilar(String name1, String name2, {double threshold = 80.0}) {
    final similarity = calculateSimilarity(name1, name2);
    return similarity >= threshold;
  }

  /// Find similar names from a list
  /// Returns list of names that are similar to the input name
  static List<String> findSimilarNames(
    String inputName,
    List<String> existingNames, {
    double threshold = 80.0,
  }) {
    final similar = <String>[];

    for (final existingName in existingNames) {
      if (isSimilar(inputName, existingName, threshold: threshold)) {
        similar.add(existingName);
      }
    }

    return similar;
  }

  /// Get detailed match info
  static Map<String, dynamic> getMatchInfo(String name1, String name2) {
    final normalized1 = normalizeName(name1);
    final normalized2 = normalizeName(name2);
    final similarity = calculateSimilarity(name1, name2);
    final distance = levenshteinDistance(normalized1, normalized2);

    return {
      'similarity': similarity,
      'distance': distance,
      'isSimilar': similarity >= 80.0,
      'normalized1': normalized1,
      'normalized2': normalized2,
    };
  }
}
