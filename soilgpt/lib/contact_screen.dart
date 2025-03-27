import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // Function to launch URLs
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/logo.png'), // Ensure logo.png exists
              ),
            ),
            const SizedBox(height: 20),

            // Contact Info
            const Text(
              'Get in Touch',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Email
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('support@soilgpt.com'),
              onTap: () => _launchURL('mailto:support@soilgpt.com'),
            ),

            // Phone
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('+91 9876543210'),
              onTap: () => _launchURL('tel:+919876543210'),
            ),

            // Website
            ListTile(
              leading: const Icon(Icons.web, color: Colors.orange),
              title: const Text('Visit Website'),
              onTap: () => _launchURL('https://soilgpt.com'),
            ),

            const SizedBox(height: 20),

            // Social Media Links
            const Text(
              'Follow Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.facebook, color: Colors.blue, size: 30),
                  onPressed: () => _launchURL('https://facebook.com/soilgpt'),
                ),
                IconButton(
                  icon: const Icon(Icons.linked_camera, color: Colors.red, size: 30),
                  onPressed: () => _launchURL('https://instagram.com/soilgpt'),
                ),
                IconButton(
                  icon: const Icon(Icons.alternate_email, color: Colors.lightBlue, size: 30),
                  onPressed: () => _launchURL('https://twitter.com/soilgpt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
