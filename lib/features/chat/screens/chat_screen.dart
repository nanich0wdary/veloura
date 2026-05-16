// lib/features/chat/screens/chat_screen.dart
// Veloura — Chat Screen

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    // Scroll when new message arrives
    ref.listen(chatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, state),
      body: Stack(
        children: [
          // ── Animated background ──
          _AnimatedBackground(controller: _bgController),

          // ── Messages ──
          Column(
            children: [
              Expanded(
                child: _MessageList(
                  messages: state.messages,
                  isTyping: state.isPartnerTyping,
                  scrollController: _scrollController,
                  onReact: (messageId) async {
                    final emoji = await ReactionPicker.show(context);
                    if (emoji != null) {
                      ref
                          .read(chatProvider.notifier)
                          .addReaction(messageId, emoji);
                    }
                  },
                ),
              ),

              // ── Typing indicator ──
              if (state.isPartnerTyping)
                const TypingIndicator()
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.5, end: 0),

              // ── Input bar ──
              ChatInputBar(
                isSending: state.isSending,
                onSend: (text) {
                  ref.read(chatProvider.notifier).sendMessage(text);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ChatState state) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.6),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // Back
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // Avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFC084FC),
                            Color(0xFFF472B6)
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFC084FC).withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Name + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Ariana',
                            style: TextStyle(
                              fontFamily: 'Cormorant',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                state.isPartnerTyping
                                    ? 'typing...'
                                    : 'online · Mumbai',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: state.isPartnerTyping
                                      ? const Color(0xFFC084FC)
                                      : Colors.white38,
                                  fontFamily: 'Cormorant',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    IconButton(
                      icon: const Icon(Icons.photo_album_outlined,
                          size: 20, color: Colors.white54),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded,
                          size: 20, color: Colors.white54),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Message list ─────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.isTyping,
    required this.scrollController,
    required this.onReact,
  });

  final List<Message> messages;
  final bool isTyping;
  final ScrollController scrollController;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 90, 14, 8),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final showTime = i == 0 ||
            messages[i].timestamp
                    .difference(messages[i - 1].timestamp)
                    .inMinutes >
                15;
        return ChatBubble(
          message: msg,
          showTime: showTime,
          onLongPress: () => onReact(msg.id),
        );
      },
    );
  }
}

// ── Animated gradient background ────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                -0.5 + t * 0.4,
                -0.8 + t * 0.3,
              ),
              radius: 1.2,
              colors: const [
                Color(0xFF1E1035),
                Color(0xFF0F172A),
              ],
            ),
          ),
        );
      },
    );
  }
}
