// lib/features/chat/widgets/chat_bubble.dart
// Veloura — Glass Chat Bubble

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.onLongPress,
    this.showTime = false,
  });

  final Message message;
  final VoidCallback onLongPress;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: message.isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 10),
              child: Center(
                child: Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white30,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          GestureDetector(
            onLongPress: onLongPress,
            child: Row(
              mainAxisAlignment: message.isMine
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Partner avatar
                if (!message.isMine) ...[
                  _Avatar(),
                  const SizedBox(width: 8),
                ],

                // Bubble
                _Bubble(message: message),

                // My status tick
                if (message.isMine) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: message.status),
                ],
              ],
            ),
          ),

          // Reaction
          if (message.reaction != null)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: message.isMine ? 0 : 48,
                right: message.isMine ? 8 : 0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  message.reaction!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0, 0),
                    duration: 300.ms,
                    curve: Curves.elasticOut),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(
          begin: message.isMine ? 0.2 : -0.2,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Partner avatar dot ──────────────────────────────────────

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC084FC).withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 11,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Glass bubble ────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final maxW = MediaQuery.of(context).size.width * 0.68;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMine
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFC084FC).withOpacity(0.25),
                        const Color(0xFFF472B6).withOpacity(0.18),
                      ],
                    )
                  : null,
              color: isMine
                  ? null
                  : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              border: Border.all(
                color: isMine
                    ? const Color(0xFFC084FC).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
              boxShadow: isMine
                  ? [
                      BoxShadow(
                        color:
                            const Color(0xFFC084FC).withOpacity(0.15),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontFamily: 'Cormorant',
                fontSize: 16,
                height: 1.5,
                color: isMine
                    ? Colors.white
                    : Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Message status icon ─────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white30,
          ),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded,
            size: 14, color: Colors.white38);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Colors.white38);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Color(0xFFC084FC));
    }
  }
}
