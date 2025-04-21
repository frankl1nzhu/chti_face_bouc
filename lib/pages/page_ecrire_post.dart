import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/membre.dart';

class PageEcrirePost extends StatefulWidget {
  final Membre member; // Current user
  final Function(int) newSelection; // Callback to change tabs

  const PageEcrirePost({
    super.key,
    required this.member,
    required this.newSelection,
  });

  @override
  State<PageEcrirePost> createState() => _PageEcrirePostState();
}

class _PageEcrirePostState extends State<PageEcrirePost> {
  // Controller for the text input
  final TextEditingController textController = TextEditingController();

  // Holds the selected image file
  XFile? _imageFile;

  // Track if post is being sent
  bool _isSending = false;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  // Function to handle image selection
  Future<void> _takePic(ImageSource source) async {
    try {
      setState(() {
        // 隐藏任何以前的错误消息
        if (_isSending) return; // 如果正在发送则不允许选择新图片
      });

      final ImagePicker picker = ImagePicker();

      // 显示加载指示器
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Chargement de l\'image...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // 选择图片并限制大小
      XFile? newFile = await picker.pickImage(
        source: source,
        maxWidth: 1200, // 限制宽度，平衡质量和性能
        imageQuality: 85, // 适当压缩图片质量
      );

      if (newFile != null) {
        // 检查文件大小
        final file = File(newFile.path);
        final fileSize = await file.length();
        final fileSizeInMB = fileSize / (1024 * 1024);

        print(
          "Selected image: ${newFile.path}, size: ${fileSizeInMB.toStringAsFixed(2)} MB",
        );

        if (fileSize > 10 * 1024 * 1024) {
          // 10MB限制
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image trop volumineuse (max: 10MB)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _imageFile = newFile; // 更新状态以显示预览
        });

        // 显示成功消息
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image sélectionnée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 用户取消了选择
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to handle post submission
  void _sendPost() async {
    try {
      FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard

      // Check if post has content
      if (_imageFile == null && textController.text.trim().isEmpty) {
        // Show error message - cannot send empty post
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez écrire quelque chose ou ajouter une image.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSending = true; // Show loading state
      });

      // Show loading indicator
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
              Text('Envoi du post en cours...'),
            ],
          ),
          duration: Duration(minutes: 1), // 长时间显示，直到上传完成
        ),
      );

      print("Starting post creation with image: ${_imageFile != null}");
      await ServiceFirestore().createPost(
        member: widget.member,
        text: textController.text.trim(),
        image: _imageFile, // Pass the selected image file
      );

      // Clear fields
      setState(() {
        _imageFile = null;
        textController.clear();
        _isSending = false;
      });

      // Show success message
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Post envoyé avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      // Switch to home tab
      widget.newSelection(0);
    } catch (e) {
      print("Error sending post: $e");
      setState(() {
        _isSending = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'envoi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to clear selected image
  void _clearImage() {
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.border_color, color: Colors.brown),
                      const SizedBox(width: 8),
                      const Text(
                        "Ecrire un post",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Show user info who is creating the post
                      Text(
                        "Par ${widget.member.fullName}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Divider(),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText: 'Votre post',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null, // Allow multiple lines
                    minLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Display selected image preview if available
                  if (_imageFile != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_imageFile!.path),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 5.0, color: Colors.black),
                            ],
                          ),
                          onPressed: _clearImage,
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Camera and gallery buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Galerie"),
                          onPressed:
                              _imageFile == null
                                  ? () => _takePic(ImageSource.gallery)
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Caméra"),
                          onPressed:
                              _imageFile == null
                                  ? () => _takePic(ImageSource.camera)
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendPost,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child:
                  _isSending
                      ? const CircularProgressIndicator()
                      : const Text("Envoyer"),
            ),
          ),
        ],
      ),
    );
  }
}
