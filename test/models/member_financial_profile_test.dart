import 'package:flutter_test/flutter_test.dart';
import 'package:seedvest_mobile/data/models/member_financial_profile.dart';

void main() {
  group('MemberFinancialProfile Model Tests', () {
    test('successfully parses stringified decimals from backend DRF serializer', () {
      final json = {
        'member': {
          'id': 101,
          'name': 'Grace Hopper',
          'email': 'grace@seedvest.org',
          'membership_number': 'MBR-2026-0042',
        },
        'total_savings': '15500.50',
        'total_contributions': '18000.00',
        'total_penalties': '200.00',
        'total_investments': '5000.00',
        'active_loans': 2,
        'outstanding_balance': '3400.75',
        'overdue_loans': 1,
        'overdue_balance': '1200.00',
        'total_repayments': '4500.00',
        'net_position': '16900.25',
      };

      final profile = MemberFinancialProfile.fromJson(json);

      expect(profile.member.id, equals(101));
      expect(profile.member.name, equals('Grace Hopper'));
      expect(profile.member.email, equals('grace@seedvest.org'));
      expect(profile.member.membershipNumber, equals('MBR-2026-0042'));
      expect(profile.totalSavings, equals(15500.50));
      expect(profile.totalContributions, equals(18000.00));
      expect(profile.totalPenalties, equals(200.00));
      expect(profile.totalInvestments, equals(5000.00));
      expect(profile.activeLoans, equals(2));
      expect(profile.outstandingBalance, equals(3400.75));
      expect(profile.overdueLoans, equals(1));
      expect(profile.overdueBalance, equals(1200.00));
      expect(profile.totalRepayments, equals(4500.00));
      expect(profile.netPosition, equals(16900.25));
    });

    test('successfully parses numeric primitive numbers', () {
      final json = {
        'member': {
          'id': 202,
          'name': 'Ada Lovelace',
          'email': 'ada@seedvest.org',
        },
        'total_savings': 5000,
        'total_contributions': 6000.5,
        'total_penalties': 0,
        'total_investments': 1000,
        'active_loans': 0,
        'outstanding_balance': 0.0,
        'overdue_loans': 0,
        'overdue_balance': 0.0,
        'total_repayments': 0,
        'net_position': 6000,
      };

      final profile = MemberFinancialProfile.fromJson(json);

      expect(profile.member.id, equals(202));
      expect(profile.member.name, equals('Ada Lovelace'));
      expect(profile.totalSavings, equals(5000.0));
      expect(profile.totalContributions, equals(6000.5));
      expect(profile.totalPenalties, equals(0.0));
      expect(profile.netPosition, equals(6000.0));
    });

    test('gracefully defaults missing and null fields to safe zeros', () {
      final json = <String, dynamic>{
        'member': null,
      };

      final profile = MemberFinancialProfile.fromJson(json);

      expect(profile.member.id, equals(0));
      expect(profile.member.name, isEmpty);
      expect(profile.totalSavings, equals(0.0));
      expect(profile.totalPenalties, equals(0.0));
      expect(profile.activeLoans, equals(0));
      expect(profile.outstandingBalance, equals(0.0));
      expect(profile.netPosition, equals(0.0));
    });

    test('roundtrips to JSON correctly', () {
      final profile = MemberFinancialProfile(
        member: MemberProfileInfo(
          id: 55,
          name: 'Test Member',
          email: 'test@example.com',
          membershipNumber: 'MBR-0055',
        ),
        totalSavings: 2000.0,
        totalContributions: 2500.0,
        totalPenalties: 50.0,
        totalInvestments: 500.0,
        activeLoans: 1,
        outstandingBalance: 300.0,
        overdueLoans: 0,
        overdueBalance: 0.0,
        totalRepayments: 100.0,
        netPosition: 2150.0,
      );

      final json = profile.toJson();
      expect(json['member']['id'], equals(55));
      expect(json['total_savings'], equals(2000.0));
      expect(json['net_position'], equals(2150.0));
    });
  });
}
