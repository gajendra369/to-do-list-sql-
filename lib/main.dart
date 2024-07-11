// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter To-Do App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigoAccent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.indigoAccent,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.indigoAccent),
          ),
          labelStyle: TextStyle(color: Colors.indigoAccent),
        ),
      ),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _tasks;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasks = _dbHelper.queryAllTasks();
    });
  }

  void _addTask() async {
    if (_titleController.text.isNotEmpty) {
      await _dbHelper.insertTask({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _titleController.clear();
      _descriptionController.clear();
      _refreshTasks();
    }
  }

  void _showEditTaskDialog(Map<String, dynamic> task) {
    final TextEditingController editTitleController =
        TextEditingController(text: task['title']);
    final TextEditingController editDescriptionController =
        TextEditingController(text: task['description']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editTitleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: editDescriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateTask(task['id'], editTitleController.text,
                    editDescriptionController.text);
                Navigator.pop(context);
              },
              child: const Text('Save',style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  void _updateTask(int id, String newTitle, String newDescription) async {
    if (newTitle.isNotEmpty) {
      await _dbHelper.updateTask({
        'id': id,
        'title': newTitle,
        'description': newDescription,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _refreshTasks();
    }
  }

  void _deleteTask(int id) async {
    await _dbHelper.deleteTask(id);
    _refreshTasks();
  }

  void _showTaskDetails(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task['title']),
          content: Text(task['description']),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    final String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
    final String formattedTime = DateFormat('hh:mm a').format(dateTime);
    return '$formattedDate – $formattedTime';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _tasks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No tasks found'));
                } else {
                  final tasks = snapshot.data!;
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(task['title']),
                            subtitle: Text(_formatTimestamp(task['timestamp'])),
                            onTap: () => _showTaskDetails(task),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.indigoAccent),
                                  onPressed: () => _showEditTaskDialog(task),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () => _deleteTask(task['id']),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Save Task'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
