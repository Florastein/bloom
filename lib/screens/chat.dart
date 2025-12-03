/*import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> messages = [
    {"isMe": false, "text": "Excited to jump on the design crit session today.", "time": "2:58 PM", "isAudio": false},
    {"isMe": true, "text": "Excited to jump on the design crit session today.", "time": "3:04 PM", "isAudio": false},
    {"isMe": false, "text": "Audio Message", "time": "3:06 PM", "isAudio": true},
    {"isMe": false, "text": "After the call, please choose some interests for the Offsite Meeting", "time": "3:06 PM", "isAudio": false},
    {"isMe": true, "text": "Awesome, that sounds very interesting!", "time": "3:08 PM", "isAudio": false},
  ];

  final List<String> tags = ["🍕 Food & Cooking", "⚽ Sport", "🌿 Nature", "📖 Education"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Align(
                      alignment: msg["isMe"] ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: msg["isMe"] ? Colors.blue.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            msg["isAudio"]
                                ? Row(
                                    children: [
                                      Icon(Icons.play_arrow),
                                      SizedBox(width: 5),
                                      Text("Audio Message"),
                                    ],
                                  )
                                : Text(msg["text"]),
                            SizedBox(height: 5),
                            Text(msg["time"], style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        
            // Tags Selection
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Wrap(
                spacing: 8,
                children: tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.black12,
                  );
                }).toList(),
              ),
            ),
        
            // Chat Input Field
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Message Martin...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.send), onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/

import 'dart:async';
import 'dart:io';

import 'package:bloom/models/chat_message.dart';
import 'package:bloom/services/db_service.dart';
import 'package:bloom/services/gemini_chat.dart';
import 'package:bloom/services/online.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

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
        backgroundColor: Colors.green[50],
        appBar: AppBar(
          backgroundColor: Colors.green[50],
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.lightGreen,
              radius: 20,
              child: const Icon(Icons.spa, color: Colors.white, size: 32),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Bloom",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                ),
              ),
              isOnline
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Online",
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Offline",
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
          actions: _selectedMessage != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copySelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      if (_selectedMessage != null) {
                        final index = messages.indexWhere(
                          (msg) => msg["text"] == _selectedMessage,
                        );
                        if (index != -1) {
                          _deleteSelected(index);
                        }
                      }
                    },
                  ),
                ]
              : [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
          automaticallyImplyLeading: true,
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

/*class ChatBubble extends StatelessWidget {
  final String? text;
  final String time;
  final bool isMe;
  final bool isTyping;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    this.isTyping = false,
    this.onDelete,
  });

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text ?? ''));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Copied to clipboard")),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(context);
                    if (onDelete != null) onDelete!();
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.7;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 20,
                child: Image.asset('assets/images/esther.png'),
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: GestureDetector(
                onLongPress: () => _showActionSheet(context),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isMe ? 12 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isTyping)
                          SizedBox(
                            width: 50,
                            height: 20,
                            child: Lottie.asset(
                              'assets/animations/mem_load.json',
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          SelectableText(
                            text ?? '',
                            style: GoogleFonts.workSans(color: Colors.black87),
                          ),
                        if (!isTyping) const SizedBox(height: 5),
                        if (!isTyping)
                          Text(
                            time.toString(),
                            style: GoogleFonts.workSans(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (isMe) ...[
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}*/

/*class ChatBubble extends StatefulWidget {
  final String? text;
  final String time;
  final bool isMe;
  final bool isTyping;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    this.isTyping = false,
    this.onDelete,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.text ?? ''));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Copied to clipboard")),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onDelete != null) widget.onDelete!();
                  },
                ),
              ],
            ),
          ),
    );
  }

  /// Parses text and applies bold formatting when surrounded by "*"
  Widget _formattedText(String text) {
    final boldRegex = RegExp(r'\*(.*?)\*');
    final spans = <TextSpan>[];
    int start = 0;

    for (final match in boldRegex.allMatches(text)) {
      // Add normal text before the match
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: GoogleFonts.workSans(color: Colors.black87),
          ),
        );
      }

      // Add bold text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );

      start = match.end;
    }

    // Add remaining text after last match
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: GoogleFonts.workSans(color: Colors.black87),
        ),
      );
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.7;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!widget.isMe) ...[
              CircleAvatar(
                radius: 20,
                child: Image.asset('assets/images/esther.png'),
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: GestureDetector(
                onLongPress: () => _showActionSheet(context),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Column(
                    crossAxisAlignment:
                        widget.isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              widget.isMe
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(widget.isMe ? 12 : 0),
                            bottomRight: Radius.circular(widget.isMe ? 0 : 12),
                          ),
                        ),
                        child:
                            widget.isTyping
                                ? SizedBox(
                                  width: 50,
                                  height: 20,
                                  child: Lottie.asset(
                                    'assets/animations/mem_load.json',
                                    fit: BoxFit.contain,
                                  ),
                                )
                                : _formattedText(widget.text ?? ''),
                      ),
                      if (!widget.isTyping) ...[
                        const SizedBox(height: 5),
                        Text(
                          widget.time,
                          style: GoogleFonts.workSans(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            if (widget.isMe) ...[
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 20,
                child: Icon(Icons.person, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}*/

class ChatBubble extends StatelessWidget {
  final String? text;
  final String time;
  final bool isMe;
  final bool isTyping;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect; // 👈 New callback

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    this.isTyping = false,
    this.onDelete,
    this.onSelect, // 👈 Pass from parent
  });

  /// Parses text and applies bold formatting when surrounded by "*"
  Widget _formattedText(String text) {
    final boldRegex = RegExp(r'\*(.*?)\*');
    final spans = <TextSpan>[];
    int start = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: GoogleFonts.workSans(color: Colors.black87),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: GoogleFonts.workSans(color: Colors.black87),
        ),
      );
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.7;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                backgroundColor: Colors.lightGreen,
                radius: 20,
                child: const Icon(Icons.spa, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress:
                    onSelect, // 👈 Tell parent this bubble was selected
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue.shade100 : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 12),
                          ),
                        ),
                        child: isTyping
                            ? SizedBox(
                                width: 50,
                                height: 20,
                                child: Lottie.asset(
                                  'assets/animations/mem_load.json',
                                  fit: BoxFit.contain,
                                ),
                              )
                            : _formattedText(text ?? ''),
                      ),
                      if (!isTyping) ...[
                        const SizedBox(height: 5),
                        Text(
                          time,
                          style: GoogleFonts.workSans(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 20,
                child: Icon(Icons.person, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/*class VoiceChat extends StatefulWidget {
  final Function(String) onTranscriptionComplete;

  const VoiceChat({super.key, required this.onTranscriptionComplete});

  @override
  State<VoiceChat> createState() => _VoiceChatState();
}

class _VoiceChatState extends State<VoiceChat> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _startListening();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() => _transcribedText = result.recognizedWords);
        },
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _cancel() {
    _stopListening();
    Navigator.pop(context);
  }

  void _send() {
    _stopListening();
    widget.onTranscriptionComplete(_transcribedText.trim());
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Lottie.asset(
                'assets/animations/voice.json',
                height: 180,
                repeat: true,
              ),
              const SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Text(
                  _transcribedText.isEmpty
                      ? "Say something to Esther..."
                      : _transcribedText,
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _cancel,
                      child: Container(
                        padding: EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          color: Colors.red[300],
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                    ),

                    GestureDetector(
                      onTap: _transcribedText.trim().isNotEmpty ? _send : null,
                      child: Container(
                        padding: EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(Icons.send, color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/

/*class VoiceChat extends StatefulWidget {
  final Function(String) onTranscriptionComplete;

  const VoiceChat({super.key, required this.onTranscriptionComplete});

  @override
  State<VoiceChat> createState() => _VoiceChatState();
}

class _VoiceChatState extends State<VoiceChat> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _transcribedText = "Error: $error";
        });
      },
    );

    setState(() => _permissionGranted = available);

    if (available) {
      _startListening();
    } else {
      setState(() {
        _transcribedText = "Microphone permission not granted";
      });
    }
  }

  void _startListening() async {
    if (!_permissionGranted) return;

    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        setState(() => _transcribedText = result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: true,
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _cancel() {
    _stopListening();
    Navigator.pop(context);
  }

  void _send() {
    _stopListening();
    widget.onTranscriptionComplete(_transcribedText.trim());
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: _cancel,
        ),
        title: Text(
          'Voice Message',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated voice visualization
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.grey.shade800 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing animation when listening
                  if (_isListening)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      width: _isListening ? 180 : 160,
                      height: _isListening ? 180 : 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),

                  // Microphone icon or animation
                  _isListening
                      ? Lottie.asset(
                        'assets/animations/voice_waves.json',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      )
                      : Icon(
                        Icons.mic,
                        size: 60,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Transcription text container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _transcribedText.isEmpty
                        ? "Speak now..."
                        : _transcribedText,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (_transcribedText.isEmpty) const SizedBox(height: 8),

                  if (_transcribedText.isEmpty)
                    Text(
                      "Your words will appear here",
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status indicator
            Text(
              _isListening ? "Listening..." : "Tap to start speaking",
              style: TextStyle(
                color:
                    _isListening
                        ? Colors.blue.shade500
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color:
                              isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Toggle listening/send button
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _transcribedText.isNotEmpty
                              ? _send
                              : _toggleListening,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _transcribedText.isNotEmpty
                                ? Colors.blue.shade600
                                : (_isListening
                                    ? Colors.red.shade500
                                    : Colors.blue.shade600),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _transcribedText.isNotEmpty
                                ? Icons.send_rounded
                                : (_isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _transcribedText.isNotEmpty
                                ? 'Send'
                                : (_isListening ? 'Stop' : 'Start'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
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
}*/
