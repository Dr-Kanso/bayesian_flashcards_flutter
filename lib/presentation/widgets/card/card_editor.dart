import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class CardEditor extends StatefulWidget {
  final Function(
      String front, String back, String? frontImage, String? backImage) onSave;
  final String? initialFront;
  final String? initialBack;
  final String? initialFrontImage;
  final String? initialBackImage;

  const CardEditor({
    super.key,
    required this.onSave,
    this.initialFront,
    this.initialBack,
    this.initialFrontImage,
    this.initialBackImage,
  });

  @override
  State<CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<CardEditor> {
  late QuillController _frontController;
  late QuillController _backController;
  String? _frontImage;
  String? _backImage;
  bool _isShowingBack = false;

  @override
  void initState() {
    super.initState();
    _frontController = QuillController.basic();
    _backController = QuillController.basic();

    if (widget.initialFront != null) {
      // Load initial content if provided
      _frontController.document = Document.fromJson(
        jsonDecode(widget.initialFront!) as List,
      );
    }

    if (widget.initialBack != null) {
      _backController.document = Document.fromJson(
        jsonDecode(widget.initialBack!) as List,
      );
    }

    _frontImage = widget.initialFrontImage;
    _backImage = widget.initialBackImage;
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Toggle buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isShowingBack = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !_isShowingBack ? Colors.blue : Colors.grey,
                  ),
                  child: const Text('Front'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isShowingBack = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isShowingBack ? Colors.blue : Colors.grey,
                  ),
                  child: const Text('Back'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Editor section
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isShowingBack ? 'Back Side' : 'Front Side',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Toolbar
                    QuillToolbar.basic(
                      controller:
                          _isShowingBack ? _backController : _frontController,
                    ),

                    const SizedBox(height: 8),

                    // Editor
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QuillEditor.basic(
                          controller: _isShowingBack
                              ? _backController
                              : _frontController,
                          placeholder: 'Enter text...',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Image section
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(_isShowingBack),
                          icon: const Icon(Icons.image),
                          label: const Text('Add Image'),
                        ),
                        const SizedBox(width: 16),
                        if ((_isShowingBack ? _backImage : _frontImage) != null)
                          ElevatedButton.icon(
                            onPressed: () => _removeImage(_isShowingBack),
                            icon: const Icon(Icons.delete),
                            label: const Text('Remove Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),

                    // Image preview
                    if ((_isShowingBack ? _backImage : _frontImage) != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildImagePreview(
                            _isShowingBack ? _backImage! : _frontImage!),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Save Card',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String base64String) {
    try {
      final bytes = base64Decode(base64String.split(',').last);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } catch (e) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Text('Invalid image'),
        ),
      );
    }
  }

  Future<void> _pickImage(bool isBack) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      final String base64String =
          'data:image/png;base64,${base64Encode(bytes)}';

      setState(() {
        if (isBack) {
          _backImage = base64String;
        } else {
          _frontImage = base64String;
        }
      });
    }
  }

  void _removeImage(bool isBack) {
    setState(() {
      if (isBack) {
        _backImage = null;
      } else {
        _frontImage = null;
      }
    });
  }

  void _saveCard() {
    final frontJson = jsonEncode(_frontController.document.toDelta().toJson());
    final backJson = jsonEncode(_backController.document.toDelta().toJson());

    widget.onSave(
      frontJson,
      backJson,
      _frontImage,
      _backImage,
    );

    // Clear the editors
    _frontController.clear();
    _backController.clear();
    setState(() {
      _frontImage = null;
      _backImage = null;
      _isShowingBack = false;
    });
  }
}
