// import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

// class ChatGPTService {
//   final String apiKey;
//   late final OpenAI openAI;

//   ChatGPTService({required this.apiKey}) {
//     openAI = OpenAI.instance.build(
//       token: apiKey,
//       baseOption: HttpSetup(
//         receiveTimeout: const Duration(seconds: 60),
//         connectTimeout: const Duration(seconds: 60),
//       ),
//       enableLog: true,
//     );
//   }

//   Future<String> getChatGPTResponse(String message) async {
//     try {
//       final request = ChatCompleteText(
//         messages: [
//           Map.from({"role": "user", "content": message})
//         ],
//         maxToken: 1000,
//         model: GptTurboChatModel(), // You can also use Gpt4ChatModel() if you have access
//       );

//       final response = await openAI.onChatCompletion(request: request);
      
//       if (response != null && response.choices.isNotEmpty) {
//         return response.choices[0].message?.content ?? "No response received";
//       } else {
//         throw Exception("No response received from ChatGPT");
//       }
//     } catch (e) {
//       throw Exception("Failed to get ChatGPT response: $e");
//     }
//   }
// }


const String GEMINI_API_KEY = "AIzaSyBqMMBMeDZaq-ju7BKiPRcFOpzvIBrMEJs";


