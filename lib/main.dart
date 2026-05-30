import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/contract_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/room_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/tenant_dashboard_screen.dart';
import 'screens/room_grid_screen.dart';
import 'screens/branch_management_screen.dart';
import 'screens/contract_screen.dart';
import 'screens/bill_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/staff_management_screen.dart';
import 'screens/roommate_screen.dart';
import 'screens/asset_management_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/room_qr_screen.dart';
import 'screens/rental_request_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StayHubApp());
}

class StayHubApp extends StatelessWidget {
  const StayHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => ContractProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
      ],
      child: MaterialApp(
        title: 'StayHub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0B192C),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0B192C),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/',
        routes: {
          '/': (ctx) => const SplashScreen(),
          '/login': (ctx) => const LoginScreen(),
          '/owner-dashboard': (ctx) {
            final auth = Provider.of<AuthProvider>(ctx, listen: false);
            return OwnerDashboardScreen(
              ownerId: auth.userId!,
              ownerName: auth.userName ?? 'Chủ nhà',
              planType: auth.planType ?? 'FREE',
            );
          },
          '/tenant-dashboard': (ctx) {
            final auth = Provider.of<AuthProvider>(ctx, listen: false);
            return TenantDashboardScreen(tenantId: auth.userId!);
          },
          '/rooms': (ctx) {
            final auth = Provider.of<AuthProvider>(ctx, listen: false);
            return BranchManagementScreen(ownerId: auth.userId!);
          },
          '/branches': (ctx) {
            final auth = Provider.of<AuthProvider>(ctx, listen: false);
            return BranchManagementScreen(ownerId: auth.userId!);
          },
          '/contracts': (ctx) {
            final auth = Provider.of<AuthProvider>(ctx, listen: false);
            return ContractScreen(
              userId: auth.userId!,
              isOwner: auth.role == 'OWNER',
            );
          },
          '/bills': (ctx) {
            final auth = Provider.of<AuthProvider>(ctx, listen: false);
            return BillScreen(
              userId: auth.userId!,
              isOwner: auth.role == 'OWNER' || auth.role == 'STAFF',
            );
          },
          '/notifications': (ctx) {
            final auth = Provider.of<AuthProvider>(ctx, listen: false);
            return NotificationScreen(userId: auth.userId!);
          },
          '/staff': (ctx) {
            final auth = Provider.of<AuthProvider>(ctx, listen: false);
            return StaffManagementScreen(ownerId: auth.userId!);
          },
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/room-grid') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RoomGridScreen(
                ownerId: args['ownerId'],
                branchName: args['branchName'] ?? 'Phòng trọ',
                branchId: args['branchId'],
              ),
            );
          }
          if (settings.name == '/roommates') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (ctx) {
                if (args == null) {
                  return const Scaffold(
                    backgroundColor: Color(0xFF0B192C),
                    body: Center(
                      child: Text('Chọn phòng để xem người ở cùng',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  );
                }
                return RoommateScreen(
                  contractId: args['contractId'],
                  roomId: args['roomId'],
                  roomName: args['roomName'] ?? 'Phòng',
                );
              },
            );
          }
          if (settings.name == '/room-assets') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AssetManagementScreen(
                roomId: args['roomId'],
                roomName: args['roomName'] ?? 'Phòng',
              ),
            );
          }
          if (settings.name == '/qr-scanner') {
            return MaterialPageRoute(
              builder: (_) => const QrScannerScreen(),
            );
          }
          if (settings.name == '/room-qr') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RoomQrScreen(
                roomId: args['roomId'],
                roomName: args['roomName'] ?? 'Phòng',
                branchId: args['branchId'],
                branchName: args['branchName'] ?? '',
                price: (args['price'] as num).toDouble(),
              ),
            );
          }
          if (settings.name == '/rental-request') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RentalRequestScreen(
                roomId: args['roomId'],
                roomName: args['roomName'] ?? 'Phòng',
                branchId: args['branchId'],
                branchName: args['branchName'] ?? '',
                price: (args['price'] as num).toDouble(),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
