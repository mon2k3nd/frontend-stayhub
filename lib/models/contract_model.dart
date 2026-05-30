class ContractModel {
  final int id;
  final int roomId;
  final int tenantId;
  final int ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double? depositAmount;
  final double? electricityPrice;
  final double? waterPrice;
  final double? serviceFee;
  final String? terms;
  final String status;
  final DateTime? signedAt;
  final DateTime? terminatedAt;
  final String? terminationReason;
  final DateTime createdAt;

  ContractModel({
    required this.id,
    required this.roomId,
    required this.tenantId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    this.depositAmount,
    this.electricityPrice,
    this.waterPrice,
    this.serviceFee,
    this.terms,
    required this.status,
    this.signedAt,
    this.terminatedAt,
    this.terminationReason,
    required this.createdAt,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) => ContractModel(
        id: json['id'],
        roomId: json['roomId'],
        tenantId: json['tenantId'],
        ownerId: json['ownerId'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        monthlyRent: (json['monthlyRent'] as num).toDouble(),
        depositAmount: json['depositAmount'] != null
            ? (json['depositAmount'] as num).toDouble()
            : null,
        electricityPrice: json['electricityPrice'] != null
            ? (json['electricityPrice'] as num).toDouble()
            : null,
        waterPrice: json['waterPrice'] != null
            ? (json['waterPrice'] as num).toDouble()
            : null,
        serviceFee: json['serviceFee'] != null
            ? (json['serviceFee'] as num).toDouble()
            : null,
        terms: json['terms'],
        status: json['status'] ?? 'ACTIVE',
        signedAt: json['signedAt'] != null ? DateTime.parse(json['signedAt']) : null,
        terminatedAt:
            json['terminatedAt'] != null ? DateTime.parse(json['terminatedAt']) : null,
        terminationReason: json['terminationReason'],
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => endDate.isBefore(DateTime.now());

  // Số ngày còn lại của hợp đồng
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}
