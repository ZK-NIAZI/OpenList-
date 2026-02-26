import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/core/providers/theme_provider.dart';
import 'package:openlist/services/ai_extraction_service.dart';

class AISettingsScreen extends ConsumerStatefulWidget {
  const AISettingsScreen({super.key});

  @override
  ConsumerState<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends ConsumerState<AISettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _apiKeyController = TextEditingController();
  
  bool _isEnabled = false;
  bool _isLoading = true;
  bool _isTesting = false;
  bool _obscureApiKey = true;
  String _defaultReminderOffset = '30'; // minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final apiKey = await _storage.read(key: 'gemini_api_key');
      final enabled = await _storage.read(key: 'ai_extraction_enabled');
      final reminderOffset = await _storage.read(key: 'ai_reminder_offset');
      
      if (mounted) {
        setState(() {
          _apiKeyController.text = apiKey ?? '';
          _isEnabled = enabled == 'true';
          _defaultReminderOffset = reminderOffset ?? '30';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load settings: $e');
      }
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      _showError('Please enter an API key');
      return;
    }

    try {
      await _storage.write(key: 'gemini_api_key', value: apiKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ API key saved securely'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to save API key: $e');
    }
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      _showError('Please enter an API key first');
      return;
    }

    setState(() => _isTesting = true);

    try {
      final service = AIExtractionService(apiKey);
      final isConnected = await service.testConnection();
      
      if (mounted) {
        setState(() => _isTesting = false);
        
        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connection successful!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showError('Connection failed. Please check your API key.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTesting = false);
        _showError('Connection test failed: $e');
      }
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value && _apiKeyController.text.trim().isEmpty) {
      _showError('Please enter an API key first');
      return;
    }

    setState(() => _isEnabled = value);
    await _storage.write(key: 'ai_extraction_enabled', value: value.toString());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
                ? '🤖 AI extraction enabled' 
                : '🤖 AI extraction disabled',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _setReminderOffset(String value) async {
    setState(() => _defaultReminderOffset = value);
    await _storage.write(key: 'ai_reminder_offset', value: value);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Get Your API Key',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To use AI extraction, you need a free Gemini API key:',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            Text(
              '1. Visit: aistudio.google.com/apikey',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '2. Sign in with your Google account',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 8),
            Text(
              '3. Click "Create API Key"',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 8),
            Text(
              '4. Copy and paste it here',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Free tier: 15 requests/minute',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
        appBar: AppBar(
          backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
          elevation: 0,
          title: Text(
            'AI Settings',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: Text(
          'AI Settings',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI extraction helps you create tasks from natural language like "Buy groceries tomorrow at 5pm"',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Enable/Disable
            Text(
              'GENERAL',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.psychology, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Extraction',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Extract tasks from natural language',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isEnabled,
                      onChanged: _toggleEnabled,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // API Key Section
            Text(
              'API CONFIGURATION',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Gemini API Key',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _showApiKeyHelp,
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text('Get Key'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    decoration: InputDecoration(
                      hintText: 'Enter your Gemini API key',
                      hintStyle: GoogleFonts.inter(
                        color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                          color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                        ),
                        onPressed: () {
                          setState(() => _obscureApiKey = !_obscureApiKey);
                        },
                      ),
                    ),
                    style: GoogleFonts.inter(
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveApiKey,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Save Key'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isTesting ? null : _testConnection,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Test'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preferences
            Text(
              'PREFERENCES',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Reminder',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set reminder time before due date',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _defaultReminderOffset,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: '15', child: Text('15 minutes before')),
                      DropdownMenuItem(value: '30', child: Text('30 minutes before')),
                      DropdownMenuItem(value: '60', child: Text('1 hour before')),
                      DropdownMenuItem(value: '120', child: Text('2 hours before')),
                      DropdownMenuItem(value: '1440', child: Text('1 day before')),
                    ],
                    onChanged: (value) {
                      if (value != null) _setReminderOffset(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.privacy_tip_outlined, color: AppColors.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Notice',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your text is sent to Google AI for processing. Google does not store your data per their API terms.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
