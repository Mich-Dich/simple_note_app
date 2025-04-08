import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
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
  List<Map<String, String>> notes = [];

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
            .map((note) => Map<String, String>.from(note))
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

  // Tapping on a note navigates to the NoteDetailScreen
  void _viewNote(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          note: notes[index],
          onEdit: () async {
            final updatedNote = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditScreen(note: notes[index]),
              ),
            );
            if (updatedNote != null && updatedNote['title']!.isNotEmpty) {
              setState(() {
                notes[index] = updatedNote;
                _saveNotes();
              });
            }
          },
        ),
      ),
    );
  }

  void _deleteNote(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Note'),
          content: Text(
              'Are you sure you want to delete the note: "${notes[index]['title']}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  notes.removeAt(index);
                  _saveNotes();
                });
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: ReorderableListView(
        onReorder: (int oldIndex, int newIndex) {
          if (newIndex > oldIndex) {
            newIndex--;
          }
          setState(() {
            final note = notes.removeAt(oldIndex);
            notes.insert(newIndex, note);
            _saveNotes();
          });
        },
        children: List.generate(notes.length, (index) {
          final note = notes[index];
          return ListTile(
            key: Key('${note['title']}_$index'),
            title: Text(note['title']!),
            onTap: () => _viewNote(index),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteNote(index),
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: Icon(Icons.add),
      ),
    );
  }
}

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
      final markdownImage = "\n![]($imagePath)\n";
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
    final todoTemplate = "\n- [ ] New Task\n";
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










class NoteDetailScreen extends StatefulWidget {
  final Map<String, String> note;
  final VoidCallback onEdit;

  NoteDetailScreen({required this.note, required this.onEdit});

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late String content;
  late List<int> checkboxLineIndices; // Maps rendered checkboxes to line numbers

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
      if (line.trimLeft().startsWith('- [ ]') || line.trimLeft().startsWith('- [x]')) {
        checkboxLineIndices.add(i);
      }
    }
  }

  void _toggleCheckbox(int checkboxIndex) {
    final lines = content.split('\n');
    final lineIndex = checkboxLineIndices[checkboxIndex];
    final line = lines[lineIndex];

    if (line.contains('- [ ]')) {
      lines[lineIndex] = line.replaceFirst('- [ ]', '- [x]');
    } else if (line.contains('- [x]')) {
      lines[lineIndex] = line.replaceFirst('- [x]', '- [ ]');
    }

    setState(() {
      content = lines.join('\n');
      widget.note['content'] = content;
      _updateCheckboxLineIndices(); // Refresh map
    });
  }

  @override
  Widget build(BuildContext context) {
    final MarkdownStyleSheet customStyle = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(fontSize: 16),
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: content,
            styleSheet: customStyle,
            imageBuilder: (uri, title, alt) {
              return Image.file(File(uri.path));
            },
            onTapLink: (text, href, title) {
              if (href != null) launchUrl(Uri.parse(href));
            },
            checkboxBuilder: (bool value) {
              final currentIndex = checkboxCounter;
              checkboxCounter++;

              return Checkbox(
                value: value,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (bool? newValue) {
                  if (newValue != null) {
                    _toggleCheckbox(currentIndex);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

