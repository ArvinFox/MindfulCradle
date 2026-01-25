import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/language_provider.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool _isTyping = false;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      messages.add({"role": "user", "text": _controller.text.trim()});
      _isTyping = true;
    });
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        messages.add({
          "role": "bot",
          "text": _currentLang == 'en'
              ? "This is a sample answer from the AI."
              : "මෙය AI එකෙන් සපයන උත්තරයකි."
        });
        _isTyping = false;
      });
      _scrollToBottom();
    });
    _controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  late String _currentLang;

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
        title: Text(
          _currentLang == 'en' ? "Mindful Chat" : "සතිමත් සංවාදය",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.primary,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      _currentLang == 'en'
                          ? "Start the conversation by typing below."
                          : "පහතින් ටයිප් කිරීමෙන් සංවාදය ආරම්භ කරන්න.",
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 16 : 18,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == messages.length) {
                        return _buildBotTypingIndicator();
                      }
                      final msg = messages[index];
                      final isUser = msg["role"] == "user";
                      return _buildChatBubble(msg["text"]!, isUser, isMobile);
                    },
                  ),
          ),
          _buildInputArea(isMobile),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, bool isMobile) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * (isMobile ? 0.75 : 0.6)),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.roboto(
            color: isUser ? Colors.white : AppColors.text,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildBotTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                )),
            const SizedBox(width: 8),
            Text(
              _currentLang == 'en' ? "AI is typing..." : "AI ටයිප් කරමින් පවතී...",
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _currentLang == 'en'
                    ? "Type your message..."
                    : "පණිවුඩය ටයිප් කරන්න...",
                hintStyle: GoogleFonts.roboto(
                    color: Colors.grey.shade400, fontSize: isMobile ? 16 : 18),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: AppColors.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
