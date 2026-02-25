import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'SeedVest Terms & Conditions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'By using SeedVest, you agree to these terms. Please read them carefully.',
          ),
          SizedBox(height: 20),
          _SectionTitle('1. Account Responsibility'),
          Text(
            'You are responsible for your account credentials and all activities performed through your account.',
          ),
          SizedBox(height: 14),
          _SectionTitle('2. Contributions and Payments'),
          Text(
            'Contributions are processed using available payment channels. Delays or network issues from third-party providers may affect completion time.',
          ),
          SizedBox(height: 14),
          _SectionTitle('3. Membership and Governance'),
          Text(
            'Membership approval, role assignment, and governance actions follow organization rules and authorized admin decisions.',
          ),
          SizedBox(height: 14),
          _SectionTitle('4. Data and Privacy'),
          Text(
            'SeedVest stores only the information required to provide account, finance, and governance features.',
          ),
          SizedBox(height: 14),
          _SectionTitle('5. Service Availability'),
          Text(
            'We may update or maintain the platform periodically. Some services may be temporarily unavailable during maintenance.',
          ),
          SizedBox(height: 14),
          _SectionTitle('6. Limitation of Liability'),
          Text(
            'SeedVest is not liable for losses caused by user error, credential sharing, or external provider outages beyond our control.',
          ),
          SizedBox(height: 14),
          _SectionTitle('7. Contact'),
          Text(
            'For questions regarding these terms, contact support through the Help page.',
          ),
          SizedBox(height: 24),
          Text(
            'Last updated: February 25, 2026',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}
