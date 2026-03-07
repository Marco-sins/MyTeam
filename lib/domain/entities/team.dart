class Team {
  final int id;
  final String name;
  final String category;
  final String? logoUrl;

  Team({
    required this.id,
    required this.name,
    required this.category,
    this.logoUrl,
  });
}