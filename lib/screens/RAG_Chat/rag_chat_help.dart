import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mamamind/services/rag_service.dart';
import 'package:mamamind/services/chat_history_service.dart';
import '../../constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../utils/translate.dart';
import '../../utils/app_snackbar.dart';
import 'chat_history_screen.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  List<Map<String, String>> messages = [];
  bool _isTyping = false;
  bool _isInitializing = false;
  bool _isLoadingHistory = true;
  late String _currentLang;
  RagService? _ragService;
  Future<void>? _ragInitFuture;
  String? _ragInitError;

  // Chat session management
  String? _currentSessionId;
  bool _isNewSession = true;

  // Streaming state
  bool _isStreaming = false;
  int _streamingMessageIndex = -1;

  // Crisis detection keywords
  static const List<String> _crisisKeywordsEn = [
    'suicide',
    'suicidal',
    'kill myself',
    'kill my self',
    'end my life',
    'take my life',
    'want to die',
    'want to end my life',
    'self harm',
    'self-harm',
    'hurt myself',
    'cutting myself',
    "don't want to live",
    'do not want to live',
    'no reason to live',
    'give up on life',
    'better off dead',
    'no point in living',
    'no point in life',
    'end it all',
    'no way out',
    'life is not worth living',
    'life is meaningless',
    'slit my wrist',
    'overdose on',
    'not worth living',
    'think about dying',
    'thoughts of dying',
  ];
  static const List<String> _crisisKeywordsSi = [
    'සිය දිවි',
    'ආත්ම ඝාතනය',
    'ජීවිතය නිම',
    'ජීවත් නොවෙමි',
    'ජීවිතය ගන්නෙමි',
    'ජීවිතය හමාරයි',
    'මිය යන්නෙමි',
    'ජීවත් නොවිය',
    'ජීවිතය අවසන්',
    'ජීවිතය නිකරුණේ',
    'ජීවිතේ නිම',
    'මරණ',
    'මරනය',
    'මරණය',
    'මැරෙන්න',
    'මැරෙන්න',
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _initRagService();

    // Add welcome message in-memory only (no Firebase save yet)
    if (mounted && _ragInitError == null && messages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final lang = Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).currentLang;
        final welcomeMsg = {
          "role": "bot",
          "text": lang == 'en'
              ? "Hello! I am your Mindful Cradle companion, here to answer your questions about pregnancy, childbirth, and newborn care. How can I help you today?"
              : "ආයුබෝවන්! මම ඔබේ Mindful Cradle සහායකයා වෙමි. ගැබ් ගැනීම, දරු ප්‍රසූතිය සහ අලුත උපන් බිළිඳුන් රැකබලා ගැනීම පිළිබඳ ඔබේ ප්‍රශ්නවලට පිළිතුරු සැපයීමට මම මෙහි සිටිමි. අද මට ඔබට උදව් කළ හැක්කේ කෙසේද?",
        };
        setState(() {
          messages.add(welcomeMsg);
          _isLoadingHistory = false;
        });
      });
    } else {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadOrCreateSession({String? sessionId}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId == null) {
      setState(() {
        _isLoadingHistory = false;
      });
      return;
    }

    if (sessionId != null) {
      // Load existing session
      _currentSessionId = sessionId;
      _isNewSession = false;
      final history = await _chatHistoryService.loadChatSession(
        userId: userId,
        sessionId: sessionId,
      );
      if (mounted) {
        setState(() {
          messages = history;
          _isLoadingHistory = false;
          // Reset streaming states when switching chats
          _isTyping = false;
          _isStreaming = false;
          _streamingMessageIndex = -1;
        });
      }
    } else {
      // Create new session
      try {
        _currentSessionId = await _chatHistoryService.createChatSession(
          userId: userId,
        );
        _isNewSession = true;
        setState(() {
          messages = [];
          _isLoadingHistory = false;
          // Reset streaming states for new chat
          _isTyping = false;
          _isStreaming = false;
          _streamingMessageIndex = -1;
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error creating session: $e');
        }
        setState(() {
          _isLoadingHistory = false;
          // Reset streaming states on error
          _isTyping = false;
          _isStreaming = false;
          _streamingMessageIndex = -1;
        });
      }
    }
  }

  Future<void> _saveMessageToHistory(
    String role,
    String text, {
    String? sessionId,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    final targetSessionId = sessionId ?? _currentSessionId;

    if (userId != null && targetSessionId != null) {
      await _chatHistoryService.saveMessage(
        userId: userId,
        sessionId: targetSessionId,
        role: role,
        text: text,
      );

      // Update session title with first user message
      if (_isNewSession && role == 'user') {
        final title = _chatHistoryService.generateTitleFromMessage(text);
        await _chatHistoryService.updateSessionTitle(
          userId: userId,
          sessionId: targetSessionId,
          title: title,
        );
        _isNewSession = false;
      }
    }
  }

  Future<void> _startNewChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _currentLang == 'en'
              ? 'Start New Chat?'
              : 'නව සංවාදයක් ආරම්භ කරන්නද?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          _currentLang == 'en'
              ? 'This will start a fresh conversation. Your current chat will be saved.'
              : 'මෙය නව සංවාදයක් ආරම්භ කරයි. ඔබේ වත්මන් චැට් එක සුරකිනු ලැබේ.',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_currentLang == 'en' ? 'Cancel' : 'අවලංගු කරන්න'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _currentLang == 'en' ? 'Start New' : 'නව එක ආරම්භ කරන්න',
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        messages.clear();
        _currentSessionId = null;
        _isNewSession = true;
        _isLoadingHistory = true;
      });
      await _initializeChat(); // Adds welcome message (in-memory only)
    }
  }

  Future<void> _viewChatHistory() async {
    final selectedSessionId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
    );

    if (selectedSessionId != null && selectedSessionId != _currentSessionId) {
      setState(() {
        _isLoadingHistory = true;
      });
      await _loadOrCreateSession(sessionId: selectedSessionId);
    }
  }

  Future<void> _initRagService() async {
    setState(() {
      _isInitializing = true;
    });

    final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (kDebugMode) {
      debugPrint('RAG API key loaded: ${apiKey.isNotEmpty}');
    }

    if (apiKey.isEmpty) {
      setState(() {
        _isInitializing = false;
      });
      _showKeyStatus(false);
      return;
    }

    _showKeyStatus(true);

    final RagService service = RagService(apiKey: apiKey);
    _ragService = service;
    _ragInitFuture ??= _safeInitialize(service);
    await _ragInitFuture;

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _safeInitialize(RagService service) async {
    try {
      await service.initialize();
      _ragInitError = null;
    } catch (e) {
      _ragInitError = e.toString();
      if (kDebugMode) {
        debugPrint('RAG init error: $e');
      }
    }
  }

  void _showKeyStatus(bool loaded) {
    if (!mounted || loaded) {
      return;
    }
    // Only show error if API key is missing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        context.t.chat('apiKeyMissing'),
        duration: const Duration(seconds: 4),
      );
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    final String fallbackMessage = context.t.chat('assistantNotConfigured');
    final String ragInitFailedPrefix = context.t.chat('ragInitFailed');
    final String languageHint = _currentLang == 'en'
        ? context.t.chat('languageHintEnglish')
        : context.t.chat('languageHintSinhala');

    // Read user name early (before async gaps)
    final authProviderEarly = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProviderEarly.user?.fullName;

    // Crisis content detection
    final isCrisis = _isCrisisMessage(text);

    final userMsg = {"role": "user", "text": text};
    setState(() {
      messages.add(userMsg);
      _isTyping = true;
      _isStreaming = false;
    });

    _controller.clear();
    _scrollToBottom();

    // Create session on first message if needed
    if (_currentSessionId == null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId != null) {
        try {
          _currentSessionId = await _chatHistoryService.createChatSession(
            userId: userId,
          );
          _isNewSession = true;

          // Unlock chat_companion on first ever chat session
          if (context.mounted) {
            final achievementProvider = Provider.of<AchievementProvider>(
              context,
              listen: false,
            );
            await achievementProvider.unlockAchievement(
              context,
              'chat_companion',
              showUI: false,
            );
            achievementProvider.showPendingAchievements(context);
          }

          // Save welcome message first (if exists)
          if (messages.length > 1 && messages[0]['role'] == 'bot') {
            await _chatHistoryService.saveMessage(
              userId: userId,
              sessionId: _currentSessionId!,
              role: messages[0]['role']!,
              text: messages[0]['text']!,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error creating session on first message: $e');
          }
        }
      }
    }

    // Capture the session ID to ensure messages are saved to the correct session
    // even if user switches chats during streaming
    final String? sessionId = _currentSessionId;

    // Save user message
    await _saveMessageToHistory(
      userMsg['role']!,
      userMsg['text']!,
      sessionId: sessionId,
    );

    if (_ragInitFuture != null) {
      await _ragInitFuture;
    }

    final RagService? service = _ragService;
    if (service == null || _ragInitError != null) {
      if (!mounted) return;

      // Only update UI if this is still the current session
      if (_currentSessionId == sessionId) {
        final String errorDetail = _ragInitError ?? '';
        final String message = errorDetail.isNotEmpty
            ? ragInitFailedPrefix + errorDetail
            : fallbackMessage;
        setState(() {
          messages.add({"role": "bot", "text": message});
          _isTyping = false;
        });
        _scrollToBottom();
      }
      return;
    }

    try {
      // Use streaming for a responsive live experience
      bool isFirstChunk = true;
      final fullResponseBuffer = StringBuffer();

      // Get conversation history (excluding current user message and crisis cards)
      final conversationHistory = messages.length > 1
          ? messages
                .sublist(0, messages.length - 1)
                .where((m) => m['role'] != 'crisis')
                .toList()
          : <Map<String, String>>[];

      await for (final chunk in service.answerStream(
        text,
        languageHint: languageHint,
        conversationHistory: conversationHistory,
        userName: userName,
        crisisExtra: isCrisis
            ? 'CRITICAL: The user has expressed thoughts of self-harm, suicide, or extreme emotional distress. '
                  'This application is based in Sri Lanka and serves Sri Lankan mothers. '
                  'Respond with deep empathy and compassion in the same language the user wrote in. '
                  'Acknowledge their pain and validate their feelings without judgment. '
                  'Remind them that help is available and they are not alone. '
                  'IMPORTANT: Only reference Sri Lanka specific helplines: '
                  'National Mental Health Helpline (1926), CCC Mental Health Helpline (1333), '
                  'and Sumithrayo (0112682535). '
                  'Do NOT mention any helplines from the US, Canada, UK, or any other country. '
                  'Do not provide information that could cause harm. '
                  'Encourage them warmly to reach out for professional support immediately.'
            : null,
      )) {
        if (!mounted) return;

        // Check if user has switched to a different chat session
        if (_currentSessionId != sessionId) {
          // Continue collecting the response but don't update UI
          fullResponseBuffer.write(chunk);
          continue;
        }

        fullResponseBuffer.write(chunk);
        final currentText = fullResponseBuffer.toString();

        if (isFirstChunk) {
          // First chunk received - switch from "thinking" to "streaming"
          isFirstChunk = false;
          setState(() {
            _isTyping = false;
            _isStreaming = true;
            _streamingMessageIndex = messages.length;
            // Add initial message
            messages = List.from(messages)
              ..add({"role": "bot", "text": currentText});
          });
        } else {
          // Update the streaming message - create new list to trigger rebuild
          setState(() {
            messages = List.from(messages)
              ..[_streamingMessageIndex] = {"role": "bot", "text": currentText};
          });
        }

        _scrollToBottom();
      }

      // Stream complete - finalize the message
      if (!mounted) return;
      final finalText = fullResponseBuffer.toString();

      // Only update UI if this is still the current session
      if (_currentSessionId == sessionId) {
        setState(() {
          _isStreaming = false;
          messages = List.from(messages)
            ..[_streamingMessageIndex] = {"role": "bot", "text": finalText};
          _streamingMessageIndex = -1;
        });
        _scrollToBottom();
      }

      // Save bot response to the correct session regardless
      await _saveMessageToHistory("bot", finalText, sessionId: sessionId);

      // If crisis message, append crisis card AFTER the bot response
      if (isCrisis) {
        if (mounted && _currentSessionId == sessionId) {
          setState(() {
            messages = List.from(messages)..add({"role": "crisis", "text": ""});
          });
          _scrollToBottom();
        }
        await _saveMessageToHistory("crisis", "", sessionId: sessionId);
      }
    } catch (e) {
      if (!mounted) return;

      // Only update UI if this is still the current session
      if (_currentSessionId == sessionId) {
        setState(() {
          messages.add({"role": "bot", "text": context.t.chat('errorRetry')});
          _isTyping = false;
          _isStreaming = false;
          _streamingMessageIndex = -1;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    _currentLang = langProvider.currentLang;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Removes the back button
        title: Text(
          context.t.chat('mindfulChat'),
          style: GoogleFonts.poppins(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          if (messages.isNotEmpty && !_isLoadingHistory)
            IconButton(
              icon: const Icon(Icons.history_rounded, color: AppColors.text),
              tooltip: context.t.chat('chatHistory'),
              onPressed: _viewChatHistory,
            ),
          if (messages.isNotEmpty && !_isLoadingHistory)
            IconButton(
              icon: const Icon(
                Icons.add_comment_outlined,
                color: AppColors.text,
              ),
              tooltip: context.t.chat('newChat'),
              onPressed: _startNewChat,
            ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8F5F2), Color(0xFFF4F0EC)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.heroGradientMid.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState(isMobile)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isTyping && index == messages.length) {
                            return _buildBotTypingIndicator();
                          }
                          final msg = messages[index];
                          if (msg["role"] == "crisis") {
                            return _buildCrisisCard(isMobile);
                          }
                          final isUser = msg["role"] == "user";
                          final isStreamingMsg =
                              _isStreaming && index == _streamingMessageIndex;
                          return _buildChatBubble(
                            msg["text"]!,
                            isUser,
                            isMobile,
                            isStreaming: isStreamingMsg,
                          );
                        },
                      ),
              ),
              _buildInputArea(isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    if (_isInitializing || _isLoadingHistory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              context.t.common('loading'),
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t.chat('startConversation'),
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t.chat('hereToHelp'),
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
    String text,
    bool isUser,
    bool isMobile, {
    bool isStreaming = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              radius: 16,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      text,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: isMobile ? 15 : 16,
                        height: 1.4,
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: MarkdownBody(
                            data: text,
                            styleSheet: MarkdownStyleSheet(
                              p: GoogleFonts.roboto(
                                color: AppColors.text,
                                fontSize: isMobile ? 15 : 16,
                                height: 1.4,
                              ),
                              strong: GoogleFonts.roboto(
                                color: AppColors.text,
                                fontSize: isMobile ? 15 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                              em: GoogleFonts.roboto(
                                color: AppColors.text,
                                fontSize: isMobile ? 15 : 16,
                                fontStyle: FontStyle.italic,
                              ),
                              code: GoogleFonts.robotoMono(
                                backgroundColor: Colors.grey.shade100,
                                color: AppColors.primary,
                                fontSize: isMobile ? 14 : 15,
                              ),
                              listBullet: GoogleFonts.roboto(
                                color: AppColors.text,
                                fontSize: isMobile ? 15 : 16,
                              ),
                            ),
                          ),
                        ),
                        // Show cursor animation while streaming
                        if (isStreaming) ...[
                          const SizedBox(width: 4),
                          const _StreamingCursor(),
                        ],
                      ],
                    ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                final photoUrl = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).user?.photoUrl;
                return CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 16,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.grey.shade600,
                        )
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  bool _isCrisisMessage(String text) {
    final lower = text.toLowerCase();
    for (final kw in _crisisKeywordsEn) {
      if (lower.contains(kw)) return true;
    }
    for (final kw in _crisisKeywordsSi) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  Widget _buildCrisisCard(bool isMobile) {
    final isSinhala = _currentLang == 'si';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3F3), Color(0xFFFFF0F5)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFE53935),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSinhala ? 'ඔබ තනිව නොසිටී' : 'You are not alone',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 15 : 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB71C1C),
                          ),
                        ),
                        Text(
                          isSinhala
                              ? 'සහාය ලැබිය හැකිය. කරුණාකර සම්බන්ධ වන්න.'
                              : 'Help is available. Please reach out.',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: const Color(0xFFC62828),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: const Color(0xFFFFCDD2), thickness: 1),
              const SizedBox(height: 12),
              Text(
                isSinhala ? 'හදිසි සහාය දුරකතන' : 'Emergency Helplines',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF37474F),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              _buildCallButton(
                name: isSinhala
                    ? 'ජාතික මානසික සෞඛ්‍ය helpline'
                    : 'National Mental Health Helpline',
                number: '1926',
                color: const Color(0xFFE53935),
              ),
              const SizedBox(height: 8),
              _buildCallButton(
                name: isSinhala
                    ? 'CCC මානසික සෞඛ්‍ය helpline'
                    : 'CCC Mental Health Helpline',
                number: '1333',
                color: const Color(0xFFAD1457),
              ),
              const SizedBox(height: 8),
              _buildCallButton(
                name: 'Sumithrayo',
                number: '0112682535',
                color: const Color(0xFF6A1B9A),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required String name,
    required String number,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          final uri = Uri(scheme: 'tel', path: number);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {}
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      number,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2933),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.call_made_rounded,
                size: 16,
                color: color.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            radius: 16,
            child: Icon(
              Icons.smart_toy_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.t.chat('thinking'),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.roboto(fontSize: 16),
                decoration: InputDecoration(
                  hintText: context.t.chat('typeMessage'),
                  hintStyle: GoogleFonts.roboto(
                    color: AppColors.textMuted,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.heroGradientStart,
                    AppColors.heroGradientMid,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated cursor widget shown while text is streaming
class _StreamingCursor extends StatefulWidget {
  const _StreamingCursor();

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 530),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
