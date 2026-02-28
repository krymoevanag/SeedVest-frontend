import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_service.dart';
import '../data/models/contribution.dart';

class ContributionsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _paymentError;
  String? get paymentError => _paymentError;

  List<Contribution> _contributions = [];
  List<Contribution> get contributions => _contributions;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> get members => _members;

  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> get groups => _groups;

  Future<void> fetchUsersAndGroups() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _apiService.getUsers(approvedOnly: true),
        _apiService.getGroups(),
      ]);
      final membersList = (results[0].data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final groupsList = (results[1].data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _members = membersList;
      _groups = groupsList;
    } catch (e) {
      debugPrint('Error fetching users and groups: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchContributions() async {
    _setLoading(true);
    try {
      final response = await _apiService.getContributions();
      if (response.statusCode == 200) {
        final List data = response.data;
        _contributions = data.map((e) => Contribution.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching contributions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> initiatePayment(double amount, String phoneNumber) async {
    _setLoading(true);
    _paymentError = null;
    try {
      final response =
          await _apiService.initiateMpesaPayment(amount, phoneNumber);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Payment initiated successfully
        return true;
      }
      _paymentError = _extractErrorMessage(response.data) ??
          'Failed to initiate M-Pesa push.';
      return false;
    } on DioException catch (e) {
      _paymentError = _extractErrorMessage(e.response?.data) ??
          e.message ??
          'Failed to initiate M-Pesa push.';
      debugPrint('Error initiating payment: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      _paymentError = 'Failed to initiate M-Pesa push.';
      debugPrint('Error initiating payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> proposeManualContribution({
    int? groupId,
    required double amount,
    DateTime? reportedPaidDate,
    String? paymentMethod,
    String? reference,
    String? note,
  }) async {
    _setLoading(true);
    try {
      final payload = <String, dynamic>{
        'amount': amount,
        'reported_paid_date': (reportedPaidDate ?? DateTime.now())
            .toIso8601String()
            .split('T')[0],
      };
      if (groupId != null) {
        payload['group_id'] = groupId;
      }
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        payload['reported_payment_method'] = paymentMethod;
      }
      if (reference != null && reference.trim().isNotEmpty) {
        payload['reported_reference'] = reference.trim();
      }
      if (note != null && note.trim().isNotEmpty) {
        payload['reported_note'] = note.trim();
      }

      final response = await _apiService.proposeManualContribution(payload);
      if (response.statusCode == 201) {
        await fetchContributions();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error submitting manual contribution proposal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveContribution(int id) async {
    _setLoading(true);
    try {
      final response = await _apiService.approveContribution(id);
      if (response.statusCode == 200) {
        await fetchContributions(); // Refresh list
      }
    } catch (e) {
      debugPrint('Error approving contribution: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectContribution(int id) async {
    _setLoading(true);
    try {
      final response = await _apiService.rejectContribution(id);
      if (response.statusCode == 200) {
        await fetchContributions(); // Refresh list
      }
    } catch (e) {
      debugPrint('Error rejecting contribution: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> adminAddContribution({
    required int userId,
    required int groupId,
    required double amount,
    String? paidDate,
  }) async {
    _setLoading(true);
    try {
      final data = <String, dynamic>{
        'user_id': userId,
        'group_id': groupId,
        'amount': amount,
      };
      if (paidDate != null) {
        data['paid_date'] = paidDate;
      }
      final response = await _apiService.adminAddContribution(data);
      if (response.statusCode == 201) {
        await fetchContributions();
        return null;
      } else {
        return 'Failed to add contribution';
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e.response?.data) ??
          e.message ??
          'Failed to add contribution';
      debugPrint('Error adding contribution: $errorMessage');
      return errorMessage;
    } catch (e) {
      debugPrint('Error adding contribution: $e');
      return 'An unexpected error occurred.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map) {
      const keys = [
        'error',
        'detail',
        'message',
        'ResponseDescription',
        'CustomerMessage',
        'group_id',
        'user_id',
        'non_field_errors'
      ];
      for (final key in keys) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        } else if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }
}
