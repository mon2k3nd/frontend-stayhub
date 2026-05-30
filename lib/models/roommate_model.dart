class RoommateModel {
  final int id;
  final int contractId;
  final int roomId;
  final String fullName;
  final String? phoneNumber;
  final String? cccdNumber;
  final String? hometown;
  final DateTime? birthday;
  final String? gender;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final bool isActive;

  RoommateModel({
    required this.id,
    required this.contractId,
    required this.roomId,
    required this.fullName,
    this.phoneNumber,
    this.cccdNumber,
    this.hometown,
    this.birthday,
    this.gender,
    this.checkInDate,
    this.checkOutDate,
    required this.isActive,
  });

  factory RoommateModel.fromJson(Map<String, dynamic> json) => RoommateModel(
        id: json['id'],
        contractId: json['contractId'],
        roomId: json['roomId'],
        fullName: json['fullName'],
        phoneNumber: json['phoneNumber'],
        cccdNumber: json['cccdNumber'],
        hometown: json['hometown'],
        birthday: json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
        gender: json['gender'],
        checkInDate:
            json['checkInDate'] != null ? DateTime.parse(json['checkInDate']) : null,
        checkOutDate:
            json['checkOutDate'] != null ? DateTime.parse(json['checkOutDate']) : null,
        isActive: json['isActive'] ?? true,
      );
}
