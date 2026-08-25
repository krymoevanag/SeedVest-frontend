import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_service.dart';
import '../data/models/loan.dart';

class LoanViewModel extends ChangeNotifier {
  LoanViewModel({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  final List<Loan> _loans = [];
  final List<Map<String, dynamic>> _groups = [];
  final List<Map<String, dynamic>> _eligibleGuarantors = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<Loan> get loans => List.unmodifiable(_loans);
  List<Map<String, dynamic>> get groups => List.unmodifiable(_groups);
  List<Map<String, dynamic>> get eligibleGuarantors =>
      List.unmodifiable(_eligibleGuarantors);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Future<void> initialise() async {
    await Future.wait([fetchLoans(), fetchGroups()]);
  }

  Future<void> fetchLoans({int? groupId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.getLoans(groupId: groupId);
      _loans
        ..clear()
        ..addAll(_asList(response.data).map(Loan.fromJson));
    } catch (error) {
      _error = _errorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGroups() async {
    try {
      final response = await _apiService.getGroups();
      _groups
        ..clear()
        ..addAll(
          _asList(response.data)
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      notifyListeners();
    } catch (error) {
      _error ??= _errorMessage(error);
      notifyListeners();
    }
  }

  Future<void> fetchEligibleGuarantors(int groupId) async {
    _eligibleGuarantors.clear();
    notifyListeners();
    try {
      final response = await _apiService.getEligibleGuarantors(groupId);
      _eligibleGuarantors.addAll(
        _asList(response.data)
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
    } catch (error) {
      _error = _errorMessage(error);
    } finally {
      notifyListeners();
    }
  }

  Future<bool> applyLoan({
    required int groupId,
    required double amount,
    required double interestRate,
    required int durationMonths,
    required String purpose,
    required List<int> guarantorUserIds,
  }) async {
    return await _submit(() async {
      return await _apiService.applyLoan({
        'group_id': groupId,
        'amount': amount.toStringAsFixed(2),
        'interest_rate': interestRate.toStringAsFixed(2),
        'duration_months': durationMonths,
        'purpose': purpose.trim(),
        'guarantor_user_ids': guarantorUserIds,
      });
    });
  }

  Future<bool> respondToGuarantee(int loanId, bool accepted,
      {String notes = ''}) async {
    return await _submit(() => _apiService.respondGuarantor(loanId, {
          'status': accepted ? 'ACCEPTED' : 'REJECTED',
          'notes': notes.trim(),
        }));
  }

  Future<bool> approveLoan(int loanId) async {
    return await _submit(() => _apiService.approveLoan(loanId));
  }

  Future<bool> disburseLoan(int loanId) async {
    return await _submit(() => _apiService.disburseLoan(loanId));
  }

  Future<bool> submitRepayment({
    required int loanId,
    required double amount,
    required String paymentMethod,
    String transactionReference = '',
    String notes = '',
  }) async {
    return await _submit(() => _apiService.makeLoanRepayment(loanId, {
          'amount': amount.toStringAsFixed(2),
          'payment_method': paymentMethod,
          'transaction_reference': transactionReference.trim(),
          'notes': notes.trim(),
        }));
  }

  Future<bool> verifyRepayment(int loanId, int repaymentId) async {
    return await _submit(
        () => _apiService.verifyLoanRepayment(loanId, repaymentId));
  }

  double calculateTotalPayable({
    required double amount,
    required double interestRate,
    required int durationMonths,
  }) {
    return amount * (1 + ((interestRate / 100) * durationMonths));
  }

  Future<bool> _submit(Future<Response<dynamic>> Function() operation) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await operation();
      await fetchLoans();
      return true;
    } catch (error) {
      _error = _errorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    final rawList = data is List
        ? data
        : (data is Map && data['results'] is List
            ? data['results'] as List
            : const []);
    return rawList
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData.isNotEmpty) {
        final firstValue = responseData.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue.toString();
      }
      return error.message ?? 'The loan request could not be completed.';
    }
    return 'The loan request could not be completed.';
  }
}
