class AssetModel {
  final int id;
  final int roomId;
  final String assetName;
  final int quantity;
  final String? conditionNote;
  final String? assetImage;
  final String assetStatus;
  final double? value;
  final DateTime createdAt;

  AssetModel({
    required this.id,
    required this.roomId,
    required this.assetName,
    required this.quantity,
    this.conditionNote,
    this.assetImage,
    required this.assetStatus,
    this.value,
    required this.createdAt,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
        id: json['id'],
        roomId: json['roomId'],
        assetName: json['assetName'],
        quantity: json['quantity'] ?? 1,
        conditionNote: json['conditionNote'],
        assetImage: json['assetImage'],
        assetStatus: json['assetStatus'] ?? 'GOOD',
        value: json['value'] != null ? (json['value'] as num).toDouble() : null,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  String get statusLabel {
    switch (assetStatus) {
      case 'GOOD': return 'Tốt';
      case 'DAMAGED': return 'Hỏng';
      case 'LOST': return 'Mất';
      case 'REPAIRED': return 'Đã sửa';
      default: return assetStatus;
    }
  }
}
