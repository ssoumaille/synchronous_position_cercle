import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:synchronous_position_cercle/main.dart' as Appmain;
import 'package:synchronous_position_cercle/main.dart';

void main() {
  test('test correction position', () {
    expect(limitingMovementToWindowOnly(Offset(0, 0)), Offset(20, 20));
    expect(limitingMovementToWindowOnly(Offset(600, 0)), Offset(460, 20));
    expect(limitingMovementToWindowOnly(Offset(0, 600)), Offset(20, 460));
    expect(limitingMovementToWindowOnly(Offset(600, 600)), Offset(460, 460));
  });

  testWidgets('test riverpod position', (tester) async {
    firestoreInstance = FakeFirebaseFirestore();
    await initApp();
    await tester.pumpWidget(ProviderScope(child: MyApp()));
    print(find.byType(MyDraggableCircle));
    final draggableCircle = find.byType(MyDraggableCircle);
    expect(draggableCircle, findsOneWidget);
    await tester.drag(draggableCircle, const Offset(500.0, 500.0));
    await tester.pump();
    expect(tester.getTopLeft(draggableCircle), Offset(460.0, 460.0));
  });

  testWidgets('test riverpod list gamers', (tester) async {
    firestoreInstance = FakeFirebaseFirestore();
    await initApp();
    firestoreInstance.collection(Collection.position.name)
        .doc("c1").set({"x" : 120, "y" : 120, "color": color});
    firestoreInstance.collection(Collection.position.name)
        .doc("c2").set({"x" : 120, "y" : 120, "color": color});
    firestoreInstance.collection(Collection.position.name)
        .doc("c3").set({"x" : 120, "y" : 120, "color": color});
    firestoreInstance.collection(Collection.position.name)
        .doc("c4").set({"x" : 120, "y" : 120, "color": color});
    firestoreInstance.collection(Collection.position.name)
        .doc("c5").set({"x" : 120, "y" : 120, "color": color});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    sleep(const Duration(seconds: 2));
    await tester.pump();
    int gamersCount = tester.elementList(find.byType(CirclesFromFirestore)).length;
    expect(gamersCount, 5);

    final CircleFromButton = find.byType(ElevatedButton);
    await tester.tap(CircleFromButton);
    await tester.pump();
    gamersCount = tester.elementList(find.byType(CirclesFromFirestore)).length;
    expect(gamersCount, 6);
  });
}
