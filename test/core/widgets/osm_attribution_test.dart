import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/widgets/osm_tile_layer.dart';

Widget host(OsmAttribution attribution) => MaterialApp(
      home: Scaffold(body: Stack(children: [attribution])),
    );

void main() {
  testWidgets('shows the OpenStreetMap credit', (tester) async {
    await tester.pumpWidget(host(OsmAttribution(launcher: (_) async => true)));

    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('tapping the credit opens the OSM copyright page',
      (tester) async {
    Uri? opened;
    await tester.pumpWidget(host(OsmAttribution(
      launcher: (uri) async {
        opened = uri;
        return true;
      },
    )));

    await tester.tap(find.text('© OpenStreetMap contributors'));
    await tester.pump();

    expect(opened, OsmAttribution.copyrightUri);
    expect(opened.toString(), 'https://www.openstreetmap.org/copyright');
  });

  testWidgets('a launcher failure does not break the screen', (tester) async {
    await tester.pumpWidget(host(OsmAttribution(launcher: (_) async => false)));

    await tester.tap(find.text('© OpenStreetMap contributors'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });
}
