// lib/features/pairing/screens/pairing_screen.dart
// Veloura — Pairing Screen (QR + Code entry)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/pairing_provider.dart';
import '../widgets/qr_display.dart';
import '../widgets/connected_card.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bg.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pairingProvider);
    final notifier = ref.read(pairingProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _appBar(context),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bg,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    -0.3 + _bg.value * 0.4,
                    -0.6 + _bg.value * 0.3,
                  ),
                  radius: 1.4,
                  colors: const [Color(0xFF1E1035), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFFC084FC), strokeWidth: 2))
                : state.isPaired
                    ? _paired(state, notifier)
                    : _unpaired(state, notifier),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.6),
              border: Border(bottom: BorderSide(
                  color: Colors.white.withOpacity(0.07), width: 0.5)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text('PAIR DEVICES',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                              fontSize: 13, color: Colors.white,
                              letterSpacing: 4)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paired(PairingState state, PairingNotifier notifier) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: ConnectedCard(
          pairData: state.pairData!, onUnpair: notifier.unpair),
    );
  }

  Widget _unpaired(PairingState state, PairingNotifier notifier) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        children: [
          Text('Connect with your person',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22, color: Colors.white70,
                fontStyle: FontStyle.italic),
              textAlign: TextAlign.center)
              .animate().fadeIn(duration: 600.ms),

          const SizedBox(height: 6),

          Text('Both devices must have Veloura installed',
              style: GoogleFonts.cinzel(
                  fontSize: 9, color: Colors.white24, letterSpacing: 1.5))
              .animate().fadeIn(delay: 200.ms, duration: 600.ms),

          const SizedBox(height: 20),

          // Name field
          _nameField(state, notifier),

          const SizedBox(height: 20),

          // Tab toggle
          _tabToggle(),

          const SizedBox(height: 20),

          // Tab content
          if (_tab == 0)
            QrDisplay(
              data: state.pairData?.qrPayload ?? 'veloura',
              pairCode: state.pairData?.pairCode ?? 'VELO-XXXX',
            )
          else
            _codeEntry(state, notifier),

          // Error
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2), width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: Colors.red.withOpacity(0.7), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(state.error!,
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 14,
                            color: Colors.red.withOpacity(0.8))),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).shakeX(duration: 400.ms),
          ],

          const SizedBox(height: 20),

          // Demo button
          GestureDetector(
            onTap: state.isLoading ? null : notifier.simulatePairing,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline_rounded,
                      color: Colors.white24, size: 16),
                  const SizedBox(width: 8),
                  Text('Demo — Simulate Pairing',
                      style: GoogleFonts.cinzel(
                          fontSize: 10, color: Colors.white24,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _nameField(PairingState state, PairingNotifier notifier) {
    if (_nameCtrl.text.isEmpty && state.pairData?.displayName != 'You') {
      _nameCtrl.text = state.pairData?.displayName ?? '';
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  color: Colors.white38, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 16, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Your name...',
                    hintStyle: GoogleFonts.cormorantGaramond(
                        fontSize: 15, color: Colors.white24,
                        fontStyle: FontStyle.italic),
                    border: InputBorder.none, isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: notifier.setDisplayName,
                ),
              ),
              GestureDetector(
                onTap: () => notifier.setDisplayName(_nameCtrl.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC084FC).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('SAVE',
                      style: GoogleFonts.cinzel(
                          fontSize: 9, color: const Color(0xFFC084FC),
                          letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms);
  }

  Widget _tabToggle() {
    return Row(
      children: [
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _tab = 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: _tab == 0
                  ? const LinearGradient(
                      colors: [Color(0xFFC084FC), Color(0xFFF472B6)])
                  : null,
              color: _tab == 0 ? null : Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              border: Border.all(
                color: _tab == 0 ? Colors.transparent
                    : Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_rounded, size: 16,
                    color: _tab == 0 ? Colors.white : Colors.white38),
                const SizedBox(width: 8),
                Text('MY QR',
                    style: GoogleFonts.cinzel(fontSize: 10, letterSpacing: 1.5,
                        color: _tab == 0 ? Colors.white : Colors.white38)),
              ],
            ),
          ),
        )),
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _tab = 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: _tab == 1
                  ? const LinearGradient(
                      colors: [Color(0xFFC084FC), Color(0xFFF472B6)])
                  : null,
              color: _tab == 1 ? null : Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16)),
              border: Border.all(
                color: _tab == 1 ? Colors.transparent
                    : Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_rounded, size: 16,
                    color: _tab == 1 ? Colors.white : Colors.white38),
                const SizedBox(width: 8),
                Text('ENTER CODE',
                    style: GoogleFonts.cinzel(fontSize: 10, letterSpacing: 1.5,
                        color: _tab == 1 ? Colors.white : Colors.white38)),
              ],
            ),
          ),
        )),
      ],
    ).animate().fadeIn(delay: 350.ms, duration: 600.ms);
  }

  Widget _codeEntry(PairingState state, PairingNotifier notifier) {
    return Column(
      children: [
        Text('Ask your partner for their Pair Code',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 16, color: Colors.white54,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center)
            .animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Cinzel', fontSize: 24,
                        color: Colors.white, letterSpacing: 6),
                    decoration: InputDecoration(
                      hintText: 'XXXX-XXXX',
                      hintStyle: TextStyle(
                          fontFamily: 'Cinzel', fontSize: 22,
                          color: Colors.white.withOpacity(0.15),
                          letterSpacing: 6),
                      border: InputBorder.none, isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(9)],
                    onSubmitted: (_) => _submitCode(notifier),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _submitCode(notifier),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFC084FC), Color(0xFFF472B6)]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                            color: const Color(0xFFC084FC).withOpacity(0.3),
                            blurRadius: 14)],
                      ),
                      child: state.isLoading
                          ? const Center(child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)))
                          : Text('CONNECT',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cinzel(
                                  fontSize: 12, color: Colors.white,
                                  letterSpacing: 3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.1, end: 0, delay: 200.ms),
      ],
    );
  }

  void _submitCode(PairingNotifier notifier) {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final payload =
        '{"app":"veloura","version":"1","deviceId":"manual-${code.replaceAll('-','')}","pairCode":"$code","name":"Partner"}';
    notifier.connectFromQr(payload);
    _codeCtrl.clear();
  }
}
