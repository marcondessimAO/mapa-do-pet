import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapa_do_pet/core/widgets/location_picker.dart';
import 'package:provider/provider.dart';

import '../../support/blank_tile_provider.dart';

const _start = LatLng(-15.7939, -47.8828);

Widget host(ValueChanged<LatLng> onChanged) {
  return Provider<TileProvider>.value(
    value: BlankTileProvider(),
    child: MaterialApp(
      home: Scaffold(
        body: LocationPicker(location: _start, onChanged: onChanged),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the hint and a pin at the current point', (tester) async {
    await tester.pumpWidget(host((_) {}));
    await tester.pumpAndSettle();

    expect(find.text('Toque no mapa para ajustar o ponto.'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });

  testWidgets('credits OpenStreetMap', (tester) async {
    await tester.pumpWidget(host((_) {}));
    await tester.pumpAndSettle();

    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('tapping the map reports the new point (RF-07)', (tester) async {
    LatLng? picked;
    await tester.pumpWidget(host((point) => picked = point));
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(FlutterMap));
    await tester.tapAt(center + const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.longitude, greaterThan(_start.longitude)); // para o leste
    expect(picked!.latitude, closeTo(_start.latitude, 0.001));
  });
}
