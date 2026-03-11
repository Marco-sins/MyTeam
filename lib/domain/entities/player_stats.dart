class PlayerStats {
  final int id;
  final int playerId;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;

  const PlayerStats({
    this.id = 0,
    this.playerId = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  });
}