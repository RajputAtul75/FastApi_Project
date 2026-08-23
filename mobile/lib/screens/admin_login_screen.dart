/// Admin sign-in screen — the security gate in front of the admin dashboard.
///
/// Credentials are verified by the backend only (`POST /api/auth/login`);
/// nothing is checked or stored locally beyond the resulting session flag.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/app_state.dart';
// Reuse the landing page's design tokens and Ashoka Chakra motif so this screen
// reads as part of the same product. Scoped with `show` because
// utils/theme.dart also declares an `AppColors`.
import 'landing_screen.dart' show AppColors, AppText, AshokaChakra;

/// Gates an admin screen behind [AdminLoginScreen].
///
/// Wrapping every `/admin*` route in this guard means an unauthenticated deep
/// link renders the login screen instead of protected content. Route arguments
/// are unaffected, since they live on the enclosing [ModalRoute] rather than on
/// the widget.
class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authenticated =
        context.select<AppState, bool>((state) => state.isAdminAuthenticated);
    return authenticated ? child : const AdminLoginScreen();
  }
}

class AdminLoginScreen extends StatefulWidget {
  /// Route to open once signed in.
  ///
  /// Null when shown by [AdminGuard] — the guard swaps in the protected child
  /// itself as soon as the session becomes valid, so no navigation is needed.
  final String? redirectRoute;

  const AdminLoginScreen({super.key, this.redirectRoute});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  late final AnimationController _chakraController;

  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chakraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    )..repeat();
  }

  @override
  void dispose() {
    _chakraController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter both your username and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.adminLogin(username: username, password: password);
      if (!mounted) return;

      await context.read<AppState>().loginAsAdmin(username);
      if (!mounted) return;

      final redirect = widget.redirectRoute;
      if (redirect != null) {
        Navigator.pushReplacementNamed(context, redirect);
      }
      // Otherwise AdminGuard rebuilds and reveals the dashboard on its own.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _passwordCtrl.clear();
        _error = switch (e.statusCode) {
          401 => 'Incorrect username or password.',
          0 => e.message, // Server unreachable — message already explains it.
          _ => 'Sign-in failed (${e.statusCode}). ${e.message}',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Something went wrong while signing in. Please try again.';
      });
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const _TricolorStrip(),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Faint rotating chakra watermark, echoing the hero section.
                  Positioned(
                    top: 60,
                    child: RotationTransition(
                      turns: _chakraController,
                      child: AshokaChakra(
                        size: 320,
                        color: AppColors.navy.withValues(alpha: 0.05),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(),
                            const SizedBox(height: 26),
                            _buildBrand(),
                            const SizedBox(height: 26),
                            _buildCard(),
                            const SizedBox(height: 22),
                            _buildFootnote(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _goBack,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: const Text('Back'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.slate,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          textStyle: AppText.body(size: 13.5, weight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AshokaChakra(
              size: 30,
              color: AppColors.navy,
              strokeWidth: 2.6,
            ),
            const SizedBox(width: 10),
            Text(
              'NyayaAI',
              style: AppText.display(size: 20, weight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _RestrictedBadge(),
        const SizedBox(height: 16),
        Text(
          'Department sign-in',
          style: AppText.display(size: 29, weight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          'The admin dashboard holds live citizen complaints and personal '
          'details. Sign in with your department credentials to continue.',
          style: AppText.body(size: 14.5, color: AppColors.slate, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel('USERNAME'),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameCtrl,
            enabled: !_loading,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            style: AppText.body(size: 15),
            decoration: _inputDecoration(
              hint: 'department.admin',
              icon: Icons.person_outline_rounded,
            ),
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 18),
          _fieldLabel('PASSWORD'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            enabled: !_loading,
            obscureText: _obscurePassword,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            style: AppText.body(size: 15),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.slate,
                ),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 18),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffron,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.saffron.withValues(
                  alpha: 0.55,
                ),
                disabledForegroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: AppText.body(size: 15.5, weight: FontWeight.w600),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Sign in to dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootnote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, size: 15, color: AppColors.slate),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Credentials are issued by your department administrator and '
            'verified on the NyayaAI server. Your password is never stored on '
            'this device.',
            style: AppText.body(size: 11.5, color: AppColors.slate, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: AppText.body(
        size: 10.5,
        weight: FontWeight.w600,
        color: AppColors.slate,
      ).copyWith(letterSpacing: 0.9),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.body(
        size: 14.5,
        color: AppColors.slate.withValues(alpha: 0.55),
      ),
      prefixIcon: Icon(icon, size: 20, color: AppColors.slate),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.paper,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: border(AppColors.line, 1),
      enabledBorder: border(AppColors.line, 1),
      focusedBorder: border(AppColors.navy, 1.8),
      disabledBorder: border(AppColors.line, 1),
    );
  }
}

// ---------------------------------------------------------------------------
// Small presentational pieces
// ---------------------------------------------------------------------------

/// Navy-tinted pill marking this as a restricted area.
class _RestrictedBadge extends StatelessWidget {
  const _RestrictedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.navy2),
          const SizedBox(width: 7),
          Text(
            'RESTRICTED — AUTHORISED STAFF ONLY',
            style: AppText.mono(
              size: 10,
              weight: FontWeight.w500,
              color: AppColors.navy2,
            ).copyWith(letterSpacing: 0.7),
          ),
        ],
      ),
    );
  }
}

/// Inline error message shown above the sign-in button.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  static const _errorInk = Color(0xFF9A2020);
  static const _errorTint = Color(0xFFFBE9E9);
  static const _errorLine = Color(0xFFF0C7C7);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _errorTint,
        border: Border.all(color: _errorLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 17, color: _errorInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppText.body(size: 12.5, color: _errorInk, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Local copy of the landing page's tricolor strip (that one is private).
class _TricolorStrip extends StatelessWidget {
  const _TricolorStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: Row(
        children: [
          Expanded(child: Container(color: AppColors.saffron)),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.line, width: 0.5),
                  bottom: BorderSide(color: AppColors.line, width: 0.5),
                ),
              ),
            ),
          ),
          Expanded(child: Container(color: AppColors.green)),
        ],
      ),
    );
  }
}
