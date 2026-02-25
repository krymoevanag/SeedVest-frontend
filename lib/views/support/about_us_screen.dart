import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About SeedVest')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'About Us',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 14),
          Text(
            'SeedVest is a financial governance and growth platform designed to simplify group contributions, improve transparency, and support accountability.',
          ),
          SizedBox(height: 18),
          _AboutBlock(
            title: 'Our Mission',
            content:
                'To help communities and groups manage contributions, savings, and governance with confidence and clarity.',
          ),
          SizedBox(height: 12),
          _AboutBlock(
            title: 'What We Provide',
            content:
                'Member onboarding, approval workflows, contribution tracking, payment support, penalties, role management, and notifications.',
          ),
          SizedBox(height: 12),
          _AboutBlock(
            title: 'Core Values',
            content:
                'Transparency, accountability, financial discipline, and inclusive growth.',
          ),
          SizedBox(height: 12),
          _AboutBlock(
            title: 'Support Contacts',
            content:
                '0708873060 / 0796649625\nseedvest.app@gmail.com\nkirimievansgitonga@gmail.com',
          ),
          SizedBox(height: 24),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _AboutBlock extends StatelessWidget {
  final String title;
  final String content;

  const _AboutBlock({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(content),
        ],
      ),
    );
  }
}
