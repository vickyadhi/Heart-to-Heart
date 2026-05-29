import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'pairing_page.dart';

class NamePage extends StatefulWidget {
  final bool isEditing;
  const NamePage({super.key, this.isEditing = false});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final _nameController = TextEditingController();
  final _partnerNicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedAnniversary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      if (user != null) {
        if (user.displayName.isNotEmpty && user.displayName != 'Rambo') {
          _nameController.text = user.displayName;
        }
        if (user.partnerNickname != null) {
          _partnerNicknameController.text = user.partnerNickname!;
        }
        if (user.anniversaryDate != null) {
          _selectedAnniversary = user.anniversaryDate;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partnerNicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedAnniversary ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedAnniversary = picked);
    }
  }

  Future<void> _submit(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnniversary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your anniversary date 💖',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    await authService.updateProfileDetails(
      _nameController.text.trim(),
      _partnerNicknameController.text.trim(),
      _selectedAnniversary!,
    );
    
    if (mounted) {
      if (widget.isEditing) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PairingPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Container(
      decoration: AppTheme.romanticGradient(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.isEditing) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 32),
                          ],
                          // Centered Graphic / Heart Icon
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppTheme.premiumShadow,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: AppTheme.primary,
                                  size: 38,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title matching reference: "Let's Get Paired" / "Tell Us Your Love Details"
                          const Text(
                            'Tell Us Your Love Details',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'We will use this to track important dates\nand milestones for your connection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppTheme.textLight,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // USER NICKNAME CARD
                          _buildInputCard(
                            title: 'Your Nickname',
                            child: TextFormField(
                              controller: _nameController,
                              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Enter your name (e.g. Rambo)...',
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter nickname' : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // PARTNER NICKNAME CARD
                          _buildInputCard(
                            title: "Partner's Nickname",
                            child: TextFormField(
                              controller: _partnerNicknameController,
                              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Enter their nickname (e.g. Kajal)...',
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter partner\'s nickname' : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ANNIVERSARY DATE SELECT CARD
                          _buildInputCard(
                            title: 'Your Anniversary Date 💖',
                            child: InkWell(
                              onTap: _pickDate,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedAnniversary == null
                                          ? 'Select date...'
                                          : '${_selectedAnniversary!.year}-${_selectedAnniversary!.month.toString().padLeft(2, '0')}-${_selectedAnniversary!.day.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _selectedAnniversary == null 
                                            ? AppTheme.textLight.withValues(alpha: 0.4) 
                                            : AppTheme.textDark,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),
                          const SizedBox(height: 24),

                          // Bottom action Button matching reference: "Let's Go"
                          ElevatedButton(
                            onPressed: authService.isLoading ? null : () => _submit(authService),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: authService.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Let's Go"),
                          ),
                          // Safe bottom spacing for scroll
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontFamily: 'Outfit', 
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
