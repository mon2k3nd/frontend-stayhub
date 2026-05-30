class BillModel {
  final int id;
  final int roomId;
  final int? contractId;
  final int? tenantId;
  final int month;
  final int year;
  final double? electricCurrent;
  final double? electricPrevious;
  final double? waterCurrent;
  final double? waterPrevious;
  final double? electricUnitPrice;
  final double? waterUnitPrice;
  final double? electricAmount;
  final double? waterAmount;
  final double? rentAmount;
  final double? serviceAmount;
  final double? totalAmount;
  final String? electricImage;
  final String? waterImage;
  final String? paymentQrUrl;
  final bool isPaid;
  final DateTime? paidAt;
  final bool paidByCash;
  final int? collectedByStaffId;
  final DateTime? dueDate;
  final DateTime createdAt;

  BillModel({
    required this.id,
    required this.roomId,
    this.contractId,
    this.tenantId,
    required this.month,
    required this.year,
    this.electricCurrent,
    this.electricPrevious,
    this.waterCurrent,
    this.waterPrevious,
    this.electricUnitPrice,
    this.waterUnitPrice,
    this.electricAmount,
    this.waterAmount,
    this.rentAmount,
    this.serviceAmount,
    this.totalAmount,
    this.electricImage,
    this.waterImage,
    this.paymentQrUrl,
    required this.isPaid,
    this.paidAt,
    required this.paidByCash,
    this.collectedByStaffId,
    this.dueDate,
    required this.createdAt,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
        id: json['id'],
        roomId: json['roomId'],
        contractId: json['contractId'],
        tenantId: json['tenantId'],
        month: json['month'],
        year: json['year'],
        electricCurrent: json['electricCurrent'] != null
            ? (json['electricCurrent'] as num).toDouble()
            : null,
        electricPrevious: json['electricPrevious'] != null
            ? (json['electricPrevious'] as num).toDouble()
            : null,
        waterCurrent: json['waterCurrent'] != null
            ? (json['waterCurrent'] as num).toDouble()
            : null,
        waterPrevious: json['waterPrevious'] != null
            ? (json['waterPrevious'] as num).toDouble()
            : null,
        electricUnitPrice: json['electricUnitPrice'] != null
            ? (json['electricUnitPrice'] as num).toDouble()
            : null,
        waterUnitPrice: json['waterUnitPrice'] != null
            ? (json['waterUnitPrice'] as num).toDouble()
            : null,
        electricAmount: json['electricAmount'] != null
            ? (json['electricAmount'] as num).toDouble()
            : null,
        waterAmount: json['waterAmount'] != null
            ? (json['waterAmount'] as num).toDouble()
            : null,
        rentAmount: json['rentAmount'] != null
            ? (json['rentAmount'] as num).toDouble()
            : null,
        serviceAmount: json['serviceAmount'] != null
            ? (json['serviceAmount'] as num).toDouble()
            : null,
        totalAmount: json['totalAmount'] != null
            ? (json['totalAmount'] as num).toDouble()
            : null,
        electricImage: json['electricImage'],
        waterImage: json['waterImage'],
        paymentQrUrl: json['paymentQrUrl'],
        isPaid: json['isPaid'] ?? false,
        paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
        paidByCash: json['paidByCash'] ?? false,
        collectedByStaffId: json['collectedByStaffId'],
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  String get periodLabel => 'Tháng $month/$year';
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isPaid;
}
