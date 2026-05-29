import 'package:flutter/material.dart';
import '../theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.romanticGradient(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Terms of Service',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppTheme.textDark,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Last updated: May 28, 2026',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textLight.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.premiumShadow,
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Acceptance of Terms'),
                      _buildSectionBody(
                        'By downloading, accessing, or using Heart to Heart (h2h), you agree to be bound by these Terms of Service. If you do not agree to all of these terms, do not access or use the application.',
                      ),
                      
                      _buildSectionTitle('2. Description of Service'),
                      _buildSectionBody(
                        'Heart to Heart is an interactive companion app designed for long-distance couples. The service provides pairing, status sharing (e.g., battery levels and charging statuses), love event triggers (vibrations, taps), and real-time chatting.',
                      ),
                      
                      _buildSectionTitle('3. Account Registration & Security'),
                      _buildSectionBody(
                        'To use the app, you must create an account via email or Google Sign-In. You are responsible for keeping your login credentials confidential and for all activity that occurs under your account. You agree to notify us immediately of any unauthorized use of your account.',
                      ),

                      _buildSectionTitle('4. Partner Pairing Codes'),
                      _buildSectionBody(
                        'Pairing requires both users to enter a unique 4-digit code. Each pairing code is bound to your account and remains active to authorize your partner connection. You agree to share pairing codes only with your intended partner.',
                      ),

                      _buildSectionTitle('5. User Conduct & Acceptable Use'),
                      _buildSectionBody(
                        'You agree to use h2h only for lawful, personal purposes. You shall not transmit any offensive, harassing, abusive, or unauthorized content through the app\'s communication systems.',
                      ),

                      _buildSectionTitle('6. Intellectual Property'),
                      _buildSectionBody(
                        'All components, assets, graphics, designs, logos, software code, and services are owned by or licensed to Heart to Heart. You may not duplicate, reverse engineer, or redistribute our assets without prior written consent.',
                      ),

                      _buildSectionTitle('7. Termination of Service'),
                      _buildSectionBody(
                        'We reserve the right to suspend or terminate your account or access to h2h at our discretion, without notice, if we believe you are in breach of these terms.',
                      ),

                      _buildSectionTitle('8. Limitation of Liability'),
                      _buildSectionBody(
                        'h2h is provided "as is" without warranties of any kind. We are not liable for any direct, indirect, incidental, or consequential damages resulting from your use of, or inability to use, our service.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String body) {
    return Text(
      body,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: AppTheme.textLight,
        height: 1.5,
      ),
    );
  }
}
