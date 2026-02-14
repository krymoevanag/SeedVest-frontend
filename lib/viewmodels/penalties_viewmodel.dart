import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/penalty.dart';

class PenaltiesViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  List<Penalty> _penalties = [];
  List<Penalty> get penalties => _penalties;

  Future<void> fetchPenalties() async {
    _setLoading(true);
    try {
      final response = await _apiService.getPenalties();
      if (response.statusCode == 200) {
        final List data = response.data;
        _penalties = data.map((e) => Penalty.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching penalties: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
