class Team {
  final int id;
  final String name;
  final String category;
  final String? logoUrl;

  const Team({
    required this.id,
    required this.name,
    required this.category,
    this.logoUrl,
  });
}