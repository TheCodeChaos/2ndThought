class SchulteCell {
  final int number;
  final int gridIndex;
  bool tapped;

  SchulteCell({
    required this.number,
    required this.gridIndex,
    this.tapped = false,
  });

  SchulteCell copyWith({bool? tapped}) {
    return SchulteCell(
      number: number,
      gridIndex: gridIndex,
      tapped: tapped ?? this.tapped,
    );
  }
}
