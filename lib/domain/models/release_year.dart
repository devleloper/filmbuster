/// The year of an ISO [releaseDate] such as `2010-09-30`, or `null` when the
/// date is missing or malformed.
int? releaseYearOf(String? releaseDate) {
  if (releaseDate == null || releaseDate.length < 4) return null;
  return int.tryParse(releaseDate.substring(0, 4));
}
