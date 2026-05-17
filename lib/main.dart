import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/mood/screens/mood_screen.dart';
import 'features/memories/screens/memories_screen.dart';
import 'features/pairing/screens/pairing_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  runApp(const ProviderScope(child: VelouraApp()));
}

class VelouraApp extends ConsumerWidget {
  const VelouraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Veloura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC084FC),
          secondary: Color(0xFFF472B6),
        ),
      ),
      home: const SplashEntry(),
    );
  }
}

// ── Splash entry — shows splash then transitions to home ─────

class SplashEntry extends StatefulWidget {
  const SplashEntry({super.key});

  @override
  State<SplashEntry> createState() => _SplashEntryState();
}

class _SplashEntryState extends State<SplashEntry> {
  bool _showHome = false;

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return const HomeScreen();
    }
    return SplashScreen(
      onComplete: () => setState(() => _showHome = true),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _aura;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _aura = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _aura.dispose();
    super.dispose();
  }

  void _push(Widget screen) => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => screen,
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF1E1035), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VELOURA',
                        style: GoogleFonts.cinzel(
                            fontSize: 14,
                            color: const Color(0xFFC084FC),
                            letterSpacing: 4)),
                    _ConnectedPill(),
                  ],
                ),

                const SizedBox(height: 28),

                // Aura ring
                _AuraRing(controller: _aura)
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.7, 0.7),
                        duration: 1000.ms, curve: Curves.elasticOut),

                const SizedBox(height: 22),

                // Partner card
                _PartnerCard()
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.08, end: 0, delay: 200.ms),

                const SizedBox(height: 16),

                // Feature grid
                _FeatureGrid(onNavigate: _push)
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 600.ms)
                    .slideY(begin: 0.08, end: 0, delay: 350.ms),

                const SizedBox(height: 16),

                // Emotion row
                _EmotionRow()
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) _push(const ChatScreen());
          if (i == 2) _push(const MoodScreen());
          if (i == 3) _push(const MemoriesScreen());
        },
      ),
    );
  }
}

class _ConnectedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: Row(children: [
        Container(width: 6, height: 6,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF34D399))),
        const SizedBox(width: 5),
        Text('connected',
            style: GoogleFonts.cinzel(
                fontSize: 9, color: Colors.white38, letterSpacing: 1)),
      ]),
    );
  }
}

class _AuraRing extends StatelessWidget {
  const _AuraRing({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final glow = controller.value;
        return Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC084FC).withOpacity(0.2 + glow * 0.3),
                blurRadius: 30 + glow * 20, spreadRadius: 2 + glow * 4,
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Color(0xFFC084FC), Color(0xFFF472B6),
                Color(0xFF60A5FA), Color(0xFFC084FC),
              ]),
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF0F172A)),
              child: const Center(
                child: Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 34),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PartnerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        boxShadow: [BoxShadow(
            color: const Color(0xFFC084FC).withOpacity(0.07), blurRadius: 20)],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [Color(0xFFC084FC), Color(0xFFF472B6)]),
            boxShadow: [BoxShadow(
                color: const Color(0xFFC084FC).withOpacity(0.35),
                blurRadius: 12)],
          ),
          child: const Center(
            child: Text('A',
                style: TextStyle(fontFamily: 'Cinzel',
                    fontSize: 20, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ariana',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 20, fontWeight: FontWeight.w500,
                    color: Colors.white)),
            const SizedBox(height: 3),
            Row(children: [
              Container(width: 6, height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF34D399))),
              const SizedBox(width: 5),
              Text('online · 💗 Romantic',
                  style: TextStyle(fontSize: 12,
                      color: Colors.white.withOpacity(0.4),
                      fontFamily: 'Cormorant')),
            ]),
            const SizedBox(height: 5),
            Text('"thinking of you while the rain falls 🌧️"',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 13, color: Colors.white38,
                    fontStyle: FontStyle.italic)),
          ],
        )),
      ]),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.onNavigate});
  final void Function(Widget) onNavigate;

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.chat_bubble_outline_rounded, 'CHAT',
          [const Color(0xFFC084FC), const Color(0xFFF472B6)],
          const ChatScreen()),
      (Icons.auto_awesome_rounded, 'MOOD',
          [const Color(0xFF3B82F6), const Color(0xFFC084FC)],
          const MoodScreen()),
      (Icons.photo_album_outlined, 'MEMORIES',
          [const Color(0xFFF472B6), const Color(0xFFFBBF24)],
          const MemoriesScreen()),
      (Icons.qr_code_rounded, 'PAIRING',
          [const Color(0xFF34D399), const Color(0xFF3B82F6)],
          const PairingScreen()),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: features.map((f) => GestureDetector(
        onTap: () => onNavigate(f.$4),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              f.$3.first.withOpacity(0.15),
              f.$3.last.withOpacity(0.08),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: f.$3.first.withOpacity(0.25), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(f.$1, color: f.$3.first, size: 20),
              const SizedBox(width: 8),
              Text(f.$2,
                  style: GoogleFonts.cinzel(
                      fontSize: 11, color: Colors.white70,
                      letterSpacing: 1.5)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _EmotionRow extends StatefulWidget {
  @override
  State<_EmotionRow> createState() => _EmotionRowState();
}

class _EmotionRowState extends State<_EmotionRow> {
  final _sent = <String>{};

  void _tap(String key) {
    setState(() => _sent.add(key));
    Future.delayed(const Duration(seconds: 2),
        () => mounted ? setState(() => _sent.remove(key)) : null);
  }

  @override
  Widget build(BuildContext context) {
    final btns = [
      ('🤗', 'Hug'), ('💋', 'Kiss'), ('🌙', 'Miss You'),
      ('🛡', 'Safe'), ('✨', 'Thinking'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      alignment: WrapAlignment.center,
      children: btns.map((b) {
        final active = _sent.contains(b.$1);
        return GestureDetector(
          onTap: () => _tap(b.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFC084FC).withOpacity(0.18)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? const Color(0xFFC084FC).withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Text(
              active ? '${b.$1} Sent!' : '${b.$1} ${b.$2}',
              style: TextStyle(fontSize: 13,
                  color: active ? const Color(0xFFC084FC) : Colors.white54),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
      (Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Mood'),
      (Icons.photo_album_rounded, Icons.photo_album_outlined, 'Memories'),
    ];
    return Container(
      margin: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).padding.bottom + 10),
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final active = index == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: active
                    ? const Color(0xFFC084FC).withOpacity(0.15)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(active ? item.$1 : item.$2,
                      color: active
                          ? const Color(0xFFC084FC) : Colors.white30,
                      size: 20),
                  const SizedBox(height: 2),
                  Text(item.$3,
                      style: TextStyle(
                          fontFamily: 'Cinzel', fontSize: 8,
                          letterSpacing: 0.5,
                          color: active
                              ? const Color(0xFFC084FC) : Colors.white30)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
