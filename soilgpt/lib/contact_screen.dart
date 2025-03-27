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
      body: Stack(
        children: [
          // Light Green Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFb2f7b0), Color(0xFFd2f8d2)], // Light green gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Profile Avatar with Soft Shadow
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(3, 6),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 55,
                        backgroundImage: AssetImage('assets/images/img.jpg'), // Ensure the image exists
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Contact Info Cards
                  _buildInfoCard(
                    icon: Icons.email_rounded,
                    text: 'contact@clgcart.tech',
                    color: Colors.green.shade700,
                    onTap: () => _launchURL('mailto:contact@clgcart.tech'),
                  ),

                  _buildInfoCard(
                    icon: Icons.language_rounded,
                    text: 'Visit Website',
                    color: Colors.green.shade700,
                    onTap: () => _launchURL('https://github.com/itsAakashz/solution_challenge_proto'),
                  ),

                  const SizedBox(height: 25),

                  // Follow Us Section
                  const Text(
                    'Follow Us',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  // Social Media Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(Icons.facebook_rounded, Colors.blueAccent, '#'),
                      _buildSocialButton(Icons.camera_alt_rounded, Colors.redAccent, '#'),
                      _buildSocialButton(Icons.alternate_email_rounded, Colors.lightBlueAccent, '#'),
                    ],
                  ),

                  const Spacer(),

                  // Footer: Made with ❤️
                  const Text(
                    'Made with ❤️ by Team HackHeads',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to create Contact Info Cards
  Widget _buildInfoCard({required IconData icon, required String text, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9), // Slight transparency for a modern touch
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to create Social Media Buttons
  Widget _buildSocialButton(IconData icon, Color color, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        onPressed: () => _launchURL(url),
      ),
    );
  }
}
