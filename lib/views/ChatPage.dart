// import 'package:flutter/material.dart';
// import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
// import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// import 'package:uuid/uuid.dart';
// import 'Const.dart';

// class ChatPage extends StatefulWidget {
//   final ChatGPTService chatGPTService;

//   const ChatPage({Key? key, required this.chatGPTService}) : super(key: key);

//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> {
//   List<types.Message> _messages = [];
//   bool _isLoading = false;

//   final _user = const types.User(
//     id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
//   );

//   final _chatGPTUser = const types.User(
//     id: 'chatgpt',
//     firstName: 'Achiva',
//   );

//   @override
//   void initState() {
//     super.initState();
//     _addMessage(_createSystemMessage("Hello! How can I help you today?"));
//   }

//   types.TextMessage _createSystemMessage(String text) {
//     return types.TextMessage(
//       author: _chatGPTUser,
//       createdAt: DateTime.now().millisecondsSinceEpoch,
//       id: const Uuid().v4(),
//       text: text,
//     );
//   }

//   void _addMessage(types.Message message) {
//     setState(() {
//       _messages.insert(0, message);
//     });
//   }

//   void _handleSendPressed(types.PartialText message) async {
//     final textMessage = types.TextMessage(
//       author: _user,
//       createdAt: DateTime.now().millisecondsSinceEpoch,
//       id: const Uuid().v4(),
//       text: message.text,
//     );

//     _addMessage(textMessage);

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final response = await widget.chatGPTService.getChatGPTResponse(message.text);

//       final chatGPTMessage = types.TextMessage(
//         author: _chatGPTUser,
//         createdAt: DateTime.now().millisecondsSinceEpoch,
//         id: const Uuid().v4(),
//         text: response,
//       );

//       _addMessage(chatGPTMessage);
//     } catch (e) {
//       _addMessage(_createSystemMessage("Sorry, I encountered an error: ${e.toString()}"));
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) => Scaffold(
//         // appBar: AppBar(
//         //   title: const Text('ChatGPT Chat'),
//         // ),
//         body: Stack(
//           children: [
//             Chat(
//               messages: _messages,
//               onSendPressed: _handleSendPressed,
//               showUserAvatars: true,
//               showUserNames: true,
//               user: _user,
//             ),
//             if (_isLoading)
//               const Positioned.fill(
//                 child: Center(
//                   child: CircularProgressIndicator(),
//                 ),
//               ),
//           ],
//         ),
//       );
// }

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final chatGPTService = ChatGPTService(
//       apiKey: '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',
//     );

//     return MaterialApp(
//       home: ChatPage(chatGPTService: chatGPTService),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:uuid/uuid.dart';

import 'Const.dart';

enum CustomMessageType { typing }

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});


  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<types.Message> _messages = [];
  final gemini = Gemini.instance;
  bool _isLoading = false;
  bool _isDisposed = false;

  final _user = const types.User(
    id: '0',
    firstName: 'User',
  );

  final _achivaUser = const types.User(
    id: '1',
    firstName: 'Achiva',
  );

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
    _testAchivaConnection();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _testAchivaConnection() async {
    try {
      final result = await gemini.text('Hello! This is a test message.');
      if (!_isDisposed) {
        print('Achiva connection test: ${result?.content?.parts?.first.text}');
      }
    } catch (e) {
      if (!_isDisposed) {
        print('Achiva connection error: $e');
        _addMessage(types.TextMessage(
          author: _achivaUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text:
              'Unable to connect to Achiva. Please check your internet connection and API key.',
        ));
      }
    }
  }

  void _addInitialMessage() {
    _addMessage(types.TextMessage(
      author: _achivaUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: 'Hello! How can I help you today?',
    ));
  }

  void _addMessage(types.Message message) {
    if (!_isDisposed) {
      setState(() {
        _messages.insert(0, message);
      });
    }
  }

  void _sendCutOffMessage() {
    _addMessage(types.TextMessage(
      author: _achivaUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text:
          "It seems like your message might have been cut off. Could you please provide more details? I'm here to help!",
    ));
  }

  bool _isIncompleteMessage(String message) {
    final trimmedMessage = message.trim();

    if (trimmedMessage.length == 1 &&
        trimmedMessage.contains(RegExp(r'[a-zA-Z]'))) {
      return true;
    }

    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(trimmedMessage);
    final hasOnlyNumbersAndSpecials =
        RegExp(r'^[^a-zA-Z]*$').hasMatch(trimmedMessage);

    return hasOnlyNumbersAndSpecials || !hasLetters;
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final trimmedMessage = message.text.trim();

    if (trimmedMessage.isEmpty) {
      return;
    }

    if (_isLoading) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (_isIncompleteMessage(trimmedMessage)) {
      _addMessage(types.TextMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: trimmedMessage));
      _sendCutOffMessage();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Add user message
    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: trimmedMessage,
    );
    _addMessage(userMessage);

    // Add typing indicator
    final typingMessage = types.CustomMessage(
      author: _achivaUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      metadata: {'type': CustomMessageType.typing.name},
    );
    _addMessage(typingMessage);

    try {
      String fullResponse = '';

      await for (final chunk in gemini.streamGenerateContent(trimmedMessage)) {
        if (_isDisposed) break;

        final response = chunk.content?.parts
                ?.fold("", (previous, current) => "$previous${current.text}") ??
            "";

        fullResponse += response;

        if (_messages.isNotEmpty) {
          if (_messages[0] is types.CustomMessage) {
            setState(() {
              _messages.removeAt(0);
              _addMessage(types.TextMessage(
                author: _achivaUser,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                id: const Uuid().v4(),
                text: fullResponse,
              ));
            });
          } else {
            setState(() {
              _messages[0] = (_messages[0] as types.TextMessage).copyWith(
                text: fullResponse,
              );
            });
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!_isDisposed) {
        // Remove typing indicator if it exists
        if (_messages.isNotEmpty && _messages[0] is types.CustomMessage) {
          setState(() {
            _messages.removeAt(0);
          });
        }

        _addMessage(types.TextMessage(
          author: _achivaUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: 'Sorry, I encountered an error. Please try again.',
        ));
      }
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

     WidgetsFlutterBinding.ensureInitialized();
   Gemini.init(
     apiKey: GEMINI_API_KEY,
 );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Set the height of the AppBar
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                      Color.fromARGB(255, 30, 12, 48),
                Color.fromARGB(255, 77, 64, 98),
              ], // Define your gradient colors
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent, // Make background transparent
            elevation: 0, // Remove shadow
            leading: IconButton(
  icon: const Icon(
    Icons.arrow_back,
    color: Colors.white,
  ),
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Leave Conversation?',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'If you leave now, this conversation will be lost.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Stay',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 30, 12, 48),
                    Color.fromARGB(255, 77, 64, 98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Leave',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        );
      },
    );
  },
),
            title: const Text(
              'Achiva Assistant Chat',
              style:
                  TextStyle(color: Colors.white), // Change text color to white
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
                      Color.fromARGB(255, 30, 12, 48),
        Color.fromARGB(255, 77, 64, 98),  // Gradient color 2
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  ),
  child: Chat(
    messages: _messages,
    onSendPressed: _handleSendPressed,
    user: _user,
    showUserAvatars: true,
    showUserNames: true,
    customMessageBuilder: _buildCustomMessage,
    theme: const DefaultChatTheme(
      primaryColor: Color.fromARGB(255, 31, 6, 62),
      secondaryColor: Color.fromARGB(255, 239, 239, 239),
      backgroundColor: Colors.transparent,
      userAvatarNameColors: [Colors.deepPurple],
    ),
  ),
),
    );
  }
}

Widget _buildCustomMessage(types.CustomMessage message,
    {required int messageWidth}) {
  if (message.metadata?['type'] == CustomMessageType.typing.name) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 186, 186, 186),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                _TypingDot(),
                SizedBox(width: 4),
                _TypingDot(delay: Duration(milliseconds: 150)),
                SizedBox(width: 4),
                _TypingDot(delay: Duration(milliseconds: 300)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  return const SizedBox();
}

class _TypingDot extends StatefulWidget {
  final Duration delay;
  const _TypingDot({this.delay = Duration.zero});

  @override
  _TypingDotState createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    Future.delayed(widget.delay, () {
      if (!_isDisposed) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_controller.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// Custom exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);
  @override
  String toString() => message;
}

// class ApiKeyException implements Exception {
//   final String message;
//   ApiKeyException([this.message = 'Invalid API key']);
//   @override
//   String toString() => message;
// }

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   Gemini.init(
//     apiKey: GEMINI_API_KEY,
//   );
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Achiva Assistant Chat',
//       home: const ChatPage(),
//     );
//   }
// }


const String GEMINI_API_KEY = "AIzaSyBqMMBMeDZaq-ju7BKiPRcFOpzvIBrMEJs";

