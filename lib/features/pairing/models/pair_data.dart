// lib/features/pairing/models/pair_data.dart
// Veloura — Pairing Data Model

import 'dart:convert';
import 'dart:math';

enum PairingStatus { unpaired, waiting, connected }

class PairData {
  const PairData({
    required this.deviceId,
    required this.pairCode,
    required this.displayName,
    this.partnerId,
    this.partnerName,
    this.status = PairingStatus.unpaired,
    this.pairedAt,
  });

  final String deviceId;
  final String pairCode;
  final String displayName;
  final String? partnerId;
  final String? partnerName;
  final PairingStatus status;
  final DateTime? pairedAt;

  bool get isPaired => status == PairingStatus.connected;

  PairData copyWith({
    String? partnerId,
    String? partnerName,
    PairingStatus? status,
    DateTime? pairedAt,
  }) =>
      PairData(
        deviceId: deviceId,
        pairCode: pairCode,
        displayName: displayName,
        partnerId: partnerId ?? this.partnerId,
        partnerName: partnerName ?? this.partnerName,
        status: status ?? this.status,
        pairedAt: pairedAt ?? this.pairedAt,
      );

  // QR payload — what gets encoded into the QR code
  String get qrPayload => jsonEncode({
        'app': 'veloura',
        'version': '1',
        'deviceId': deviceId,
        'pairCode': pairCode,
        'name': displayName,
      });

  static PairData? fromQrPayload(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['app'] != 'veloura') return null;
      return PairData(
        deviceId: map['deviceId'] as String,
        pairCode: map['pairCode'] as String,
        displayName: map['name'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
        'deviceId': deviceId,
        'pairCode': pairCode,
        'displayName': displayName,
        'partnerId': partnerId,
        'partnerName': partnerName,
        'status': status.index,
        'pairedAt': pairedAt?.toIso8601String(),
      };

  factory PairData.fromMap(Map<String, dynamic> m) => PairData(
        deviceId: m['deviceId'] as String,
        pairCode: m['pairCode'] as String,
        displayName: m['displayName'] as String,
        partnerId: m['partnerId'] as String?,
        partnerName: m['partnerName'] as String?,
        status: PairingStatus.values[m['status'] as int? ?? 0],
        pairedAt: m['pairedAt'] != null
            ? DateTime.parse(m['pairedAt'] as String)
            : null,
      );

  String toJson() => jsonEncode(toMap());
  factory PairData.fromJson(String s) =>
      PairData.fromMap(jsonDecode(s) as Map<String, dynamic>);
}

// ── Code Generator ───────────────────────────────────────────

class PairCodeGenerator {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _rng = Random.secure();

  /// Generates a readable 8-char pair code e.g. "VELO-4K7X"
  static String generate() {
    final raw = List.generate(8, (_) => _chars[_rng.nextInt(_chars.length)]).join();
    return '${raw.substring(0, 4)}-${raw.substring(4)}';
  }

  /// Generates a unique device ID
  static String deviceId() {
    return List.generate(16, (_) => _rng.nextInt(16).toRadixString(16)).join();
  }
}
