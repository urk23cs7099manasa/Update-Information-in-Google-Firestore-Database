import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_1/main.dart';

Future<void> dismissSnackBar(WidgetTester tester) async {
  final context = tester.element(find.byType(UpdateStudentPage));
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  await tester.pumpAndSettle();
}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  testWidgets('shows setup guidance when Firebase is not configured', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UpdateStudentApp(firebaseConfigured: false));

    expect(
      find.text('Firebase is not configured for this platform.'),
      findsOneWidget,
    );
  });

  testWidgets('loads an existing student with a normalized registration', (
    WidgetTester tester,
  ) async {
    await firestore.collection('students').doc('STU-001').set({
      'name': 'Alex Student',
      'registrationNumber': 'STU-001',
      'department': 'Computer Science',
      'marks': 92,
    });

    await tester.pumpWidget(
      MaterialApp(home: UpdateStudentPage(firestore: firestore)),
    );
    await tester.enterText(find.byType(TextField).at(0), ' stu-001 ');
    await tester.tap(find.text('Load Student Record'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(
      tester.widget<TextField>(fields.at(1)).controller?.text,
      'Alex Student',
    );
    expect(
      tester.widget<TextField>(fields.at(2)).controller?.text,
      'Computer Science',
    );
    expect(tester.widget<TextField>(fields.at(3)).controller?.text, '92');
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Update Student Information'),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.text('Student record loaded successfully.'), findsOneWidget);
  });

  testWidgets('updates an existing student and preserves its other data', (
    WidgetTester tester,
  ) async {
    await firestore.collection('students').doc('STU-001').set({
      'name': 'Alex Student',
      'registrationNumber': 'STU-001',
      'department': 'Computer Science',
      'marks': 92,
      'createdAt': 'original-created-at',
    });

    await tester.pumpWidget(
      MaterialApp(home: UpdateStudentPage(firestore: firestore)),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'stu-001');
    await tester.tap(find.text('Load Student Record'));
    await tester.pumpAndSettle();
    await dismissSnackBar(tester);

    await tester.enterText(fields.at(1), 'Alex Updated');
    await tester.enterText(fields.at(2), 'Software Engineering');
    await tester.enterText(fields.at(3), '88');
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Update Student Information'),
    );
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Update Student Information'),
    );
    await tester.pumpAndSettle();

    final updated =
        (await firestore.collection('students').doc('STU-001').get()).data()!;
    expect(updated['name'], 'Alex Updated');
    expect(updated['registrationNumber'], 'STU-001');
    expect(updated['department'], 'Software Engineering');
    expect(updated['marks'], 88);
    expect(updated['createdAt'], 'original-created-at');
    expect(updated['updatedAt'], isNotNull);
    expect(
      find.text('Student information updated successfully.'),
      findsOneWidget,
    );
  });

  testWidgets('does not enable editing when a record is not found', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: UpdateStudentPage(firestore: firestore)),
    );
    await tester.enterText(find.byType(TextField).at(0), 'missing-001');
    await tester.tap(find.text('Load Student Record'));
    await tester.pumpAndSettle();

    expect(find.text('Student record not found.'), findsOneWidget);
    for (final field
        in tester.widgetList<TextField>(find.byType(TextField)).skip(1)) {
      expect(field.enabled, isFalse);
    }
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Update Student Information'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('rejects marks outside the whole-number range', (
    WidgetTester tester,
  ) async {
    await firestore.collection('students').doc('STU-001').set({
      'name': 'Alex Student',
      'registrationNumber': 'STU-001',
      'department': 'Computer Science',
      'marks': 92,
    });

    await tester.pumpWidget(
      MaterialApp(home: UpdateStudentPage(firestore: firestore)),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'STU-001');
    await tester.tap(find.text('Load Student Record'));
    await tester.pumpAndSettle();
    await dismissSnackBar(tester);
    await tester.enterText(fields.at(3), '101');
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Update Student Information'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Enter valid details. Marks must be a whole number from 0 to 100.',
      ),
      findsOneWidget,
    );
    final record = await firestore.collection('students').doc('STU-001').get();
    expect(record.data()?['marks'], 92);
  });

  testWidgets('requires loading the record for a changed registration number', (
    WidgetTester tester,
  ) async {
    await firestore.collection('students').doc('STU-001').set({
      'name': 'Alex Student',
      'registrationNumber': 'STU-001',
      'department': 'Computer Science',
      'marks': 92,
    });

    await tester.pumpWidget(
      MaterialApp(home: UpdateStudentPage(firestore: firestore)),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'STU-001');
    await tester.tap(find.text('Load Student Record'));
    await tester.pumpAndSettle();
    await dismissSnackBar(tester);
    await tester.enterText(fields.at(0), 'OTHER-001');
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Update Student Information'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Load the student record for this registration number first.'),
      findsOneWidget,
    );
    expect(
      (await firestore.collection('students').doc('OTHER-001').get()).exists,
      isFalse,
    );
  });
}
