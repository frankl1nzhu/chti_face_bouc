import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/constantes.dart';

class BoutonCamera extends StatefulWidget {
  final String type; // profilePictureKey 或 coverPictureKey
  final String id; // 用户ID

  const BoutonCamera({super.key, required this.type, required this.id});

  @override
  State<BoutonCamera> createState() => _BoutonCameraState();
}

class _BoutonCameraState extends State<BoutonCamera> {
  bool _isUploading = false;

  // 选择并上传图片
  Future<void> _takePicture(ImageSource source, BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();

      // 选择图片，根据类型限制大小
      final XFile? xFile = await picker.pickImage(
        source: source,
        maxWidth: widget.type == profilePictureKey ? 500 : 1000, // 头像较小，封面较大
        imageQuality: 80, // 适当压缩图片质量
      );

      if (xFile == null) {
        print("User cancelled image picker");
        return; // 用户取消了选择
      }

      setState(() {
        _isUploading = true;
      });

      // 显示上传指示器
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Téléchargement de l\'image...'),
            ],
          ),
          duration: Duration(minutes: 1), // 长时间显示，直到上传完成
        ),
      );

      // 转换为File对象
      File imageFile = File(xFile.path);
      print(
        "Image selected: ${imageFile.path}, size: ${await imageFile.length()} bytes",
      );

      // 确定文件夹名称
      String folder =
          widget.type == profilePictureKey || widget.type == coverPictureKey
              ? memberCollectionKey
              : postCollectionKey;

      // 执行上传
      await ServiceFirestore().updateImage(
        file: imageFile,
        folder: folder,
        memberId: widget.id,
        imageName: widget.type,
      );

      // 隐藏加载指示器并显示成功消息
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Image mise à jour avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error during image selection/upload: $e");
      // 在出错时设置上传状态为false
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据上传状态显示不同图标
    return _isUploading
        ? Container(
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8.0),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        )
        : IconButton(
          icon: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 5.0, color: Colors.black)],
          ),
          onPressed: () {
            if (_isUploading) return; // 如果正在上传，阻止新的操作

            // 显示选项：相机或图库
            showModalBottomSheet(
              context: context,
              builder: (BuildContext bc) {
                return SafeArea(
                  child: Wrap(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Galerie'),
                        onTap: () {
                          _takePicture(ImageSource.gallery, context);
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_camera),
                        title: const Text('Caméra'),
                        onTap: () {
                          _takePicture(ImageSource.camera, context);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
  }
}
