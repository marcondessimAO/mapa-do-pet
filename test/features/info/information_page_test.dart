import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/features/info/presentation/pages/information_page.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: InformationPage()));
  }

  testWidgets('has the title "Como funciona o app?" (RF-15)', (tester) async {
    await pumpPage(tester);

    expect(find.text('Como funciona o app?'), findsOneWidget);
  });

  testWidgets('explains how to register and follow the animals',
      (tester) async {
    await pumpPage(tester);

    expect(find.textContaining('Basta tocar no mapa'), findsOneWidget);
    expect(
        find.textContaining('Consulte o perfil dos animais'), findsOneWidget);
    expect(
      find.textContaining('em situação de rua e estão disponíveis para adoção'),
      findsOneWidget,
    );
  });

  testWidgets('ends with "Adote um pet, mude uma vida!"', (tester) async {
    await pumpPage(tester);

    expect(find.text('Adote um pet, mude uma vida!'), findsOneWidget);
  });

  testWidgets('is static: no inputs and no providers needed', (tester) async {
    // Sem nenhum Provider acima: a tela não acessa banco nem ViewModel.
    await pumpPage(tester);

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ButtonStyleButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
