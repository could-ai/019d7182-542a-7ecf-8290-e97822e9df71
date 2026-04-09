import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const EmotionIntentApp());
}

class EmotionIntentApp extends StatelessWidget {
  const EmotionIntentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Emotion & Intent Classifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ChatScreen(),
      },
    );
  }
}

// --- Models ---

enum Emotion { happy, sad, angry, neutral }
enum Intent { complaint, query, feedback, unknown }

class ClassificationResult {
  final Emotion emotion;
  final Intent intent;
  final double confidence;

  ClassificationResult({
    required this.emotion,
    required this.intent,
    required this.confidence,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ClassificationResult? result;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.result,
    this.isTyping = false,
  });
}

// --- Mock ML Backend ---

class MockMLBackend {
  static Future<ClassificationResult> analyzeText(String text) async {
    // Simulate network and processing delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final lowerText = text.toLowerCase();
    final random = Random();
    
    Emotion emotion = Emotion.neutral;
    Intent intent = Intent.unknown;
    
    // Simple keyword heuristics for mock purposes
    if (lowerText.contains('disappoint') || lowerText.contains('bad') || lowerText.contains('terrible') || lowerText.contains('angry') || lowerText.contains('hate') || lowerText.contains('worst')) {
      emotion = Emotion.angry;
      intent = Intent.complaint;
    } else if (lowerText.contains('happy') || lowerText.contains('good') || lowerText.contains('great') || lowerText.contains('love') || lowerText.contains('excellent') || lowerText.contains('amazing')) {
      emotion = Emotion.happy;
      intent = Intent.feedback;
    } else if (lowerText.contains('sad') || lowerText.contains('cry') || lowerText.contains('depress') || lowerText.contains('sorry')) {
      emotion = Emotion.sad;
      intent = Intent.feedback;
    } else if (lowerText.contains('how') || lowerText.contains('what') || lowerText.contains('why') || lowerText.contains('when') || lowerText.contains('help') || lowerText.contains('question')) {
      emotion = Emotion.neutral;
      intent = Intent.query;
    } else {
      // Default fallback
      emotion = Emotion.neutral;
      intent = Intent.feedback;
    }

    // Generate a realistic looking confidence score between 75% and 99%
    double confidence = 75.0 + random.nextDouble() * 24.0;

    return ClassificationResult(
      emotion: emotion,
      intent: intent,
      confidence: confidence,
    );
  }
}

// --- UI Components ---

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isInputEmpty = true;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _isInputEmpty = _textController.text.trim().isEmpty;
      });
    });
    
    // Add initial welcome message
    _messages.add(
      ChatMessage(
        text: "Hi there! 👋 I'm your AI Text Analyzer. Send me a message, and I'll classify its emotion and intent.",
        isUser: false,
        timestamp: DateTime.now(),
      )
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      
      // Add typing indicator
      _messages.add(ChatMessage(
        text: "",
        isUser: false,
        timestamp: DateTime.now(),
        isTyping: true,
      ));
    });
    
    _scrollToBottom();

    // Call Mock ML Backend
    try {
      final result = await MockMLBackend.analyzeText(text);
      
      if (!mounted) return;

      setState(() {
        // Remove typing indicator
        _messages.removeLast();
        
        // Add bot response with classification
        _messages.add(ChatMessage(
          text: text, // Store original text for context if needed
          isUser: false,
          timestamp: DateTime.now(),
          result: result,
        ));
      });
      
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: "Sorry, an error occurred while analyzing the text.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    if (message.isTyping) {
                      return const TypingIndicatorBubble();
                    }
                    return MessageBubble(message: message);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.purpleAccent),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Classifier',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Emotion & Intent Analysis',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white70),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History feature coming soon!')),
                  );
                },
                tooltip: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.white70),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice input activated (Mock)')),
                  );
                },
                tooltip: 'Voice Input',
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type a message to analyze...',
                      hintStyle: TextStyle(color: Colors.white50),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isInputEmpty ? Colors.grey.withOpacity(0.3) : Colors.deepPurpleAccent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _isInputEmpty
                      ? null
                      : () => _handleSubmitted(_textController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: message.isUser
                ? _buildUserBubble()
                : _buildBotBubble(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(
        message.text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildBotBubble(BuildContext context) {
    if (message.result == null) {
      // Simple text message (like the welcome message)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // Classification Result Card (Glassmorphism)
    final result = message.result!;
    final emotionData = _getEmotionData(result.emotion);
    final intentData = _getIntentData(result.intent);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Analysis Result",
                style: TextStyle(
                  color: Colors.white50,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              // Emotion Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: emotionData.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: emotionData.color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text(emotionData.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Emotion", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          emotionData.label,
                          style: TextStyle(
                            color: emotionData.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Intent Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: intentData.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: intentData.color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(intentData.icon, color: intentData.color, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Intent", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          intentData.label,
                          style: TextStyle(
                            color: intentData.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Confidence Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Confidence Score",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    "${result.confidence.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: result.confidence / 100,
                backgroundColor: Colors.white.withOpacity(0.1),
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _EmotionDisplayData _getEmotionData(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return _EmotionDisplayData("Happy", "😊", Colors.greenAccent);
      case Emotion.sad:
        return _EmotionDisplayData("Sad", "😢", Colors.blueAccent);
      case Emotion.angry:
        return _EmotionDisplayData("Angry", "😡", Colors.redAccent);
      case Emotion.neutral:
        return _EmotionDisplayData("Neutral", "😐", Colors.grey);
    }
  }

  _IntentDisplayData _getIntentData(Intent intent) {
    switch (intent) {
      case Intent.complaint:
        return _IntentDisplayData("Complaint", Icons.warning_amber_rounded, Colors.orangeAccent);
      case Intent.query:
        return _IntentDisplayData("Query", Icons.help_outline_rounded, Colors.lightBlueAccent);
      case Intent.feedback:
        return _IntentDisplayData("Feedback", Icons.rate_review_outlined, Colors.purpleAccent);
      case Intent.unknown:
        return _IntentDisplayData("Unknown", Icons.device_unknown, Colors.grey);
    }
  }
}

class _EmotionDisplayData {
  final String label;
  final String emoji;
  final Color color;
  _EmotionDisplayData(this.label, this.emoji, this.color);
}

class _IntentDisplayData {
  final String label;
  final IconData icon;
  final Color color;
  _IntentDisplayData(this.label, this.icon, this.color);
}

class TypingIndicatorBubble extends StatelessWidget {
  const TypingIndicatorBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Analyzing intent...",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
