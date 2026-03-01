import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/chat_history_service.dart';
import '../../utils/translate.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  List<ChatSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final sessions = await _chatHistoryService.getChatSessions(userId);
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSession(ChatSession session) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.t.chat('deleteChat'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          context.t.chat('deleteChatConfirm'),
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t.common('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.t.common('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatHistoryService.deleteChatSession(
        userId: userId,
        sessionId: session.id,
      );
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSinhala = langProvider.currentLang == 'si';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.t.chat('chatHistory'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.text.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSinhala ? 'චැට් ඉතිහාසයක් නැත' : 'No Chat History',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.text.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSessions,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: AppColors.cardBackground,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.chat_bubble,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        session.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${session.messageCount} ${isSinhala ? 'පණිවිඩ' : 'messages'}',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: AppColors.text.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM d, yyyy • h:mm a',
                            ).format(session.updatedAt),
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.text.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red.withOpacity(0.7),
                        onPressed: () => _deleteSession(session),
                      ),
                      onTap: () {
                        // Return the selected session ID
                        Navigator.pop(context, session.id);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
