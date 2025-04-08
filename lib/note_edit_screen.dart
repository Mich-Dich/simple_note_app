import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';




class NoteEditScreen extends StatefulWidget {
  final Map<String, String>? note;

  NoteEditScreen({this.note});

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.note?['title'] ?? '');
    _contentController =
        TextEditingController(text: widget.note?['content'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // pick an image and insert a markdown image link
  Future<void> _insertImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imagePath = pickedFile.path;
      final markdownImage = "![]($imagePath)";
      final text = _contentController.text;
      final selection = _contentController.selection;
      final newText = text.replaceRange(
        selection.start, selection.end, markdownImage);
      
      setState(() {
        _contentController.text = newText;
        _contentController.selection = TextSelection.collapsed(
            offset: selection.start + markdownImage.length);
      });
    }
  }

  void _insertTodoList() {
    final todoTemplate = "- [ ] ";
    final text = _contentController.text;
    final selection = _contentController.selection;
    final newText = text.replaceRange(
      selection.start, selection.end, todoTemplate);
    
    setState(() {
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
          offset: selection.start + todoTemplate.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: Icon(Icons.check_box),
            onPressed: _insertTodoList,
          ),
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _insertImage,
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, {
                'title': _titleController.text,
                'content': _contentController.text,
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Write your note here...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
