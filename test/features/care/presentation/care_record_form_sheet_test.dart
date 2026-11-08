import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';
import 'package:mapa_do_pet/core/utils/clock.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/enums/care_type.dart';
import 'package:mapa_do_pet/features/care/domain/enums/health_record_kind.dart';
import 'package:mapa_do_pet/features/care/domain/usecases/add_care_record.dart';
import 'package:mapa_do_pet/features/care/presentation/widgets/care_record_form_sheet.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_care_repository.dart';

Widget app(FakeCareRepository repository, CareType type) {
  return Provider<AddCareRecord>.value(
    value: AddCareRecord(repository, systemNow),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<CareRecord>(
                context: context,
                isScrollControlled: true,
                builder: (_) => CareRecordFormSheet(petId: 'pet-1', type: type),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> openSheet(
    WidgetTester tester, FakeCareRepository repository, CareType type) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app(repository, type));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a feeding asks for date, optional time, responsible and notes',
      (tester) async {
    await openSheet(tester, FakeCareRepository(), CareType.feeding);

    expect(find.text('Novo registro: Alimentação'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Informar horário'), findsOneWidget);
    expect(find.text('Horário'), findsOneWidget);
    expect(find.text('Responsável (opcional)'), findsOneWidget);
    expect(find.text('Observações (opcional)'), findsOneWidget);
    expect(find.text('Nome do medicamento *'), findsNothing);
  });

  testWidgets('saves a feeding with the defaults and closes the sheet',
      (tester) async {
    final repository = FakeCareRepository();
    await openSheet(tester, repository, CareType.feeding);

    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();

    final record = repository.store.single as FeedingRecord;
    expect(record.petId, 'pet-1');
    // A hora sugerida é a atual (o formulário usa o relógio real).
    final age = DateTime.now().toUtc().difference(record.occurredAt);
    expect(age.inMinutes, inInclusiveRange(0, 2));
    expect(find.text('Novo registro: Alimentação'), findsNothing);
  });

  testWidgets('turning the time off hides it and saves only the date',
      (tester) async {
    final repository = FakeCareRepository();
    await openSheet(tester, repository, CareType.bath);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('Horário'), findsNothing);
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();

    expect(repository.store.single.hasTime, isFalse);
  });

  testWidgets('a medication requires the medicine name (RN-06)',
      (tester) async {
    final repository = FakeCareRepository();
    await openSheet(tester, repository, CareType.medication);
    expect(find.text('Nome do medicamento *'), findsOneWidget);

    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome do medicamento.'), findsOneWidget);
    expect(repository.store, isEmpty);
    expect(find.text('Novo registro: Medicamento'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do medicamento *'),
      'Vermífugo',
    );
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();

    expect((repository.store.single as MedicationRecord).medicationName,
        'Vermífugo');
  });

  testWidgets('a health record asks for the kind and a description',
      (tester) async {
    final repository = FakeCareRepository();
    await openSheet(tester, repository, CareType.health);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Descrição *'), findsOneWidget);

    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();
    expect(
        find.text('Descreva o atendimento ou procedimento.'), findsOneWidget);
    expect(repository.store, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição *'),
      'Consulta de rotina',
    );
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();

    final record = repository.store.single as HealthRecord;
    expect(record.description, 'Consulta de rotina');
    expect(record.kind, HealthRecordKind.general);
  });
}
