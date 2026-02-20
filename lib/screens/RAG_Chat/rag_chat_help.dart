import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mamamind/services/rag_service.dart';
import 'package:mamamind/services/chat_history_service.dart';
import '../../constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';

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

  // Streaming state
  bool _isStreaming = false;
  String _streamingText = '';
  int _streamingMessageIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _initRagService();
    await _loadChatHistory();

    // Add welcome message if no history
    if (mounted && _ragInitError == null && messages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
        });
        _saveMessageToHistory(welcomeMsg['role']!, welcomeMsg['text']!);
      });
    }
  }

  Future<void> _loadChatHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId == null) {
      setState(() {
        _isLoadingHistory = false;
      });
      return;
    }

    final history = await _chatHistoryService.loadChatHistory(userId);
    if (mounted) {
      setState(() {
        messages = history;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _saveMessageToHistory(String role, String text) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId != null) {
      await _chatHistoryService.saveMessage(
        userId: userId,
        role: role,
        text: text,
      );
    }
  }

  Future<void> _startNewChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

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
              ? 'This will clear your current chat history.'
              : 'මෙය ඔබේ වත්මන් සංවාද ඉතිහාසය මකා දමයි.',
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

    if (confirmed == true && userId != null) {
      await _chatHistoryService.clearChatHistory(userId);
      setState(() {
        messages.clear();
      });
      await _initializeChat();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentLang == 'en'
                ? 'API key missing. Please check your .env file.'
                : 'API යතුර අස්ථානගත වී ඇත. කරුණාකර ඔබේ .env ගොනුව පරීක්ෂා කරන්න.',
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red.shade600,
        ),
      );
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();

    final userMsg = {"role": "user", "text": text};
    setState(() {
      messages.add(userMsg);
      _isTyping = true;
      _isStreaming = false;
      _streamingText = '';
    });

    _controller.clear();
    _scrollToBottom();

    // Save user message
    await _saveMessageToHistory(userMsg['role']!, userMsg['text']!);

    if (_ragInitFuture != null) {
      await _ragInitFuture;
    }

    final RagService? service = _ragService;
    if (service == null || _ragInitError != null) {
      if (!mounted) return;
      final String errorDetail = _ragInitError ?? '';
      final String fallbackMessage = _currentLang == 'en'
          ? "The assistant is not configured yet. Please add your API key."
          : "සහයකය තවම සකසා නැත. කරුණාකර ඔබේ API යතුර එක් කරන්න.";
      final String message = errorDetail.isNotEmpty
          ? (_currentLang == 'en'
                ? "RAG init failed: $errorDetail"
                : "RAG ආරම්භ කිරීම අසාර්ථකයි: $errorDetail")
          : fallbackMessage;
      setState(() {
        messages.add({"role": "bot", "text": message});
        _isTyping = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      // Use streaming for a responsive live experience
      bool isFirstChunk = true;
      final fullResponseBuffer = StringBuffer();

      await for (final chunk in service.answerStream(
        text,
        languageHint: _currentLang == 'en' ? 'English' : 'Sinhala',
      )) {
        if (!mounted) return;

        fullResponseBuffer.write(chunk);
        final currentText = fullResponseBuffer.toString();

        if (isFirstChunk) {
          // First chunk received - switch from "thinking" to "streaming"
          isFirstChunk = false;
          setState(() {
            _isTyping = false;
            _isStreaming = true;
            _streamingText = currentText;
            _streamingMessageIndex = messages.length;
            // Add initial message
            messages = List.from(messages)
              ..add({"role": "bot", "text": currentText});
          });
        } else {
          // Update the streaming message - create new list to trigger rebuild
          setState(() {
            _streamingText = currentText;
            messages = List.from(messages)
              ..[_streamingMessageIndex] = {"role": "bot", "text": currentText};
          });
        }

        _scrollToBottom();
      }

      // Stream complete - finalize the message
      if (!mounted) return;
      final finalText = fullResponseBuffer.toString();
      setState(() {
        _isStreaming = false;
        _streamingText = '';
        messages = List.from(messages)
          ..[_streamingMessageIndex] = {"role": "bot", "text": finalText};
        _streamingMessageIndex = -1;
      });

      _scrollToBottom();

      // Save bot response
      await _saveMessageToHistory("bot", finalText);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add({
          "role": "bot",
          "text": _currentLang == 'en'
              ? "Sorry, I ran into a problem. Please try again."
              : "කණගාටුයි, දෝෂයක් ඇති විය. කරුණාකර නැවත උත්සාහ කරන්න.",
        });
        _isTyping = false;
        _isStreaming = false;
        _streamingText = '';
        _streamingMessageIndex = -1;
      });
      _scrollToBottom();
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
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Removes the back button
        title: Text(
          _currentLang == 'en' ? "Mindful Chat" : "සතිමත් සංවාදය",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          if (messages.isNotEmpty && !_isLoadingHistory)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
              tooltip: _currentLang == 'en' ? 'New Chat' : 'නව සංවාදය',
              onPressed: _startNewChat,
            ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Column(
        children: [
          // --- 1. DECORATIVE CURVED HEADER ---
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),

          // --- 2. CHAT AREA ---
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
                      final isUser = msg["role"] == "user";
                      // Show cursor animation for streaming message
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

          // --- 3. INPUT AREA ---
          _buildInputArea(isMobile),
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
              _currentLang == 'en' ? "Loading..." : "පූරණය වෙමින්...",
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
            _currentLang == 'en'
                ? "Start the conversation"
                : "සංවාදය ආරම්භ කරන්න",
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentLang == 'en'
                ? "I'm here to listen and help."
                : "මම සවන් දීමට සහ උදව් කිරීමට මෙහි සිටිමි.",
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
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              radius: 16,
              child: Icon(Icons.person, size: 18, color: Colors.grey.shade600),
            ),
          ],
        ],
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
                  _currentLang == 'en' ? "Thinking..." : "සිතමින්...",
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
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.roboto(fontSize: 16),
                decoration: InputDecoration(
                  hintText: _currentLang == 'en'
                      ? "Type your message..."
                      : "පණිවුඩය ටයිප් කරන්න...",
                  hintStyle: GoogleFonts.roboto(
                    color: Colors.grey.shade400,
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
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
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
