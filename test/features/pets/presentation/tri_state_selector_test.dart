import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/pets/domain/enums/tri_state.dart';
import 'package:mapa_do_pet/features/pets/presentation/widgets/tri_state_selector.dart';

Widget host(TriState value, ValueChanged<TriState> onChanged) => MaterialApp(
      home: Scaffold(
        body: TriStateSelector(
          label: 'Dócil?',
          value: value,
          onChanged: onChanged,
        ),
      ),
    );

void main() {
  testWidgets('shows the label and the three options (RF-11)', (tester) async {
    await tester.pumpWidget(host(TriState.unknown, (_) {}));

    expect(find.text('Dócil?'), findsOneWidget);
    expect(find.text('Sim'), findsOneWidget);
    expect(find.text('Não'), findsOneWidget);
    expect(find.text('Não sei'), findsOneWidget);
  });

  testWidgets('marks the current value as selected', (tester) async {
    await tester.pumpWidget(host(TriState.no, (_) {}));

    final button = tester.widget<SegmentedButton<TriState>>(
        find.byType(SegmentedButton<TriState>));

    expect(button.selected, {TriState.no});
  });

  testWidgets('reports the tapped option', (tester) async {
    TriState? received;
    await tester.pumpWidget(host(TriState.unknown, (v) => received = v));

    await tester.tap(find.text('Sim'));
    await tester.pump();

    expect(received, TriState.yes);
  });

  testWidgets('never allows an empty selection', (tester) async {
    TriState? received;
    await tester.pumpWidget(host(TriState.yes, (v) => received = v));

    await tester.tap(find.text('Sim')); // toque no valor já selecionado
    await tester.pump();

    expect(received == null || received == TriState.yes, isTrue);
  });
}
