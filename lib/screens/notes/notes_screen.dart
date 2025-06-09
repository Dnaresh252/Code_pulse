import 'package:flutter/material.dart';

class Note {
  final String topic;
  final String content;

  Note({
    required this.topic,
    required this.content,
  });
}

class NotesPage extends StatefulWidget {
  final List<Note> notes;
  final void Function(Note) onAdd;
  final void Function(int, Note) onUpdate;
  final void Function(int) onDelete;

  const NotesPage({
    super.key,
    required this.notes,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Notes')),
      body: widget.notes.isEmpty
          ? const Center(child: Text('No notes yet. Add notes while studying!'))
          : ListView.builder(
        itemCount: widget.notes.length,
        itemBuilder: (context, index) {
          final note = widget.notes[index];
          return ListTile(
            title: Text(note.topic),
            subtitle: Text(
              note.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => widget.onDelete(index),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteEditPage(
                    note: note,
                    onSave: (updatedNote) =>
                        widget.onUpdate(index, updatedNote),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteEditPage(
                onSave: widget.onAdd,
              ),
            ),
          );
        },
      ),
    );
  }
}

class NoteEditPage extends StatefulWidget {
  final Note? note;
  final void Function(Note) onSave;

  const NoteEditPage({super.key, this.note, required this.onSave});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  late TextEditingController topicController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    topicController = TextEditingController(text: widget.note?.topic ?? '');
    contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  void _save() {
    final topic = topicController.text.trim();
    final content = contentController.text.trim();
    if (topic.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topic and content cannot be empty')),
      );
      return;
    }

    widget.onSave(Note(topic: topic, content: content));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    topicController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Note' : 'Add Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: topicController,
              decoration: const InputDecoration(labelText: 'Topic'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? 'Update Note' : 'Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
