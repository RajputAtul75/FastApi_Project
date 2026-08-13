/// Premium landing screen with Ashoka Chakra motif, live ticket preview,
/// vertical step journey, capabilities grid, departments band, and footer.
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

// ---------------------------------------------------------------------------
// Design tokens — mirrors the web version's CSS custom properties.
// ---------------------------------------------------------------------------
class AppColors {
  static const navy = Color(0xFF0C2340);
  static const navy2 = Color(0xFF153A66);
  static const saffron = Color(0xFFE1650E);
  static const saffronTint = Color(0xFFFCE4D0);
  static const green = Color(0xFF0B7A3C);
  static const greenTint = Color(0xFFDBEEE1);
  static const paper = Color(0xFFFBF9F4);
  static const paperCard = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B1F27);
  static const slate = Color(0xFF5B6472);
  static const line = Color(0xFFE6E1D3);
}

class AppText {
  static TextStyle display({double size = 26, FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color ?? AppColors.navy, height: 1.1);

  static TextStyle body({double size = 14.5, FontWeight weight = FontWeight.w400, Color? color, double? height}) =>
      GoogleFonts.ibmPlexSans(fontSize: size, fontWeight: weight, color: color ?? AppColors.ink, height: height ?? 1.5);

  static TextStyle mono({double size = 12.5, FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color ?? AppColors.slate);
}

// ---------------------------------------------------------------------------
// PAGE
// ---------------------------------------------------------------------------
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _chakraController;
  final ScrollController _scrollController = ScrollController();

  // Keys for section scrolling
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _capabilitiesKey = GlobalKey();
  final GlobalKey _departmentsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _chakraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 70),
    )..repeat();
  }

  @override
  void dispose() {
    _chakraController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleNavigation(String destination) {
    switch (destination) {
      case 'How it works':
        _scrollToSection(_howItWorksKey);
        break;
      case 'Capabilities':
        _scrollToSection(_capabilitiesKey);
        break;
      case 'For departments':
      case 'Departments':
        _scrollToSection(_departmentsKey);
        break;
      case 'Report a Grievance':
      case 'Report a grievance':
        context.read<AppState>().switchToCitizen();
        Navigator.pushNamed(context, '/submit');
        break;
      case 'Track Complaint':
      case 'Track My Complaint':
      case 'Track a complaint':
      case 'Status & routing':
        context.read<AppState>().switchToCitizen();
        Navigator.pushNamed(context, '/track');
        break;
      case 'Admin Dashboard':
      case 'Admin dashboard':
        context.read<AppState>().switchToAdmin();
        Navigator.pushNamed(context, '/admin');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      endDrawer: _NavDrawer(
        onNavTap: (label) {
          Navigator.of(context).pop(); // Close drawer
          _handleNavigation(label);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TricolorStrip(),
              _Header(onMenuTap: () => Scaffold.of(context).openEndDrawer()),
              _HeroSection(
                chakraController: _chakraController,
                onReport: () => _handleNavigation('Report a Grievance'),
                onTrack: () => _handleNavigation('Track Complaint'),
                onAdmin: () => _handleNavigation('Admin Dashboard'),
              ),
              _HowItWorksSection(key: _howItWorksKey),
              _CapabilitiesSection(key: _capabilitiesKey),
              _DepartmentsBand(key: _departmentsKey),
              _Footer(onLinkTap: _handleNavigation),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ashoka Chakra — the page's signature motif, drawn procedurally.
// ---------------------------------------------------------------------------
class AshokaChakra extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const AshokaChakra({super.key, required this.size, required this.color, this.strokeWidth = 2.2});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ChakraPainter(color: color, strokeWidth: strokeWidth)),
    );
  }
}

class _ChakraPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _ChakraPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 * 0.92;
    final innerR = size.width / 2 * 0.34;
    final hubR = size.width / 2 * 0.06;

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, outerR, ringPaint);
    canvas.drawCircle(center, innerR, ringPaint);
    canvas.drawCircle(center, hubR, Paint()..color = color);

    final spokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 24; i++) {
      final angle = (i * 15) * pi / 180;
      final inner = Offset(center.dx + innerR * sin(angle), center.dy - innerR * cos(angle));
      final outer = Offset(center.dx + outerR * sin(angle), center.dy - outerR * cos(angle));
      canvas.drawLine(inner, outer, spokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChakraPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

// ---------------------------------------------------------------------------
// Tricolor strip
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final VoidCallback onMenuTap;
  const _Header({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.96),
        border: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const AshokaChakra(size: 30, color: AppColors.navy, strokeWidth: 2.6),
          const SizedBox(width: 10),
          Text('NyayaAI', style: AppText.display(size: 20, weight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded, color: AppColors.navy),
            tooltip: 'Menu',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation Drawer
// ---------------------------------------------------------------------------
class _NavDrawer extends StatelessWidget {
  final void Function(String label) onNavTap;
  const _NavDrawer({required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.paper,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AshokaChakra(size: 28, color: AppColors.navy, strokeWidth: 2.4),
                  const SizedBox(width: 10),
                  Text('NyayaAI', style: AppText.display(size: 19)),
                ],
              ),
              const SizedBox(height: 32),
              _drawerLink('How it works'),
              _drawerLink('Capabilities'),
              _drawerLink('For departments'),
              _drawerLink('Admin Dashboard'),
              const Spacer(),
              OutlinedButton(
                onPressed: () => onNavTap('Track Complaint'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: const Text('Track Complaint'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => onNavTap('Report a Grievance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: const Text('Report a Grievance'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerLink(String label) {
    return InkWell(
      onTap: () => onNavTap(label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label, style: AppText.body(size: 16, weight: FontWeight.w500, color: AppColors.navy)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Section
// ---------------------------------------------------------------------------
class _HeroSection extends StatelessWidget {
  final AnimationController chakraController;
  final VoidCallback onReport;
  final VoidCallback onTrack;
  final VoidCallback onAdmin;

  const _HeroSection({required this.chakraController, required this.onReport, required this.onTrack, required this.onAdmin});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 40,
          child: RotationTransition(
            turns: chakraController,
            child: AshokaChakra(size: 300, color: AppColors.navy.withValues(alpha: 0.07), strokeWidth: 2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow(label: 'GRIEVANCE REDRESSAL, REIMAGINED WITH AI'),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  style: AppText.display(size: 32, weight: FontWeight.w700),
                  children: const [
                    TextSpan(text: 'From complaint to resolution — '),
                    TextSpan(text: 'faster', style: TextStyle(color: AppColors.saffron)),
                    TextSpan(text: ', smarter, transparent.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "NyayaAI reads every citizen complaint, works out what it's really about, and sends it straight to the department that can fix it — with a ticket the citizen can track from submission to resolution.",
                style: AppText.body(size: 15.5, color: AppColors.slate, height: 1.6),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffron,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    textStyle: AppText.body(size: 15.5, weight: FontWeight.w600, color: Colors.white),
                  ),
                  child: const Text('Report a Grievance'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTrack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    textStyle: AppText.body(size: 15.5, weight: FontWeight.w600, color: AppColors.navy),
                  ),
                  child: const Text('Track My Complaint'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onAdmin,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.slate,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: AppText.body(size: 14.5, weight: FontWeight.w600),
                  ),
                  child: const Text('Continue as Admin'),
                ),
              ),
              const SizedBox(height: 34),
              Container(
                padding: const EdgeInsets.only(top: 22),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Stat(value: '4', label: 'status stages'),
                    _Stat(value: '8', label: 'departments'),
                    _Stat(value: '<2 min', label: 'to AI-triage'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const _TicketCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String label;
  const _Eyebrow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        border: Border.all(color: const Color(0xFFC3E3CD)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.saffron, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: AppText.mono(size: 10.5, weight: FontWeight.w500, color: AppColors.navy2).copyWith(letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.mono(size: 19, weight: FontWeight.w500, color: AppColors.navy)),
        const SizedBox(height: 2),
        Text(label, style: AppText.body(size: 11, color: AppColors.slate)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Live ticket preview
// ---------------------------------------------------------------------------
class _TicketCard extends StatefulWidget {
  const _TicketCard();

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 16))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRV-2026-0142', style: AppText.mono(size: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.greenTint, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: Tween(begin: 0.35, end: 1.0).animate(_pulseController),
                      child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 6),
                    Text('AI Classified', style: AppText.body(size: 10.5, weight: FontWeight.w600, color: AppColors.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Pothole near college gate', style: AppText.display(size: 17, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            '"There is a large pothole near the college entrance. It is dangerous for vehicles and has already caused accidents."',
            style: AppText.body(size: 12.5, color: AppColors.slate, height: 1.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge('Road & Infrastructure', const Color(0xFFEAF1FB), const Color(0xFF1A4A8A)),
              _badge('Priority: High', AppColors.saffronTint, const Color(0xFF9A4106)),
              _badge('Municipal Corporation', const Color(0xFFF1EEFB), const Color(0xFF4B3A9C)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 16),
          const _MiniTimeline(),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: AppText.body(size: 11, weight: FontWeight.w600, color: fg)),
    );
  }
}

class _MiniTimeline extends StatelessWidget {
  const _MiniTimeline();

  static const _stages = ['Submitted', 'Assigned', 'In Progress', 'Resolved'];
  static const _doneCount = 2;
  static const _activeIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_stages.length, (i) {
        final isDone = i < _doneCount;
        final isActive = i == _activeIndex;
        final dotColor = isDone ? AppColors.green : (isActive ? AppColors.saffron : AppColors.line);
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : (isDone ? AppColors.green : AppColors.line))),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isActive ? [BoxShadow(color: AppColors.saffronTint, blurRadius: 0, spreadRadius: 4)] : null,
                    ),
                  ),
                  Expanded(child: Container(height: 2, color: Colors.transparent)),
                ],
              ),
              const SizedBox(height: 6),
              Text(_stages[i], style: AppText.body(size: 9, color: AppColors.slate, weight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// How it works
// ---------------------------------------------------------------------------
class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({super.key});

  static const _steps = [
    (
      '01',
      AppColors.saffron,
      'Citizen reports',
      'Describe the problem in your own words, in any local language, with an optional photo as evidence.'
    ),
    (
      '02',
      AppColors.navy,
      'AI understands',
      'NyayaAI reads the complaint and works out its category, urgency, and the right department to handle it.'
    ),
    (
      '03',
      AppColors.navy2,
      'Routed & ticketed',
      "A ticket is issued instantly and the complaint lands directly on the responsible department's desk."
    ),
    (
      '04',
      AppColors.green,
      'Tracked to resolution',
      'The citizen follows progress with their ticket ID, from submission through to resolved.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow(label: 'THE JOURNEY'),
          const SizedBox(height: 16),
          Text('One complaint, four honest steps.', style: AppText.display(size: 24)),
          const SizedBox(height: 10),
          Text(
            'No portals to hunt through, no forms to resubmit to a different department. NyayaAI carries the complaint the whole way.',
            style: AppText.body(size: 14, color: AppColors.slate),
          ),
          const SizedBox(height: 32),
          for (int i = 0; i < _steps.length; i++) ...[
            _StepRow(
              number: _steps[i].$1,
              accent: _steps[i].$2,
              title: _steps[i].$3,
              description: _steps[i].$4,
            ),
            if (i != _steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Container(width: 2, height: 28, color: AppColors.line),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final Color accent;
  final String title;
  final String description;

  const _StepRow({required this.number, required this.accent, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 2), color: AppColors.paperCard),
          child: Text(number, style: AppText.mono(size: 15, weight: FontWeight.w500, color: accent)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(size: 16.5, weight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 6),
                Text(description, style: AppText.body(size: 13.5, color: AppColors.slate, height: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Capabilities
// ---------------------------------------------------------------------------
class _CapabilitiesSection extends StatelessWidget {
  const _CapabilitiesSection({super.key});

  static const _items = [
    (Icons.psychology_alt_outlined, AppColors.saffron, 'AI-powered understanding',
        "Every complaint is read for meaning — not just keywords — to determine what's actually being reported."),
    (Icons.translate_outlined, AppColors.navy, 'Multilingual-ready',
        'Citizens can describe an issue in their own language — the platform is built to process it as it grows.'),
    (Icons.alt_route_outlined, AppColors.navy, 'Smart department routing',
        'Complaints are sent to the department best placed to resolve them — automatically, on the first try.'),
    (Icons.timeline_outlined, AppColors.green, 'Transparent tracking',
        'Every ticket carries a clear status a citizen can check anytime — no follow-up calls required.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 48),
      decoration: const BoxDecoration(
        color: AppColors.paperCard,
        border: Border(
          top: BorderSide(color: AppColors.line),
          bottom: BorderSide(color: AppColors.line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow(label: 'WHAT MAKES IT WORK'),
          const SizedBox(height: 16),
          Text('Built to understand, not just collect, complaints.', style: AppText.display(size: 22)),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
            children: _items.map((item) => _CapabilityCard(icon: item.$1, accent: item.$2, title: item.$3, description: item.$4)).toList(),
          ),
        ],
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String description;

  const _CapabilityCard({required this.icon, required this.accent, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, color: accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 28, color: AppColors.navy),
                  const SizedBox(height: 14),
                  Text(title, style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.navy), maxLines: 2),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      description,
                      style: AppText.body(size: 11.5, color: AppColors.slate, height: 1.4),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Departments Band
// ---------------------------------------------------------------------------
class _DepartmentsBand extends StatelessWidget {
  const _DepartmentsBand({super.key});

  static const _depts = [
    ('Municipal Corporation', Color(0xFFE1650E)),
    ('Water Department', Color(0xFF4C8DFF)),
    ('Electricity Department', Color(0xFFFFC94C)),
    ('Sanitation Department', Color(0xFF0B7A3C)),
    ('Police Department', Color(0xFF8A7CE0)),
    ('Health Department', Color(0xFFE05C8A)),
    ('Education Department', Color(0xFF5BC0BE)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      child: Column(
        children: [
          Text(
            'One platform, coordinating across every civic department that touches a citizen\'s daily life.',
            textAlign: TextAlign.center,
            style: AppText.body(size: 16, color: Colors.white.withValues(alpha: 0.92), height: 1.5),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _depts
                .map((d) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: d.$2, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(d.$1, style: AppText.body(size: 12, weight: FontWeight.w500, color: Colors.white)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------
class _Footer extends StatelessWidget {
  final void Function(String destination) onLinkTap;
  const _Footer({required this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paper,
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AshokaChakra(size: 22, color: AppColors.navy, strokeWidth: 2.2),
              SizedBox(width: 8),
              Text('NyayaAI', style: TextStyle(fontFamily: 'Fraunces', fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"Nyaya" means justice — an AI system that makes sure every civic complaint is heard, routed, and followed through.',
            style: AppText.body(size: 12.5, color: AppColors.slate, height: 1.6),
          ),
          const SizedBox(height: 26),
          _FooterColumn(
            title: 'Platform',
            links: const ['How it works', 'Capabilities', 'Departments'],
            onLinkTap: onLinkTap,
          ),
          const SizedBox(height: 18),
          _FooterColumn(
            title: 'For Citizens',
            links: const ['Report a grievance', 'Track a complaint'],
            onLinkTap: onLinkTap,
          ),
          const SizedBox(height: 18),
          _FooterColumn(
            title: 'For Departments',
            links: const ['Admin dashboard', 'Status & routing'],
            onLinkTap: onLinkTap,
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 16),
          Text('Team NyayaAI · Smart India Hackathon 2026 · Problem Statement SIH1516',
              style: AppText.body(size: 11, color: AppColors.slate)),
          const SizedBox(height: 4),
          Text('Design concept — not a production government service', style: AppText.body(size: 11, color: AppColors.slate)),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> links;
  final void Function(String destination) onLinkTap;

  const _FooterColumn({required this.title, required this.links, required this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: AppText.body(size: 11, weight: FontWeight.w600, color: AppColors.slate).copyWith(letterSpacing: 0.8)),
        const SizedBox(height: 10),
        for (final l in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onLinkTap(l),
              child: Text(l, style: AppText.body(size: 13.5, weight: FontWeight.w500, color: AppColors.navy)),
            ),
          ),
      ],
    );
  }
}
