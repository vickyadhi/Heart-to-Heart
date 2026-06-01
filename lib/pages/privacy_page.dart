import 'package:flutter/material.dart';
import '../theme.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

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
            'Privacy Policy',
            style: TextStyle(
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
                      _buildSectionTitle('1. Overview'),
                      _buildSectionBody(
                        'Heart to Heart (h2h) is designed to bring long-distance partners closer together. Because we value your trust, we never sell your data. We collect and process data solely to keep your romantic dashboard in sync.',
                      ),
                      
                      _buildSectionTitle('2. Information We Collect'),
                      _buildSectionBody(
                        'To operate the connection service, we collect: \n'
                        '• Profile Info: Your name, email address, profile picture (if using Google Sign-In), and anniversary date.\n'
                        '• Battery Status: Current battery percentage and charging state (to display to your partner).\n'
                        '• Love Events & Taps: Logs of heart interactions, emoji triggers, and simple status messages.\n'
                        '• Device Push Tokens: Cloud messaging tokens used solely for delivering real-time notification alerts when your partner sends you love.',
                      ),
                      
                      _buildSectionTitle('3. How Your Data is Used'),
                      _buildSectionBody(
                        'Your data is shared exclusively with your paired partner. Only your partner has permission to query your battery level or receive your love events. We do not use your information for advertising, profiling, or tracking across other apps.',
                      ),

                      _buildSectionTitle('4. Firestore Security & Rule Sets'),
                      _buildSectionBody(
                        'All information is stored in Cloud Firestore. We enforce strict document security rules: users can only read/write their own document, and their partner\'s document. It is physically impossible for un-paired or outside users to access your private interactions.',
                      ),

                      _buildSectionTitle('5. Data Retention & Deletion'),
                      _buildSectionBody(
                        'If you unpair from your partner, your active link is immediately removed. You can request account deletion at any time by contacting our support team. Upon deletion, your user profile and conversation logs will be permanently erased from our databases.',
                      ),

                      _buildSectionTitle('6. Third-Party Services'),
                      _buildSectionBody(
                        'We utilize Google Firebase services (Firebase Auth, Cloud Firestore, Cloud Functions, and Firebase Cloud Messaging) to power our real-time synchronization. These services are subject to Google\'s Privacy Policy.',
                      ),

                      _buildSectionTitle('7. Updates to This Policy'),
                      _buildSectionBody(
                        'We may update our Privacy Policy periodically. We will notify you of any changes by posting the new policy on this page with an updated date.',
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
        fontSize: 12,
        color: AppTheme.textLight,
        height: 1.5,
      ),
    );
  }
}
