import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'note_detail_screen.dart';
import 'note_edit_screen.dart';





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

  void _viewNote(int index) {
    void handleEdit() async {
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
        // Replace current screen to refresh
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => NoteDetailScreen(
              note: notes[index],
              onEdit: handleEdit, // Reuse the same handler
            )
          ),
        );
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          note: notes[index],
          onEdit: handleEdit,
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
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        backgroundColor: const Color.fromARGB(255, 0, 100, 0),
        child: Icon(Icons.add),
      ),
    );
  }
}
