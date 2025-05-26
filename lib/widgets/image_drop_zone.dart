import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class ImageDropZone extends StatelessWidget {
  final String? image;
  final Function(String?) onImageChanged;

  const ImageDropZone({
    super.key,
    this.image,
    required this.onImageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF484848),
      ),
      child: image != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _decodeBase64(image!),
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => onImageChanged(null),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _pickImage,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Tap to add image',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
      onImageChanged(base64String);
    }
  }

  Uint8List _decodeBase64(String base64String) {
    final base64Data = base64String.split(',').last;
    return base64Decode(base64Data);
  }
}
