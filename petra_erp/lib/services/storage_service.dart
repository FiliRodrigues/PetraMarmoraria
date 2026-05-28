import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  Future<String> uploadDrawing(String filePath, String orderId) async {
    try {
      final xFile = XFile(filePath);
      final bytes = await xFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'drawings/$orderId/${timestamp}_${xFile.name}';

      await _client.storage.from('service-order-drawings').uploadBinary(
        path,
        bytes,
      );

      return _client.storage.from('service-order-drawings').getPublicUrl(path);
    } catch (e) {
      throw Exception('Falha ao enviar desenho: ${e.toString()}');
    }
  }

  Future<String> uploadAvatar(String filePath, String userId) async {
    try {
      final xFile = XFile(filePath);
      final bytes = await xFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${userId}_${timestamp}.jpg';

      await _client.storage.from('avatars').uploadBinary(
        path,
        bytes,
      );

      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw Exception('Falha ao enviar avatar: ${e.toString()}');
    }
  }

  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Falha ao deletar arquivo: ${e.toString()}');
    }
  }

  Future<String?> pickImage() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery);
      return xFile?.path;
    } catch (e) {
      throw Exception('Falha ao selecionar imagem: ${e.toString()}');
    }
  }
}
