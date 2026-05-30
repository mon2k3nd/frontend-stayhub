import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;
    if (!raw.startsWith('stayhub://room?')) {
      _showError(
          'Mã QR không hợp lệ. Vui lòng quét mã QR phòng StayHub.');
      return;
    }

    setState(() => _scanned = true);
    _ctrl.stop();

    final uri = Uri.parse(raw);
    final roomId =
    int.tryParse(uri.queryParameters['id'] ?? '');
    final roomName = Uri.decodeComponent(
        uri.queryParameters['name'] ?? 'Phòng');
    final branchId =
    int.tryParse(uri.queryParameters['branchId'] ?? '');
    final branchName = Uri.decodeComponent(
        uri.queryParameters['branchName'] ?? '');
    final price =
        double.tryParse(uri.queryParameters['price'] ?? '0') ?? 0;

    if (roomId == null || branchId == null) {
      _showError('Dữ liệu mã QR bị lỗi. Hãy thử lại.');
      setState(() => _scanned = false);
      _ctrl.start();
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      '/rental-request',
      arguments: {
        'roomId': roomId,
        'roomName': roomName,
        'branchId': branchId,
        'branchName': branchName,
        'price': price,
      },
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
        title: const Text('Quét mã QR phòng',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _ctrl.torchState,
              builder: (_, state, __) => Icon(
                state == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: state == TorchState.on
                    ? kGold
                    : Colors.white54,
              ),
            ),
            onPressed: () => _ctrl.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios,
                color: Colors.white54),
            onPressed: () => _ctrl.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),
          _buildOverlay(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner,
                          color: kGold, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Hướng camera vào mã QR của phòng',
                        style: TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth * 0.65;
      final top = (constraints.maxHeight - size) / 2.5;
      final left = (constraints.maxWidth - size) / 2;
      return Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Positioned(
                  top: top,
                  left: left,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: top,
            left: left,
            child: SizedBox(
              width: size,
              height: size,
              child: _buildCorners(size),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCorners(double size) {
    const cornerSize = 28.0;
    const strokeWidth = 4.0;
    return Stack(
      children: [
        Positioned(
            top: 0,
            left: 0,
            child: _corner(true, true, cornerSize, strokeWidth)),
        Positioned(
            top: 0,
            right: 0,
            child: _corner(true, false, cornerSize, strokeWidth)),
        Positioned(
            bottom: 0,
            left: 0,
            child: _corner(false, true, cornerSize, strokeWidth)),
        Positioned(
            bottom: 0,
            right: 0,
            child: _corner(false, false, cornerSize, strokeWidth)),
      ],
    );
  }

  Widget _corner(
      bool top, bool left, double size, double stroke) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(color: kGold, width: stroke)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: kGold, width: stroke)
              : BorderSide.none,
          left: left
              ? BorderSide(color: kGold, width: stroke)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: kGold, width: stroke)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left
              ? const Radius.circular(6)
              : Radius.zero,
          topRight: top && !left
              ? const Radius.circular(6)
              : Radius.zero,
          bottomLeft: !top && left
              ? const Radius.circular(6)
              : Radius.zero,
          bottomRight: !top && !left
              ? const Radius.circular(6)
              : Radius.zero,
        ),
      ),
    );
  }
}