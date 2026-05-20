import 'package:dio/dio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/payment_model.dart';

class PaymentService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://127.0.0.1:8000/api';

  String? _token() {
    try {
      return html.window.localStorage['access'];
    } catch (_) {
      return null;
    }
  }

  Options get _opts => Options(headers: {'Authorization': 'Bearer ${_token()}'});

  // ── Checkout ──────────────────────────────────────────
  Future<Transaction?> checkout({
    required int helpRequestId,
    required double amount,
    String note = '',
  }) async {
    try {
      final r = await _dio.post(
        '$baseUrl/payments/checkout/',
        data: {'help_request_id': helpRequestId, 'amount': amount, 'note': note},
        options: _opts,
      );
      return Transaction.fromJson(r.data);
    } catch (_) {
      return null;
    }
  }

  // ── Release escrow ────────────────────────────────────
  Future<Transaction?> release(int requestId) async {
    try {
      final r = await _dio.post(
        '$baseUrl/payments/release/$requestId/',
        options: _opts,
      );
      return Transaction.fromJson(r.data);
    } catch (_) {
      return null;
    }
  }

  // ── Tip ───────────────────────────────────────────────
  Future<Transaction?> sendTip({
    required int helpRequestId,
    required double amount,
  }) async {
    try {
      final r = await _dio.post(
        '$baseUrl/payments/tip/',
        data: {'help_request_id': helpRequestId, 'amount': amount},
        options: _opts,
      );
      return Transaction.fromJson(r.data);
    } catch (_) {
      return null;
    }
  }

  // ── Community pool ────────────────────────────────────
  Future<bool> contributeToPool(double amount, {String note = ''}) async {
    try {
      await _dio.post(
        '$baseUrl/payments/pool/contribute/',
        data: {'amount': amount, 'note': note},
        options: _opts,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Earnings ──────────────────────────────────────────
  Future<List<MonthlyEarning>> getEarnings() async {
    try {
      final r = await _dio.get('$baseUrl/payments/earnings/', options: _opts);
      return (r.data as List).map((e) => MonthlyEarning.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Pool info ─────────────────────────────────────────
  Future<CommunityPool?> getPool() async {
    try {
      final r = await _dio.get('$baseUrl/payments/pool/', options: _opts);
      return CommunityPool.fromJson(r.data);
    } catch (_) {
      return null;
    }
  }
}