import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';
import 'package:dio/dio.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class ChatMessage {
  final String text;
  final bool isAi;
  ChatMessage({required this.text, required this.isAi});
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  void _sendMessage([String? text]) async {
    final message = text ?? _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isAi: false));
      _isTyping = true;
    });
    
    _controller.clear();
    _scrollToBottom();

    // Create a placeholder for the AI response
    int currentMsgIndex = _messages.length;
    setState(() {
      _messages.add(ChatMessage(text: '', isAi: true));
    });

    try {
      final response = await ApiClient.instance.post(
        '/chat/stream',
        data: {'message': message},
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data.stream;
      await for (final chunk in stream) {
        final decodedChunk = utf8.decode(chunk);
        
        // SSE parsing
        final lines = decodedChunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr == '[DONE]') {
              break;
            }
            try {
              final dataJson = jsonDecode(dataStr);
              if (dataJson['chunk'] != null) {
                setState(() {
                  _messages[currentMsgIndex] = ChatMessage(
                    text: _messages[currentMsgIndex].text + dataJson['chunk'],
                    isAi: true,
                  );
                });
                _scrollToBottom();
              }
            } catch (e) {
              // ignore parse errors for partial chunks
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _messages[currentMsgIndex] = ChatMessage(
          text: "Sorry, I had trouble connecting to the brain.",
          isAi: true,
        );
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary,
              radius: 16,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'FinCopilot AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSuggestedChips(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMessageBubble(
                    text: msg.text,
                    isAi: msg.isAi,
                  ),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildSuggestedChips() {
    final suggestions = [
      "Where did I spend the most?",
      "Can I afford a new phone?",
      "Summarize my month",
      "Any subscriptions to cut?",
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            onPressed: () => _sendMessage(s),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required bool isAi}) {
    if (isAi && text.isEmpty && _isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const CircularProgressIndicator(),
        ),
      );
    }
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isAi ? Colors.white : AppTheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAi ? 4 : 20),
            bottomRight: Radius.circular(isAi ? 20 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isAi 
          ? MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: AppTheme.textMain, fontSize: 15, height: 1.4),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Ask FinCopilot...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _isTyping ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
