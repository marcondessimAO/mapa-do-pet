import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/map/presentation/widgets/confirm_register_sheet.dart';

Future<bool?> openSheet(WidgetTester tester) async {
  bool? result;
  var answered = false;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              result = await showModalBottomSheet<bool>(
                context: context,
                builder: (_) => const ConfirmRegisterSheet(),
              );
              answered = true;
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  expect(find.text('Cadastrar animal aqui?'), findsOneWidget);
  addTearDown(() => answered);
  return result;
}

void main() {
  testWidgets('asks the question and explains the point is approximate',
      (tester) async {
    await openSheet(tester);

    expect(find.text('Cadastrar animal aqui?'), findsOneWidget);
    expect(find.textContaining('aproximada'), findsOneWidget);
  });

  testWidgets('confirming returns true', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async => result = await showModalBottomSheet<bool>(
              context: context,
              builder: (_) => const ConfirmRegisterSheet(),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('cancelling returns false', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async => result = await showModalBottomSheet<bool>(
              context: context,
              builder: (_) => const ConfirmRegisterSheet(),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
