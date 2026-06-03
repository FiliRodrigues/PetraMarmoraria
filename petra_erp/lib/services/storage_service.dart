import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client;
  static const String _bucket = 'assets';

  StorageService(this._client);

  Future<String> uploadFile({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    String? contentType,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final mime = contentType ?? 'application/octet-stream';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: true),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// Faz upload dos bytes para o bucket público e retorna a URL pública.
  /// [folder] separa os arquivos (ex: 'logos', 'desenhos').
  Future<String> uploadImage({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    return uploadFile(bytes: bytes, folder: folder, fileName: fileName, contentType: contentType);
  }
}
