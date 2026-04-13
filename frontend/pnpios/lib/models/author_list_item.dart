class AuthorListItem {
  final String id;
  final String name;
  final int? birthYear;
  final int? deathYear;
  final int booksCount;

  const AuthorListItem({
    required this.id,
    required this.name,
    this.birthYear,
    this.deathYear,
    required this.booksCount,
  });
}
