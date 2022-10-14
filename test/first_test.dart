import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronous_position_cercle/circle/circle.dart';
import 'package:synchronous_position_cercle/firebase_options.dart';

import 'package:synchronous_position_cercle/main.dart' as Appmain;
import 'package:synchronous_position_cercle/main.dart';

void main() {
  test('test correction position', () {
    expect(limitingMovementToWindowOnly(Offset(0, 0)), Offset(20, 20));
    expect(limitingMovementToWindowOnly(Offset(600, 0)), Offset(460, 20));
    expect(limitingMovementToWindowOnly(Offset(0, 600)), Offset(20, 460));
    expect(limitingMovementToWindowOnly(Offset(600, 600)), Offset(460, 460));
  });
  testWidgets('test riverpod', (tester) async {
    firestore = FakeFirebaseFirestore();
    await initApp();
    await tester.pumpWidget(ProviderScope(child: MyApp()));
    print(find.byType(MyDraggableCircle));
    final mydragebol = find.byType(MyDraggableCircle);
    expect(mydragebol, findsOneWidget);
    await tester.drag(mydragebol, const Offset(500.0, 500.0));
    await tester.pump();
    expect(tester.getTopLeft(mydragebol), Offset(460.0, 460.0));
  });



  testWidgets('test riverpod list gamers', (tester) async {
    firestore = FakeFirebaseFirestore();
    await initApp();
    firestore.collection(Collection.position.name)
        .doc("c1").set({"x" : 120, "y" : 120, "color": color});
    firestore.collection(Collection.position.name)
        .doc("c2").set({"x" : 120, "y" : 120, "color": color});
    firestore.collection(Collection.position.name)
        .doc("c3").set({"x" : 120, "y" : 120, "color": color});
    firestore.collection(Collection.position.name)
        .doc("c4").set({"x" : 120, "y" : 120, "color": color});
    firestore.collection(Collection.position.name)
        .doc("c5").set({"x" : 120, "y" : 120, "color": color});


    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    sleep(const Duration(seconds: 2));
    await tester.pump();
    var gamerscount = tester.elementList(find.byType(CirclesFromFirestore)).length;

    expect(gamerscount, 5);
    var newc = tester.element(find.byType(NewCercle)).length;




  });
}
