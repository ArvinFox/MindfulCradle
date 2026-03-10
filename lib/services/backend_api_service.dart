import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Centralized HTTP client for all calls to the Node.js backend.
/// Every request attaches the Firebase ID token for server-side auth.
class BackendApiService {
  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? '';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // ── Achievements ────────────────────────────────────────────────────────────

  /// Calls the backend to unlock an achievement.
  /// Returns the list of newly unlocked IDs (may include 'super_mom' chain).
  static Future<List<String>> unlockAchievement(String achievementId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/achievements/unlock'),
      headers: headers,
      body: jsonEncode({'achievementId': achievementId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['alreadyUnlocked'] == true) return [];
      return List<String>.from(data['unlockedIds'] ?? []);
    }

    throw Exception('Achievement unlock failed: ${response.statusCode}');
  }

  // ── Notifications ────────────────────────────────────────────────────────────

  /// Registers (or refreshes) the device FCM token with the backend
  /// so the server can send targeted push notifications to this device.
  static Future<void> registerFcmToken(String token) async {
    final headers = await _authHeaders();
    await http.put(
      Uri.parse('$baseUrl/api/notifications/token'),
      headers: headers,
      body: jsonEncode({'token': token}),
    );
  }

  // ── User ─────────────────────────────────────────────────────────────────────

  /// Triggers a full server-side account + data deletion using the Admin SDK.
  /// The caller should re-authenticate via Firebase before calling this.
  static Future<void> deleteAccount() async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/user/account'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Account deletion failed: ${response.statusCode}');
    }
  }
}
