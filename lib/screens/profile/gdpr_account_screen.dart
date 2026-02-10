import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/colors.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';

/// GDPR Account Management Screen
/// Allows users to export their data and delete their account
class GDPRAccountScreen extends StatefulWidget {
  const GDPRAccountScreen({super.key});

  @override
  State<GDPRAccountScreen> createState() => _GDPRAccountScreenState();
}

class _GDPRAccountScreenState extends State<GDPRAccountScreen> {
  bool _isExporting = false;
  bool _isDeleting = false;

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = langProvider.currentLang;

    try {
      final rows = await authProvider.exportUserDataRows(langCode: langCode);

      if (rows != null && mounted) {
        final confirm = await _showExportPreview(rows, langCode);
        if (confirm != true) {
          return;
        }

        final csvData = authProvider.rowsToCsv(rows);
        final directory = await _resolveDownloadDirectory();
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final fileName = 'mindful_cradle_data_$timestamp.csv';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvData);

        if (mounted) {
          final savedMessage = langCode == 'si'
              ? 'දත්ත ගොනුව සුරකින ලදි: ${file.path}'
              : 'Data file saved: ${file.path}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(savedMessage),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              langCode == 'si'
                  ? 'දත්ත අපනයනය අසාර්ථකයි'
                  : 'Failed to export data',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              langProvider.currentLang == 'si'
                  ? 'දත්ත අපනයනය අසාර්ථකයි'
                  : 'Failed to export data',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<Directory> _resolveDownloadDirectory() async {
    if (Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        return downloads;
      }
      final external = await getExternalStorageDirectory();
      if (external != null) {
        return external;
      }
    }

    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }

    return getApplicationDocumentsDirectory();
  }

  Future<bool?> _showExportPreview(List<List<String>> rows, String langCode) {
    final isSinhala = langCode == 'si';
    final title = isSinhala ? 'දත්ත පෙරදසුන' : 'Data Preview';
    final downloadText = isSinhala ? 'CSV ලෙස බාගන්න' : 'Download CSV';
    final cancelText = isSinhala ? 'අවලංගු කරන්න' : 'Cancel';
    final maxRows = 200;
    final hasOverflow = rows.length > maxRows + 1;
    final previewRows = hasOverflow ? rows.sublist(0, maxRows + 1) : rows;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final header = previewRows.isNotEmpty ? previewRows.first : [];
        final dataRows = previewRows.length > 1
            ? previewRows.sublist(1)
            : <List<String>>[];

        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasOverflow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      isSinhala
                          ? 'පෙරදසුනේ පේළි $maxRows ක් පමණක් පෙන්වයි.'
                          : 'Preview shows only the first $maxRows rows.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: header
                            .map(
                              (cell) => DataColumn(
                                label: Text(
                                  cell,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        rows: dataRows
                            .map(
                              (row) => DataRow(
                                cells: row
                                    .map(
                                      (cell) => DataCell(
                                        Text(
                                          cell,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(downloadText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = langProvider.currentLang;

    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmationDialog(langCode),
    );

    if (confirm != true) return;

    // Show password dialog
    final password = await _showPasswordDialog(langCode);
    if (password == null || password.isEmpty) return;

    setState(() => _isDeleting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final error = await authProvider.deleteAccount(
        password,
        langCode: langCode,
      );

      if (!mounted) return;

      if (error == null) {
        // Success - navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              langCode == 'si'
                  ? 'ගිණුම සාර්ථකව මකා දමන ලදි'
                  : 'Account deleted successfully',
            ),
          ),
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        // Error
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              langCode == 'si'
                  ? 'ගිණුම මකා දැමීම අසාර්ථකයි'
                  : 'Failed to delete account',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  AlertDialog _buildDeleteConfirmationDialog(String langCode) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        langCode == 'si' ? 'ගිණුම මකන්න' : 'Delete Account',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
      content: Text(
        langCode == 'si'
            ? 'ඔබට විශ්වාසද? මෙය ඔබගේ සියලු දත්ත ස්ථිරවම මකා දමනු ඇත.'
            : 'Are you sure? This will permanently delete all your data.',
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            langCode == 'si' ? 'අවලංගු කරන්න' : 'Cancel',
            style: GoogleFonts.poppins(),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(
            langCode == 'si' ? 'මකන්න' : 'Delete',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<String?> _showPasswordDialog(String langCode) async {
    final controller = TextEditingController();
    bool obscureText = true;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            langCode == 'si' ? 'මුරපදය තහවුරු කරන්න' : 'Confirm Password',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          content: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: langCode == 'si' ? 'මුරපදය' : 'Password',
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => obscureText = !obscureText);
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                langCode == 'si' ? 'අවලංගු කරන්න' : 'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                langCode == 'si' ? 'තහවුරු කරන්න' : 'Confirm',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final langCode = langProvider.currentLang;
    final isSinhala = langCode == 'si';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isSinhala ? 'දත්ත සහ පෞද්ගලිකත්වය' : 'Data & Privacy',
          style: appBarTextStyle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text(
            isSinhala ? 'GDPR අයිතිවාසිකම්' : 'GDPR Rights',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSinhala
                ? 'ඔබගේ දත්ත පිළිබඳ සම්පූර්ණ පාලනය ඔබට ඇත'
                : 'You have full control over your data',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
          ),
          const SizedBox(height: 24),

          // Export Data Card
          _buildDataCard(
            icon: Icons.download,
            title: isSinhala ? 'දත්ත අපනයනය කරන්න' : 'Export Your Data',
            description: isSinhala
                ? 'ඔබගේ සියලු සෞඛ්‍ය ලකුණු සහ පැතිකඩ දත්ත CSV ගොනුවක් ලෙස සුරකින්න'
                : 'Save all your health scores and profile data as a CSV file',
            buttonText: isSinhala ? 'අපනයනය කරන්න' : 'Export Data',
            buttonColor: AppColors.primary,
            isLoading: _isExporting,
            onPressed: _exportData,
          ),

          const SizedBox(height: 16),

          // Delete Account Card
          _buildDataCard(
            icon: Icons.delete_forever,
            title: isSinhala ? 'ගිණුම මකන්න' : 'Delete Account',
            description: isSinhala
                ? 'ඔබගේ ගිණුම සහ සියලු දත්ත ස්ථිරවම මකන්න. මෙය අපැහැර ගත නොහැක.'
                : 'Permanently delete your account and all data. This cannot be undone.',
            buttonText: isSinhala ? 'ගිණුම මකන්න' : 'Delete Account',
            buttonColor: Colors.red,
            isLoading: _isDeleting,
            onPressed: _deleteAccount,
          ),

          const SizedBox(height: 24),

          // Information Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSinhala ? 'අපි එකතු කරන දත්ත' : 'Data We Collect',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  isSinhala
                      ? 'DASS-21 ප්‍රශ්නාවලියේ ප්‍රතිචාර'
                      : 'DASS-21 questionnaire responses',
                ),
                _buildInfoItem(
                  isSinhala
                      ? 'PWS-18 ප්‍රශ්නාවලියේ ප්‍රතිචාර'
                      : 'PWS-18 questionnaire responses',
                ),
                _buildInfoItem(
                  isSinhala
                      ? 'MAAS ප්‍රශ්නාවලියේ ප්‍රතිචාර'
                      : 'MAAS questionnaire responses',
                ),
                _buildInfoItem(
                  isSinhala ? 'වීඩියෝ ප්‍රගතිය' : 'Video progress',
                ),
                _buildInfoItem(
                  isSinhala ? 'පැතිකඩ තොරතුරු' : 'Profile information',
                ),
                _buildInfoItem(isSinhala ? 'ගර්භණී සතිය' : 'Pregnancy week'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required Color buttonColor,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: buttonColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.completed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
