import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(NoteApp());
}

class NoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note App',
      theme: ThemeData.dark(),
      home: NoteListScreen(),
    );
  }
}

class NoteListScreen extends StatefulWidget {
  @override
  _NoteListScreenState createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getString('notes');

    if (savedNotes != null) {
      setState(() {
        notes = (json.decode(savedNotes) as List)
            .map((note) => Map<String, dynamic>.from(note))
            .toList();
      });
    }
  }

  void _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('notes', json.encode(notes));
  }

  void _addNote() async {
    final newNote = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(),
      ),
    );

    if (newNote != null && newNote['title']!.isNotEmpty) {
      setState(() {
        notes.add(newNote);
        _saveNotes();
      });
    }
  }

  void _editNote(int index) async {
    final updatedNote = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          note: notes[index],
        ),
      ),
    );

    if (updatedNote != null && updatedNote['title']!.isNotEmpty) {
      setState(() {
        notes[index] = updatedNote;
        _saveNotes();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(notes[index]['title']!),
            subtitle: _getNotePreview(notes[index]['content']),
            onTap: () => _editNote(index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _getNotePreview(dynamic content) {
    if (content is String) {
      // For backward compatibility with old text-only notes
      return Text(content.length > 50 ? '${content.substring(0, 50)}...' : content);
    } else if (content is List) {
      // For rich text notes with images
      final delta = quill.Delta.fromJson(content);
      final plainText = delta.map((op) => op.isInsert ? op.value : '').join();
      return Text(plainText.length > 50 ? '${plainText.substring(0, 50)}...' : plainText);
    }
    return Text('');
  }
}

class NoteEditScreen extends StatefulWidget {
  final Map<String, dynamic>? note;

  NoteEditScreen({this.note});

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?['title'] ?? '');
    
    if (widget.note?['content'] != null) {
      if (widget.note!['content'] is String) {
        // Convert old text-only notes to rich text format
        _quillController = quill.QuillController(
          document: quill.Document.fromDelta(
            quill.Delta()..insert(widget.note!['content']),
          ),
          selection: TextSelection.collapsed(offset: 0),
        );
      } else {
        // Handle rich text notes with images
        _quillController = quill.QuillController(
          document: quill.Document.fromJson(widget.note!['content']),
          selection: TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _quillController = quill.QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _insertImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final imageBase64 = base64Encode(bytes);
      
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      
      _quillController.document.insert(
        index,
        {'image': imageBase64},
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _insertImage,
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, {
                'title': _titleController.text,
                'content': _quillController.document.toDelta().toJson(),
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
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: quill.QuillEditor(
                  controller: _quillController,
                  scrollController: ScrollController(),
                  scrollable: true,
                  focusNode: FocusNode(),
                  autoFocus: false,
                  readOnly: false,
                  expands: true,
                  padding: EdgeInsets.all(16),
                ),
              ),
            ),
            quill.QuillToolbar.basic(
              controller: _quillController,
              showImageButton: false, // We're using our own image button
            ),
          ],
        ),
      ),
    );
  }
}