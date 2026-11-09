import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/theme/app_theme.dart';
import 'package:mapa_do_pet/core/utils/clock.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_record.dart';
import 'package:mapa_do_pet/features/care/domain/entities/care_summary.dart';
import 'package:mapa_do_pet/features/care/domain/enums/health_record_kind.dart';
import 'package:mapa_do_pet/features/care/domain/usecases/add_care_record.dart';
import 'package:mapa_do_pet/features/care/presentation/widgets/care_section.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_care_repository.dart';

// Datas locais (os registros guardam UTC e a tela mostra o horário local).
DateTime local(int d, int m, [int h = 0, int min = 0]) =>
    DateTime(2025, m, d, h, min).toUtc();

FeedingRecord feeding(String id, DateTime at, {bool hasTime = true}) =>
    FeedingRecord(id: id, petId: 'pet-1', occurredAt: at, hasTime: hasTime);

Widget app(
  CareSummary summary, {
  FakeCareRepository? repository,
  VoidCallback? onChanged,
}) {
  return Provider<AddCareRecord>.value(
    value: AddCareRecord(repository ?? FakeCareRepository(), systemNow),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CareSection(
            petId: 'pet-1',
            summary: summary,
            onChanged: onChanged ?? () {},
          ),
        ),
      ),
    ),
  );
}

Future<void> pump(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(const Size(800, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

Finder inFeedingList(String text) => find.descendant(
      of: find.byKey(const ValueKey('list-feeding')),
      matching: find.text(text),
    );

void main() {
  testWidgets('with no records shows the empty highlights and lists (RF-13)',
      (tester) async {
    await pump(tester, app(CareSummary.from(const [])));

    expect(find.text('Cuidados'), findsOneWidget);
    expect(find.text('Última alimentação'), findsOneWidget);
    expect(find.text('Último banho'), findsOneWidget);
    expect(find.text('Ainda sem registro'), findsNWidgets(2));
    expect(find.text('Nenhum registro'), findsNWidgets(4));
  });

  testWidgets('highlights the most recent feeding even if logged out of order',
      (tester) async {
    final summary = CareSummary.from([
      feeding('a', local(10, 3, 8)),
      feeding('b', local(12, 3, 8, 30)),
      feeding('c', local(11, 3, 19)),
    ]);

    await pump(tester, app(summary));

    final highlight = find.byKey(const ValueKey('last-feeding'));
    expect(
      find.descendant(
        of: highlight,
        matching: find.text('12/03/2025 às 08:30'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('highlights the last bath, showing only the date if no time',
      (tester) async {
    final summary = CareSummary.from([
      BathRecord(id: 'b', petId: 'pet-1', occurredAt: local(2, 3)),
    ]);

    await pump(tester, app(summary));

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('last-bath')),
        matching: find.text('02/03/2025'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('lists the records of each type from newest to oldest (RF-14)',
      (tester) async {
    final summary = CareSummary.from([
      feeding('old', local(1, 3, 8)),
      feeding('new', local(9, 3, 8)),
      feeding('mid', local(5, 3, 8)),
    ]);

    await pump(tester, app(summary));

    final newest = tester.getTopLeft(inFeedingList('09/03/2025 às 08:00')).dy;
    final middle = tester.getTopLeft(inFeedingList('05/03/2025 às 08:00')).dy;
    final oldest = tester.getTopLeft(inFeedingList('01/03/2025 às 08:00')).dy;
    expect(newest, lessThan(middle));
    expect(middle, lessThan(oldest));
  });

  testWidgets('shows the details of medication and health records',
      (tester) async {
    final summary = CareSummary.from([
      MedicationRecord(
        id: 'm',
        petId: 'pet-1',
        occurredAt: local(8, 3, 9),
        hasTime: true,
        medicationName: 'Vermífugo',
        responsibleName: 'Ana',
        notes: 'meio comprimido',
      ),
      HealthRecord(
        id: 'h',
        petId: 'pet-1',
        occurredAt: local(7, 3, 10),
        hasTime: true,
        kind: HealthRecordKind.vaccine,
        description: 'V10, primeira dose',
      ),
    ]);

    await pump(tester, app(summary));

    expect(find.text('Vermífugo'), findsOneWidget);
    expect(find.textContaining('Ana'), findsOneWidget);
    expect(find.textContaining('meio comprimido'), findsOneWidget);
    expect(find.textContaining('Vacina'), findsOneWidget);
    expect(find.textContaining('V10, primeira dose'), findsOneWidget);
  });

  testWidgets('"Adicionar registro" offers the four types', (tester) async {
    await pump(tester, app(CareSummary.from(const [])));

    await tester.tap(find.text('Adicionar registro'));
    await tester.pumpAndSettle();

    expect(find.text('Que tipo de registro?'), findsOneWidget);
    for (final label in ['Alimentação', 'Banho', 'Medicamento', 'Saúde']) {
      expect(find.widgetWithText(ListTile, label), findsOneWidget);
    }
  });

  testWidgets('adding a record saves it and tells the profile to refresh',
      (tester) async {
    final repository = FakeCareRepository();
    var changed = 0;
    await pump(
      tester,
      app(CareSummary.from(const []),
          repository: repository, onChanged: () => changed++),
    );

    await tester.tap(find.text('Adicionar registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Banho'));
    await tester.pumpAndSettle();
    expect(find.text('Novo registro: Banho'), findsOneWidget);
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();

    expect(repository.store.single, isA<BathRecord>());
    expect(changed, 1);
    expect(find.text('Registro salvo!'), findsOneWidget);
  });
}
