import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_patient_screen.dart';
import 'patient_list_screen.dart';
import 'backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;

  static const Color deepTeal = Color(0xFF0F5C5C);
  static const Color teal = Color(0xFF14B8A6);
  static const Color gold = Color(0xFFD4A24C);
  static const Color bg = Color(0xFFF4FBFA);
  static const Color ink = Color(0xFF0B2B2B);

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Animation<double> _fadeSlide(double startInterval) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(startInterval, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel("QUICK ACTIONS"),

                    const SizedBox(height: 14),

                    _animatedEntry(
                      interval: 0.15,
                      child: _actionCard(
                        icon: Icons.person_add_alt_1_rounded,
                        iconBg: teal,
                        title: "Add Patient",
                        subtitle: "Register a new patient record",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddPatientScreen(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _animatedEntry(
                      interval: 0.3,
                      child: _actionCard(
                        icon: Icons.groups_rounded,
                        iconBg: deepTeal,
                        title: "Patient List",
                        subtitle: "View ledgers, loans & payments",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PatientListScreen(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _animatedEntry(
                      interval: 0.38,
                      child: _actionCard(
                        icon: Icons.backup_outlined,
                        iconBg: gold,
                        title: "Backup & Restore",
                        subtitle: "Keep your data safe from phone loss",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BackupScreen(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    _animatedEntry(
                      interval: 0.45,
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => _confirmExit(context),
                          icon: const Icon(
                            Icons.power_settings_new_rounded,
                            color: Colors.black45,
                            size: 18,
                          ),
                          label: const Text(
                            "Exit App",
                            style: TextStyle(
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
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
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.2,
        color: Color(0xFF7A9A98),
      ),
    );
  }

  Widget _animatedEntry({required double interval, required Widget child}) {
    final anim = _fadeSlide(interval);

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 24),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 56),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deepTeal, teal],
          ),
        ),
        child: Row(
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.06).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gold.withOpacity(0.7),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Falcon Medicose",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Patient Ledger & Care Records",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
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

  Widget _actionCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: deepTeal.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconBg, size: 24),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: ink.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: ink.withOpacity(0.28),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Exit App"),
        content: const Text(
          "Are you sure you want to close Falcon Medicose?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _forceExit();
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }
}

Future<void> _forceExit() async {
  // First try the normal, OS-friendly way of leaving the app.
  await SystemNavigator.pop();

  // On some Android devices/launchers SystemNavigator.pop() only
  // minimizes the app instead of fully closing it. As a guaranteed
  // fallback, forcefully end the process shortly after.
  await Future.delayed(const Duration(milliseconds: 300));
  exit(0);
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
