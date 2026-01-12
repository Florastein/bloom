import 'dart:async';
import 'dart:io';

import 'package:bloom/models/chat_message.dart';
import 'package:bloom/services/db_service.dart';
import 'package:bloom/services/gemini_chat.dart';
import 'package:bloom/services/online.dart';
import 'package:bloom/screens/breath.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:bloom/constants/colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatService chatService;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String? _selectedMessage;
  bool _canSend = false;
  final List<Map<String, dynamic>> messages = [];

  final TextEditingController _messageController = TextEditingController();

  String formatTimestamp(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _loadChatHistory() async {
    final storedMessages = HiveDBService.getAllMessages();
    setState(() {
      messages.addAll(
        storedMessages
            .asMap()
            .entries
            .map(
              (entry) => {
                "index": entry.key, // Hive index
                "isMe": entry.value.sender == "user",
                "text": entry.value.message,
                "time": formatTimestamp(entry.value.timestamp),
                "rawTime": entry.value.timestamp,
                "isAudio": false,
              },
            )
            .toList(),
      );
    });
    _scrollToBottom();
  }

  Future<List<String>> getUsernames() async {
    final users = HiveDBService.getAllUsers();
    return users.map((user) => user.name.split(" ").first).toList();
  }

  @override
  void initState() {
    super.initState();
    _initializeChatService();
    _loadChatHistory();
    checkConnection();
    _messageController.addListener(() {
      setState(() {
        _canSend = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> _initializeChatService() async {
    final List<String> usernames = await getUsernames();
    final String userName = usernames.isNotEmpty ? usernames.first : 'User';

    setState(() {
      chatService = ChatService(userName: userName);
    });
  }

  String getTimeNow() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  void _onSendPressed(String userText) async {
    FocusScope.of(context).unfocus();
    if (userText.trim().isEmpty) return;

    final nowTime = getTimeNow();

    if (!mounted) return;
    setState(() {
      messages.add({
        "isMe": true,
        "text": userText,
        "time": nowTime,
        "isAudio": false,
      });
      messages.add({"isMe": false, "isTyping": true, "time": ''});
      _messageController.clear();
    });

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    final message = ChatMessage(
      sender: "user",
      message: userText,
      timestamp: DateTime.now(), // Ensure this is a String
    );

    await HiveDBService.saveMessage(message);
    String botReply = '';
    try {
      final responseStream = chatService.sendMessageStream(userText);

      await for (final chunk in responseStream) {
        if (!mounted) return;
        if (chunk.text != null) {
          botReply += chunk.text!;
        }
      }
    } on HandshakeException {
      botReply = "⚠️ Secure connection failed.";
    } on TimeoutException {
      botReply = "⏱️ Server timed out. Please try again later.";
    } on SocketException {
      botReply = "📡 No internet connection.";
    } catch (e) {
      botReply = "❌ Unexpected error: ${e.runtimeType}";
      debugPrint(e.toString());
    }

    final botTime = getTimeNow();

    if (!mounted) return;
    setState(() {
      if (messages.isNotEmpty && messages.last['isTyping'] == true) {
        messages.removeLast();
      }

      messages.add({
        "isMe": false,
        "text": botReply,
        "time": botTime,
        "isAudio": false,
      });
    });

    final botMessage = ChatMessage(
      sender: "bot", // String
      message: botReply.trim(), // String
      timestamp: DateTime.now(), // Convert DateTime to String
    );

    await HiveDBService.saveMessage(botMessage);

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  bool isOnline = false;

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Message",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        content: Text(
          "Are you sure you want to delete this message?",
          style: GoogleFonts.inter(color: Colors.grey[700]),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              _deleteSelected(index);
              Navigator.pop(context);
              setState(() {
                _selectedMessage = null;
              });
            },
            child: Text(
              "Delete",
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copySelected() {
    if (_selectedMessage != null) {
      Clipboard.setData(ClipboardData(text: _selectedMessage!));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
      setState(() => _selectedMessage = null); // clear selection
    }
  }

  void _deleteSelected(int index) {
    final msgIndex = messages[index]["index"];
    messages.removeAt(index);
    HiveDBService.deleteMessage(msgIndex); // optional DB delete
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Message deleted")));
    setState(() => _selectedMessage = null); // clear selection
  }

  void checkConnection() async {
    bool connected = await isInternetAvailable();
    if (connected) {
      debugPrint("✅ Internet is available");
      setState(() {
        isOnline = true;
      });
    } else {
      debugPrint("🚫 No internet connection");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.bgGreen,
        appBar: AppBar(
          backgroundColor: isDark
              ? Colors.green[900]?.withOpacity(0.3)
              : Colors.green[50],
          elevation: 0,
          scrolledUnderElevation: 2,
          surfaceTintColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: isDark ? Colors.green[800] : Colors.green[100],
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.lightGreen, Colors.green[700]!],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa, color: Colors.white, size: 24),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    "Bloom",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.green[900],
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isOnline)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green[500],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Online",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Offline",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[600],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "Your mental wellness companion",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark ? Colors.green[200] : Colors.green[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            if (_selectedMessage != null) ...[
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.copy, size: 20, color: Colors.blue[700]),
                ),
                onPressed: _copySelected,
                tooltip: 'Copy message',
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red[600],
                  ),
                ),
                onPressed: () {
                  if (_selectedMessage != null) {
                    final index = messages.indexWhere(
                      (msg) => msg["text"] == _selectedMessage,
                    );
                    if (index != -1) {
                      _showDeleteDialog(index);
                    }
                  }
                },
                tooltip: 'Delete message',
              ),
              const SizedBox(width: 4),
            ] else ...[
              IconButton(
                onPressed: () {
                  // TODO: Implement menu or overflow actions
                },
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.green[800]?.withOpacity(0.3)
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: isDark ? Colors.green[200] : Colors.green[700],
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Message List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return KeyedSubtree(
                      key: ValueKey('$index-${msg["text"]}'),
                      child: ChatBubble(
                        onSelect: () =>
                            setState(() => _selectedMessage = msg["text"]),
                        key: ValueKey('$index-${msg["text"]}'),
                        text: msg["text"],
                        time: msg["time"],
                        isMe: msg["isMe"],
                        isTyping: msg["isTyping"] ?? false,
                        onDelete: () {
                          setState(() {
                            messages.removeAt(index);
                            HiveDBService.deleteMessage(
                              msg["index"],
                            ); // optional DB delete
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Tags and Input Area
            Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.headphones),
                          onPressed: () {
                            /*Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => VoiceChat(
                                      onTranscriptionComplete: _onSendPressed,
                                    ),
                              ),
                            );*/
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            minLines: 1,
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              fillColor: Theme.of(
                                context,
                              ).scaffoldBackgroundColor,
                              hintText: "Message Bloom...",
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: _canSend ? Colors.black : Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send, color: Colors.white),
                            onPressed: _canSend
                                ? () => _onSendPressed(_messageController.text)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String? text;
  final String time;
  final bool isMe;
  final bool isTyping;
  final bool isSelected; // 👈 Track selection state
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;
  final VoidCallback? onReply; // 👈 New: Reply functionality
  final VoidCallback? onCopy; // 👈 New: Copy to clipboard

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    this.isTyping = false,
    this.isSelected = false, // 👈 Default to false
    this.onDelete,
    this.onSelect,
    this.onReply,
    this.onCopy,
  });

  /// Enhanced text formatter using flutter_markdown
  Widget _formattedText(String text, BuildContext context) {
    final isMe = this.isMe;
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.plusJakartaSans(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 15,
          height: 1.4,
        ),
        strong: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: isMe ? Colors.white : Colors.black87,
        ),
        em: GoogleFonts.plusJakartaSans(
          fontStyle: FontStyle.italic,
          color: isMe ? Colors.white : Colors.black87,
        ),
        code: GoogleFonts.robotoMono(
          backgroundColor: isMe
              ? Colors.blue.shade700
              : AppColors.botBubble.withOpacity(0.8),
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Shows context menu options
  void _showContextMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: [
        if (onCopy != null)
          PopupMenuItem(
            value: 'copy',
            onTap: onCopy,
            child: Row(
              children: [
                const Icon(Icons.copy, size: 20),
                const SizedBox(width: 10),
                Text('Copy', style: GoogleFonts.plusJakartaSans()),
              ],
            ),
          ),
        if (onReply != null)
          PopupMenuItem(
            value: 'reply',
            onTap: onReply,
            child: Row(
              children: [
                Icon(Icons.reply, size: 20, color: Colors.blue.shade600),
                const SizedBox(width: 10),
                Text('Reply', style: GoogleFonts.plusJakartaSans()),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            onTap: onDelete,
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                const SizedBox(width: 10),
                Text(
                  'Delete',
                  style: GoogleFonts.plusJakartaSans(color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.75;

    // Check for interactive tags
    final String content = (text ?? '');

    // Parse duration if present
    int? duration;
    final RegExp tagRegex = RegExp(r'\[BREATHING_EXERCISE(?::(\d+))?\]');
    final match = tagRegex.firstMatch(content);

    bool hasBreathingTag = false;

    if (match != null) {
      hasBreathingTag = true;
      if (match.group(1) != null) {
        duration = int.tryParse(match.group(1)!);
      }
    } else if (!isMe &&
        (content.toLowerCase().contains('breathing exercise') ||
            content.toLowerCase().contains('deep breathing'))) {
      hasBreathingTag = true;
    }

    final String cleanText = content.replaceAll(tagRegex, '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.lightImpact();
          onSelect?.call();
          _showContextMenu(context);
        },
        onTap: () {
          if (isSelected) {
            onSelect?.call(); // Deselect on tap if selected
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? (isMe ? Colors.blue.shade50 : Colors.green.shade50)
                : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    backgroundColor: Colors.lightGreen.shade400,
                    radius: 16,
                    child: Icon(Icons.spa, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.userBubble
                                : AppColors.botBubble,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              isTyping
                                  ? SizedBox(
                                      width: 60,
                                      height: 24,
                                      child: Lottie.asset(
                                        'assets/animations/mem_load.json',
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : _formattedText(cleanText, context),

                              // Interactive Action Button
                              if (hasBreathingTag && !isTyping) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      CupertinoPageRoute(
                                        builder: (context) =>
                                            FlowerBreathScreen(
                                              durationSeconds: duration,
                                              onComplete: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.air,
                                          color: Colors.green.shade800,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Start Breathing Session",
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe) ...[
                              // Status indicators could go here
                              // Icon(Icons.done_all, size: 12, color: Colors.blue),
                              // const SizedBox(width: 4),
                            ],
                            Text(
                              time,
                              style: GoogleFonts.workSans(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.done_all,
                                size: 12,
                                color: Colors.blue.shade500,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
