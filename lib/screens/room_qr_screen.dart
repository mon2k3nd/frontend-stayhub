import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

class RoomQrScreen extends StatelessWidget {
  final int roomId;
  final String roomName;
  final int branchId;
  final String branchName;
  final double price;

  const RoomQrScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.branchId,
    required this.branchName,
    required this.price,
  });

  String get _qrData =>
      'stayhub://room?id=$roomId&name=${Uri.encodeComponent(roomName)}'
          '&branchId=$branchId&branchName=${Uri.encodeComponent(branchName)}'
          '&price=${price.toInt()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        leading: const BackButton(color: Colors.white),
        title: const Text('Mã QR phòng',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: kGold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.meeting_room,
                        color: kGold, size: 36),
                    const SizedBox(height: 8),
                    Text(roomName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(branchName,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${(price / 1000000).toStringAsFixed(1)} triệu / tháng',
                      style: const TextStyle(
                          color: kGold,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kGold.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0B192C),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0B192C),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white54, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Cho khách thuê quét mã này để gửi yêu cầu thuê phòng',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}