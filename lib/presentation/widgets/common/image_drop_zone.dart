import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

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
        border: Border.all(
            color: const Color(0xFF484848), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF2F2F31),
      ),
      child: image != null
          ? Stack(
              children: [
                Center(
                  child: Image.memory(
                    base64Decode(image!.split(',').last),
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => onImageChanged(null),
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _pickImage,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate,
                        size: 32, color: Color(0xFF484848)),
                    SizedBox(height: 8),
                    Text(
                      'Tap to add image',
                      style: TextStyle(color: Color(0xFF484848)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
      onImageChanged(base64String);
    }
  }
}
