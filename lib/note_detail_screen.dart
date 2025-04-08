import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';





class NoteDetailScreen extends StatefulWidget {
  final Map<String, String> note;
  final VoidCallback onEdit;

  NoteDetailScreen({required this.note, required this.onEdit});

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}



class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late String content;
  late List<int> checkboxLineIndices;

  @override
  void initState() {
    super.initState();
    content = widget.note['content'] ?? '';
    _updateCheckboxLineIndices();
  }

  void _updateCheckboxLineIndices() {
    final lines = content.split('\n');
    checkboxLineIndices = [];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('- [ ]') || line.trimLeft().startsWith('- [x]'))
        checkboxLineIndices.add(i);
    }
  }

  void _toggleCheckbox(int checkboxIndex) {
    final lines = content.split('\n');
    final lineIndex = checkboxLineIndices[checkboxIndex];
    final line = lines[lineIndex];

    if (line.contains('- [ ]'))
      lines[lineIndex] = line.replaceFirst('- [ ]', '- [x]');
    else if (line.contains('- [x]'))
      lines[lineIndex] = line.replaceFirst('- [x]', '- [ ]');

    setState(() {
      content = lines.join('\n');
      widget.note['content'] = content;
      _updateCheckboxLineIndices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final MarkdownStyleSheet baseStyle = MarkdownStyleSheet.fromTheme(Theme.of(context));
    final MarkdownStyleSheet customStyle = baseStyle.copyWith(
      h1: baseStyle.h1?.copyWith(color: const Color.fromARGB(255, 0, 255, 0)),
      h2: baseStyle.h2?.copyWith(color: const Color.fromARGB(255, 0, 170, 0)),
      h3: baseStyle.h3?.copyWith(color: const Color.fromARGB(255, 0, 150, 0)),
      h4: baseStyle.h4?.copyWith(color: const Color.fromARGB(255, 0, 110, 0)),
      h5: baseStyle.h5?.copyWith(color: const Color.fromARGB(255, 0, 100, 0)),
      h6: baseStyle.h6?.copyWith(color: const Color.fromARGB(255, 0, 90, 0)),
      a: TextStyle(color: const Color.fromARGB(255, 0, 97, 0)),
      p: const TextStyle(fontSize: 16),
      blockquoteDecoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 45, 0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color.fromARGB(255, 0, 100, 0)),
      ),
    );
    int checkboxCounter = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note['title'] ?? ''),
        actions: [
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content)).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Note copied to clipboard')),
                );
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: widget.onEdit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(6.0),
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: content,
            styleSheet: customStyle,
            imageBuilder: (uri, title, alt) {
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.all(10),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width,
                            maxHeight: MediaQuery.of(context).size.height,
                          ),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.file(
                              File(uri.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Image.file(File(uri.path)),
              );
            },
            onTapLink: (text, href, title) {
              if (href != null) launchUrl(Uri.parse(href));
            },
            checkboxBuilder: (bool value) {
              final currentIndex = checkboxCounter;
              checkboxCounter++;
              return Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 24.0,
                    width: 24.0,
                    child: Checkbox(
                      value: value,
                      activeColor: const Color.fromARGB(255, 0, 105, 0),
                      checkColor: const Color.fromARGB(255, 0, 0, 0),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          _toggleCheckbox(currentIndex);
                        }
                      },
                    ),
                  )
                )
              );
            },
          ),
        ),
      ),
    );
  }
}