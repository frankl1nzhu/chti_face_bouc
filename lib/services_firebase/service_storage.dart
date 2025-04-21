import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class ServiceStorage {
  // 单例模式实现
  static final ServiceStorage _instance = ServiceStorage._internal();

  factory ServiceStorage() {
    return _instance;
  }

  ServiceStorage._internal();

  // 获取Firebase Storage实例
  static final instance = FirebaseStorage.instance;
  Reference get ref => instance.ref();

  // 上传图片并返回下载URL
  Future<String?> addImage({
    required File file, // 图片文件
    required String folder, // 文件夹名称 (例如: 'members', 'posts')
    required String userId, // 用户ID，用于子文件夹结构
    required String imageName, // 图片名称 (例如: 时间戳, UUID)
  }) async {
    try {
      print(
        "Starting upload process for image in folder: $folder, userId: $userId, imageName: $imageName",
      );

      // 获取文件扩展名
      final fileExtension = path.extension(file.path).toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

      if (!validExtensions.contains(fileExtension)) {
        print("Error: Invalid file extension: $fileExtension");
        return null;
      }

      // 创建引用: /folder/userId/imageName.ext
      final String fileName = "$imageName$fileExtension";
      final reference = ref.child(folder).child(userId).child(fileName);

      print("Created storage reference: ${reference.fullPath}");

      // 设置元数据
      final metadata = SettableMetadata(
        contentType: 'image/${fileExtension.substring(1)}',
        customMetadata: {
          'userId': userId,
          'uploadDate': DateTime.now().toString(),
        },
      );

      // 上传文件
      print("Starting file upload...");
      UploadTask task = reference.putFile(file, metadata);

      // 监听上传状态
      task.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print("Upload progress: ${progress.toStringAsFixed(2)}%");
        },
        onError: (error) {
          print("Upload error during progress monitoring: $error");
        },
      );

      // 等待上传完成
      print("Waiting for upload completion...");
      TaskSnapshot snapshot = await task;

      // 获取下载URL
      print("Upload complete, getting download URL...");
      String imageUrl = await snapshot.ref.getDownloadURL();

      print("Image uploaded successfully: $imageUrl");
      return imageUrl;
    } on FirebaseException catch (e) {
      print("Firebase Storage error: [${e.code}] ${e.message}");
      if (e.code == 'unauthorized') {
        print("User doesn't have permission to access the storage location");
      } else if (e.code == 'canceled') {
        print("Upload was canceled");
      } else if (e.code == 'object-not-found') {
        print("No object exists at the desired reference");
      } else if (e.code == 'quota-exceeded') {
        print("Quota on your Firebase Storage bucket has been exceeded");
      }
      return null;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // 从存储中删除图片
  Future<bool> deleteImage({required String imageUrl}) async {
    try {
      // 从URL获取存储引用
      print("Attempting to delete image: $imageUrl");
      Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      print("Image deleted successfully");
      return true;
    } on FirebaseException catch (e) {
      print("Firebase delete error: [${e.code}] ${e.message}");
      return false;
    } catch (e) {
      print("Error deleting image: $e");
      return false;
    }
  }
}
