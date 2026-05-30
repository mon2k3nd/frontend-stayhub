import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isRegisterMode = false;
  bool _otpSent = false; // Đã gửi OTP chưa

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _confirmPassCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng nhập số điện thoại hợp lệ'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    final auth = context.read<AuthProvider>();
    final res = await auth.sendOtp(
      target: _phoneCtrl.text.trim(),
      channel: 'sms',
    );
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['devOtp'] != null
            ? '✅ OTP (dev): ${res['devOtp']}'
            : 'OTP đã gửi đến ${_phoneCtrl.text.trim()}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Không gửi được OTP'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    Map<String, dynamic> result;
    if (_isRegisterMode) {
      result = await auth.register({
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'password': _passCtrl.text,
        'confirmPassword': _confirmPassCtrl.text,
        'otpCode': _otpCtrl.text.trim(),
        'otpChannel': 'sms',
      });
    } else {
      result = await auth.login(_phoneCtrl.text.trim(), _passCtrl.text);
    }

    if (!mounted) return;
    if (result['success'] == true) {
      final role = auth.role;
      if (role == 'OWNER' || role == 'STAFF') {
        Navigator.pushReplacementNamed(context, '/owner-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/tenant-dashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Có lỗi xảy ra!'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: kGold,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.apartment, color: kNavy, size: 44),
                  ),
                  const SizedBox(height: 16),
                  const Text('StayHub', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(
                    _isRegisterMode ? 'Tạo tài khoản mới' : 'Đăng nhập để tiếp tục',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_isRegisterMode) ...[
                            _buildField(controller: _nameCtrl, label: 'Họ và tên', icon: Icons.person_outline,
                                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null),
                            const SizedBox(height: 14),
                            _buildField(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => !v!.contains('@') ? 'Email không hợp lệ' : null),
                            const SizedBox(height: 14),
                          ],

                          // Phone + nút Gửi OTP (chỉ khi đăng ký)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildField(
                                  controller: _phoneCtrl,
                                  label: 'Số điện thoại',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v!.length < 10 ? 'SĐT không hợp lệ' : null,
                                ),
                              ),
                              if (_isRegisterMode) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: ElevatedButton(
                                    onPressed: _otpSent ? null : _sendOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _otpSent ? Colors.green : kGold,
                                      foregroundColor: kNavy,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(_otpSent ? '✓ Đã gửi' : 'Gửi OTP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),

                          if (_isRegisterMode && _otpSent) ...[
                            _buildField(
                              controller: _otpCtrl,
                              label: 'Mã OTP (6 số)',
                              icon: Icons.security_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.length != 6 ? 'OTP phải đủ 6 số' : null,
                            ),
                            const SizedBox(height: 14),
                          ],

                          _buildField(
                            controller: _passCtrl,
                            label: 'Mật khẩu',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePass,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                            validator: (v) => v!.length < 6 ? 'Mật khẩu phải có ít nhất 6 ký tự' : null,
                          ),

                          if (_isRegisterMode) ...[
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _confirmPassCtrl,
                              label: 'Xác nhận mật khẩu',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirm,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (v) => v != _passCtrl.text ? 'Mật khẩu không khớp' : null,
                            ),
                          ],

                          const SizedBox(height: 24),

                          Consumer<AuthProvider>(
                            builder: (_, auth, __) => SizedBox(
                              width: double.infinity, height: 50,
                              child: ElevatedButton(
                                onPressed: (auth.isLoading || (_isRegisterMode && !_otpSent)) ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kGold,
                                  foregroundColor: kNavy,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: kNavy, strokeWidth: 2.5))
                                    : Text(
                                  _isRegisterMode
                                      ? (_otpSent ? 'Tạo tài khoản' : 'Gửi OTP trước')
                                      : 'Đăng nhập',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isRegisterMode ? 'Đã có tài khoản? ' : 'Chưa có tài khoản? ',
                          style: const TextStyle(color: Colors.white54)),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _otpSent = false;
                          });
                          _formKey.currentState?.reset();
                        },
                        child: Text(
                          _isRegisterMode ? 'Đăng nhập' : 'Đăng ký ngay',
                          style: const TextStyle(color: kGold, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}