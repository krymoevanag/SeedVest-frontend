import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String _phone1 = '0708873060';
  static const String _phone2 = '0796649625';
  static const String _email1 = 'seedvest.app@gmail.com';
  static const String _email2 = 'kirimievansgitonga@gmail.com';

  Future<void> _openUri(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open action on this device.')),
        );
      }
    }
  }

  String _toWaNumber(String phone) {
    if (phone.startsWith('0')) return '254${phone.substring(1)}';
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Need assistance?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reach us quickly by call, WhatsApp, or email.',
          ),
          const SizedBox(height: 20),
          _ContactCard(
            title: 'Call Support',
            subtitle: '$_phone1 or $_phone2',
            icon: Icons.call,
            color: Colors.green.shade700,
            onTap: () => _openUri(context, Uri.parse('tel:$_phone1')),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            title: 'WhatsApp Support',
            subtitle: 'Chat on $_phone1',
            icon: Icons.chat_bubble_outline,
            color: Colors.green.shade800,
            onTap: () => _openUri(
              context,
              Uri.parse('https://wa.me/${_toWaNumber(_phone1)}'),
            ),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            title: 'WhatsApp Alternate',
            subtitle: 'Chat on $_phone2',
            icon: Icons.chat_bubble_outline,
            color: Colors.teal.shade700,
            onTap: () => _openUri(
              context,
              Uri.parse('https://wa.me/${_toWaNumber(_phone2)}'),
            ),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            title: 'Email Support',
            subtitle: _email1,
            icon: Icons.email_outlined,
            color: Colors.blue.shade700,
            onTap: () => _openUri(
              context,
              Uri(
                scheme: 'mailto',
                path: _email1,
                queryParameters: {'subject': 'SeedVest Support Request'},
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            title: 'Email Alternate',
            subtitle: _email2,
            icon: Icons.alternate_email,
            color: Colors.indigo.shade700,
            onTap: () => _openUri(
              context,
              Uri(
                scheme: 'mailto',
                path: _email2,
                queryParameters: {'subject': 'SeedVest Support Request'},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new, size: 18),
      ),
    );
  }
}
