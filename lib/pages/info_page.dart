import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'dashboard_page.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _dob;
  DateTime? _anniversary;
  String? _gender;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _nameController.text = auth.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: isDob ? 365 * 20 : 365)),
      firstDate: DateTime(1950),
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
      setState(() {
        if (isDob) {
          _dob = picked;
        } else {
          _anniversary = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Date of Birth.')),
      );
      return;
    }
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }
    if (_anniversary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Anniversary date.')),
      );
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await auth.completeSetup(
        name: _nameController.text.trim(),
        gender: _gender!,
        dob: _dob!.toIso8601String().split('T').first,
        anniversaryDate: _anniversary!,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Romantic Gradient
          Container(decoration: AppTheme.romanticGradient()),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Logo / Icon (3D Hands Heart)
                      Center(
                        child: Image.asset(
                          'assets/images/hands_heart_3d.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Heading
                      const Text(
                        'Tell Us About Yourself',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This information helps connect you and your partner in a more meaningful way!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // DISPLAY NAME (How should your partner call you)
                      const Text(
                        'How should your partner call you?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'e.g., Sweetie, Vicky, Katija...',
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // GENDER SELECTOR
                      const Text(
                        'Your Gender',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGenderCard(
                              label: 'Male',
                              imageAsset: 'assets/images/male_avatar_3d.png',
                              isSelected: _gender == 'Male',
                              onTap: () => setState(() => _gender = 'Male'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGenderCard(
                              label: 'Female',
                              imageAsset: 'assets/images/female_avatar_3d.png',
                              isSelected: _gender == 'Female',
                              onTap: () => setState(() => _gender = 'Female'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // DATE OF BIRTH
                      const Text(
                        'Your Date of Birth',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDatePickerButton(
                        label: _dob == null
                            ? 'Select Date of Birth'
                            : '${_dob!.day} ${_monthName(_dob!.month)} ${_dob!.year}',
                        isSelected: _dob != null,
                        onTap: () => _selectDate(context, true),
                      ),
                      const SizedBox(height: 20),

                      // ANNIVERSARY DATE
                      const Text(
                        'Relationship Anniversary Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDatePickerButton(
                        label: _anniversary == null
                            ? 'Select Relationship Start Date'
                            : '${_anniversary!.day} ${_monthName(_anniversary!.month)} ${_anniversary!.year}',
                        isSelected: _anniversary != null,
                        onTap: () => _selectDate(context, false),
                      ),
                      const SizedBox(height: 36),

                      // SUBMIT BUTTON
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save and Enter Dashboard',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard({
    required String label,
    required String imageAsset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.withOpacity(0.15),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primary : AppTheme.textDark,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildDatePickerButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary.withOpacity(0.4) : Colors.white.withOpacity(0.8),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.textDark : AppTheme.textLight.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
