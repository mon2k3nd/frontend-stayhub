class BranchModel {
  final int id;
  final int ownerId;
  final String branchName;
  final String address;
  final String? description;
  final int totalRooms;
  final String? coverImage;
  final bool isActive;
  final DateTime createdAt;

  BranchModel({
    required this.id,
    required this.ownerId,
    required this.branchName,
    required this.address,
    this.description,
    required this.totalRooms,
    this.coverImage,
    required this.isActive,
    required this.createdAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) => BranchModel(
        id: json['id'],
        ownerId: json['ownerId'],
        branchName: json['branchName'],
        address: json['address'],
        description: json['description'],
        totalRooms: json['totalRooms'] ?? 0,
        coverImage: json['coverImage'],
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'branchName': branchName,
        'address': address,
        'description': description,
        'coverImage': coverImage,
      };
}
