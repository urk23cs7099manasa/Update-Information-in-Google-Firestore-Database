import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  if (firebaseOptions == null) {
    runApp(const UpdateStudentApp(firebaseConfigured: false));
    return;
  }

  try {
    await Firebase.initializeApp(options: firebaseOptions);
    runApp(const UpdateStudentApp(firebaseConfigured: true));
  } on FirebaseException catch (error) {
    runApp(
      FirebaseInitializationErrorApp(message: error.message ?? error.code),
    );
  }
}

class UpdateStudentApp extends StatelessWidget {
  final bool firebaseConfigured;

  const UpdateStudentApp({super.key, required this.firebaseConfigured});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Update Student Information',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: firebaseConfigured
          ? const UpdateStudentPage()
          : const FirebaseConfigurationPage(),
    );
  }
}

class FirebaseConfigurationPage extends StatelessWidget {
  const FirebaseConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InformationPage(
      icon: Icons.cloud_off,
      message: 'Firebase is not configured for this platform.',
      details:
          'Create firebase_config.json from the example file, add your '
          'Firebase project settings, then run this app with '
          '--dart-define-from-file=firebase_config.json.',
    );
  }
}

class FirebaseInitializationErrorApp extends StatelessWidget {
  final String message;

  const FirebaseInitializationErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Update Student Information',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: _InformationPage(
        icon: Icons.error_outline,
        message: 'Firebase could not be initialized.',
        details: message,
      ),
    );
  }
}

class _InformationPage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String details;

  const _InformationPage({
    required this.icon,
    required this.message,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Student Information'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: Colors.teal),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(details, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateStudentPage extends StatefulWidget {
  final FirebaseFirestore? firestore;

  const UpdateStudentPage({super.key, this.firestore});

  @override
  State<UpdateStudentPage> createState() => _UpdateStudentPageState();
}

class _UpdateStudentPageState extends State<UpdateStudentPage> {
  final _registrationController = TextEditingController();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _marksController = TextEditingController();

  late final CollectionReference<Map<String, dynamic>> _students =
      (widget.firestore ?? FirebaseFirestore.instance).collection('students');

  bool _isLoading = false;
  String? _loadedRegistrationNumber;

  bool get _recordFound => _loadedRegistrationNumber != null;

  Future<void> _loadStudent() async {
    final registrationNumber = _registrationController.text
        .trim()
        .toUpperCase();
    if (registrationNumber.isEmpty) {
      _showMessage('Please enter a registration number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadedRegistrationNumber = null;
      _clearStudentFields();
    });

    try {
      final document = await _students.doc(registrationNumber).get();
      if (!mounted) return;

      final data = document.data();
      if (data == null) {
        _showMessage('Student record not found.');
        return;
      }

      setState(() {
        _loadedRegistrationNumber = registrationNumber;
        _nameController.text = data['name']?.toString() ?? '';
        _departmentController.text = data['department']?.toString() ?? '';
        _marksController.text = data['marks']?.toString() ?? '';
      });
      _showMessage('Student record loaded successfully.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(
        'Unable to retrieve record: ${error.message ?? error.code}. '
        'Check Firestore access.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStudent() async {
    if (!_recordFound) {
      _showMessage('Search for an existing student first.');
      return;
    }

    final registrationNumber = _registrationController.text
        .trim()
        .toUpperCase();
    if (registrationNumber != _loadedRegistrationNumber) {
      _showMessage(
        'Load the student record for this registration number first.',
      );
      return;
    }

    final name = _nameController.text.trim();
    final department = _departmentController.text.trim();
    final marksText = _marksController.text.trim();
    final marks = int.tryParse(marksText);

    if (name.isEmpty ||
        department.isEmpty ||
        marks == null ||
        marks < 0 ||
        marks > 100) {
      _showMessage(
        'Enter valid details. Marks must be a whole number from 0 to 100.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _students.doc(registrationNumber).update({
        'name': name,
        'department': department,
        'marks': marks,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showMessage('Student information updated successfully.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(
        'Update failed: ${error.message ?? error.code}. '
        'Check the record and Firestore permissions.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearStudentFields() {
    _nameController.clear();
    _departmentController.clear();
    _marksController.clear();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Student Information'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.edit_note, size: 65, color: Colors.teal),
                const SizedBox(height: 12),
                const Text(
                  'Update Student Record',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _registrationController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    hintText: 'Enter registration number',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _isLoading ? null : _loadStudent(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loadStudent,
                  icon: const Icon(Icons.search),
                  label: const Text('Load Student Record'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  enabled: _recordFound && !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _departmentController,
                  enabled: _recordFound && !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _marksController,
                  enabled: _recordFound && !_isLoading,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks (0-100)',
                    prefixIcon: Icon(Icons.grade),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_recordFound
                      ? null
                      : _updateStudent,
                  icon: const Icon(Icons.save),
                  label: const Text('Update Student Information'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
