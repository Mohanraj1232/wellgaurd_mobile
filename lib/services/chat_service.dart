import 'package:dio/dio.dart';
import 'package:wellguard_ai/services/dio_client.dart';

class ChatService {
  static const String _chatEndpoint = 'https://foster-postcentral-al.ngrok-free.dev/chatbot/chat';

  /// Sends a user message to the civic chatbot backend and returns the bot reply.
  /// Throws [DioException] on network/server errors.
  static Future<String> sendMessage(String message) async {
    final dio = DioClient.getDio();

    final response = await dio.post(
      _chatEndpoint,
      data: {'message': message},
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('reply')) {
      return data['reply'] as String;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Invalid response format from chat API',
    );
  }
}
