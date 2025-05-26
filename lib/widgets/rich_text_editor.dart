import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart'
    as quill_ext;

class RichTextEditor extends StatefulWidget {
  final String label;
  final quill.QuillController controller;

  const RichTextEditor({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2F2F31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF484848)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                quill.QuillSimpleToolbar(
                  controller: widget.controller,
                  config: quill.QuillSimpleToolbarConfig(
                    embedButtons: quill_ext.FlutterQuillEmbeds.toolbarButtons(),
                    showClipboardPaste: true,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: quill.QuillEditor(
                    controller: widget.controller,
                    scrollController: _scrollController,
                    focusNode: _focusNode,
                    config: const quill.QuillEditorConfig(
                      padding: EdgeInsets.all(8),
                      placeholder: 'Start writing...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
