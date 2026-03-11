class Team {
  final int id;
  final String name;
  final String category;
  final String? logoUrl;

  const Team({
    this.id = 0,
    required this.name,
    required this.category,
    this.logoUrl,
  });
}