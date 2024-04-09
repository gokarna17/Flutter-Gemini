import 'dart:io';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class MessageProvider extends ChangeNotifier {
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
        "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
  );

  void addMessage(ChatMessage message) {
    messages.insert(0, message);
    notifyListeners();
  }

  void clearMessages() {
    messages.clear();
    notifyListeners();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MessageProvider(),
      child: _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late MessageProvider messageProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    messageProvider = Provider.of<MessageProvider>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text("Flutter Gemini App"),
        centerTitle: true,
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(
          onPressed: () {
            _sendMediaMessage(context);
          },
          icon: Icon(Icons.image),
        )
      ]),
      currentUser: messageProvider.currentUser,
      onSend: _sendMessage,
      messages: messageProvider.messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }
      Gemini.instance
          .streamGenerateContent(question, images: images)
          .listen((event) {
        String response = event.content?.parts
                ?.fold("", (previous, current) => "$previous${current.text}") ??
            "";

        // messageProvider.messages.clear();

        ChatMessage message = ChatMessage(
          user: messageProvider.geminiUser,
          createdAt: DateTime.now(),
          text: response,
        );

        messageProvider.addMessage(message);
      });
    } catch (e) {
      print(e);
    }
  }

  void _sendMediaMessage(BuildContext context) async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: messageProvider.currentUser,
        createdAt: DateTime.now(),
        text: "Describe the this picture",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );
      messageProvider.addMessage(chatMessage);
      _sendMessage(chatMessage);
    }
  }
}
