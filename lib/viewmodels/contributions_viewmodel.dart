import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/contribution.dart';

class ContributionsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Contribution> _contributions = [];
  List<Contribution> get contributions => _contributions;

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
    try {
      final response =
          await _apiService.initiateMpesaPayment(amount, phoneNumber);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Payment initiated successfully
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error initiating payment: $e');
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
