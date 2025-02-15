import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(),
        useMaterial3: true,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatController extends GetxController {
  var messages = <Map<String, String>>[].obs;
  var isLoading = false.obs;
  TextEditingController textController = TextEditingController();

  Future<void> sendMessage() async {
    if (textController.text.trim().isEmpty) return;
    String userMessage = textController.text.trim();
    messages.add({"role": "user", "message": userMessage});
    textController.clear();
    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat'),
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"messages": messages}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        messages.add({"role": "bot", "message": data['response']});
      } else {
        messages.add({"role": "bot", "message": "Error: Unable to fetch response"});
      }
    } catch (e) {
      messages.add({"role": "bot", "message": "Error: $e"});
    }
    isLoading.value = false;
  }
}

class ChatScreen extends StatelessWidget {
  final ChatController controller = Get.put(ChatController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DeepSeek Chat", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                var msg = controller.messages[index];
                bool isUser = msg["role"] == "user";
                return Row(
                  mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isUser) CircleAvatar(child: Icon(Icons.android)),
                    Flexible(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg["message"]!,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    if (isUser) CircleAvatar(child: Icon(Icons.person)),
                  ],
                );
              },
            )),
          ),
          Obx(() => controller.isLoading.value
              ? Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(),
          )
              : SizedBox.shrink()),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: controller.sendMessage,
                  child: Icon(Icons.send),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
