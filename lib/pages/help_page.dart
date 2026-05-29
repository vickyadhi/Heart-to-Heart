import 'package:flutter/material.dart';
import '../theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

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
            'Help Center',
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
                const Text(
                  'How can we help you today? 🌸',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find answers to frequently asked questions or learn how to optimize your Heart to Heart experience.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppTheme.textLight.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                // FAQ TITLE
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // FAQ ITEM 1
                _buildFaqTile(
                  question: 'How do I pair with my partner?',
                  answer: 'Once logged in, navigate to the Pairing screen. You can either share the 4-digit generated code shown on your screen with your partner, or enter your partner\'s 4-digit code in the "Enter Partner\'s Code" tab. Once they accept, your screens will link instantly!',
                ),
                const SizedBox(height: 12),

                // FAQ ITEM 2
                _buildFaqTile(
                  question: 'Why is my Home Screen widget not updating?',
                  answer: 'Widgets can sometimes be delayed by the mobile operating system to save battery. On Android, ensure you have enabled background auto-start and removed battery optimization for h2h. On iOS, verify that App Groups are configured correctly and that background refresh is allowed.',
                ),
                const SizedBox(height: 12),

                // FAQ ITEM 3
                _buildFaqTile(
                  question: 'How does real-time battery sync work?',
                  answer: 'When your battery percentage changes, your local device uploads the updated level and charging status to Firestore. If you are paired, your partner\'s app listens to these changes reactively and updates their dashboard card instantly.',
                ),
                const SizedBox(height: 12),

                // FAQ ITEM 4
                _buildFaqTile(
                  question: 'Are my love taps and messages secure?',
                  answer: 'Yes! All connection data, events, and chat messages are stored securely using Firebase Firestore. Data is only accessible by you and your authorized partner using Firestore Security Rules.',
                ),
                const SizedBox(height: 12),

                // FAQ ITEM 5
                _buildFaqTile(
                  question: 'How do I unpair from my partner?',
                  answer: 'To unpair, navigate to the Settings tab, scroll to the User Header card, and tap the "Unpair" button. Once confirmed, both you and your partner will be disconnected, and your partner will be redirected back to the pairing page.',
                ),
                
                const SizedBox(height: 36),
                
                // Troubleshooting Quick Cards
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
                      const Row(
                        children: [
                          Icon(Icons.vibration_rounded, color: AppTheme.primary, size: 20), // wait, vibrafont might not exist, let's use vibration_rounded
                          SizedBox(width: 8),
                          Text(
                            'Quick Vibration Tip 📳',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you aren\'t receiving vibrations when your partner taps the heart, make sure the "Vibration" switch is turned on in your Profile settings, and verify that your system settings allow app-level vibrations.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.textLight.withOpacity(0.9),
                          height: 1.45,
                        ),
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

  Widget _buildFaqTile({required String question, required String answer}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        iconColor: AppTheme.primary,
        collapsedIconColor: AppTheme.textLight,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        shape: const Border(), // remove divider lines
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppTheme.textLight,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
