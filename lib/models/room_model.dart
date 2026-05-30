class RoomModel {
  final int id;
  final int ownerId;
  final int? branchId;
  final String roomName;
  final double? price;
  final String? address;
  final String status;
  final String? description;
  final double? deposit;
  final int? maxGuests;
  final double? electricityPrice;
  final double? waterPrice;
  final double? serviceFee;
  final String? roomImages;
  final String? inspectionImages;
  final String? qrCode;
  final int? currentTenantId;
  final int? currentContractId;

  RoomModel({
    required this.id,
    required this.ownerId,
    this.branchId,
    required this.roomName,
    this.price,
    this.address,
    required this.status,
    this.description,
    this.deposit,
    this.maxGuests,
    this.electricityPrice,
    this.waterPrice,
    this.serviceFee,
    this.roomImages,
    this.inspectionImages,
    this.qrCode,
    this.currentTenantId,
    this.currentContractId,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: json['id'],
        ownerId: json['ownerId'],
        branchId: json['branchId'],
        roomName: json['roomName'],
        price: json['price'] != null ? (json['price'] as num).toDouble() : null,
        address: json['address'],
        status: json['status'] ?? 'TRONG',
        description: json['description'],
        deposit: json['deposit'] != null ? (json['deposit'] as num).toDouble() : null,
        maxGuests: json['maxGuests'],
        electricityPrice: json['electricityPrice'] != null
            ? (json['electricityPrice'] as num).toDouble()
            : null,
        waterPrice: json['waterPrice'] != null
            ? (json['waterPrice'] as num).toDouble()
            : null,
        serviceFee: json['serviceFee'] != null
            ? (json['serviceFee'] as num).toDouble()
            : null,
        roomImages: json['roomImages'],
        inspectionImages: json['inspectionImages'],
        qrCode: json['qrCode'],
        currentTenantId: json['currentTenantId'],
        currentContractId: json['currentContractId'],
      );

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'branchId': branchId,
        'roomName': roomName,
        'price': price,
        'address': address,
        'description': description,
        'deposit': deposit,
        'maxGuests': maxGuests,
        'electricityPrice': electricityPrice,
        'waterPrice': waterPrice,
        'serviceFee': serviceFee,
      };

  bool get isTrong => status == 'TRONG';
  bool get isDaThue => status == 'DA_THUE';
  bool get isBaoTri => status == 'BAO_TRI';
  bool get isDongCua => status == 'DONG_CUA';

  String get statusLabel {
    switch (status) {
      case 'TRONG': return 'Trống';
      case 'DA_THUE': return 'Đã thuê';
      case 'BAO_TRI': return 'Bảo trì';
      case 'DONG_CUA': return 'Đóng cửa';
      default: return status;
    }
  }
}
