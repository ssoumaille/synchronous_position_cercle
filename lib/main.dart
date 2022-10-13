import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'circle/circle.dart';
import 'firebase_options.dart';

final idCircle = '9999999'; //'''${Random().nextInt(9999999)}';

enum Collection { position }

// Random color for circles
final color = (math.Random().nextDouble() * 0xFFFFFF).toInt();
final randomColor = Color(color).withOpacity(1.0);

/// Limit Firestore offset write ops
final throttler = PublishSubject<Function()>();
Offset myThrottledOffset = Offset.zero;

/// Current Circle
Circle myCircle = Circle(id: "0", x: 0, y: 0, color: 0);

// Providers
final offsetProvider = StateProvider<Offset>((ref) => Offset.zero);
final firestoreSCircleProvider = StreamProvider<Iterable<Circle>>((ref) =>
    FirebaseFirestore.instance
        .collection(Collection.position.name)
        .snapshots()
        .map((event) =>
            event.docs.where((ee) => ee.id != idCircle).map((doc) => Circle(
                  id: doc.id,
                  x: doc.data()['x'],
                  y: doc.data()['y'],
                  color: doc.data()['color'],
                ))));

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance
      .collection(Collection.position.name)
      .doc(idCircle)
      .set({"x": 0, "y": 0, "color": color});

  final local = await FirebaseFirestore.instance
      .collection(Collection.position.name)
      .doc(idCircle)
      .get();

  myCircle = Circle(
      id: idCircle,
      x: local.data()!['x'],
      y: local.data()!['y'],
      color: local.data()!['color']);

  throttler
      .throttleTime(const Duration(seconds: 1))
      .forEach((element) => element());

  runApp(const ProviderScope(
      child: MaterialApp(
          home: Center(
    child: DragGame(),
  ))));
}

class DragGame extends ConsumerWidget {
  const DragGame({super.key});

  @override
  build(_, ref) {
    final listCircle = ref.watch(firestoreSCircleProvider).value ?? [];
    return Stack(
      children: [
        for (Circle circle in listCircle) OtherWidget(circle),
        DraggableWidget(myCircle),
      ],
    );
  }
}

class OtherWidget extends ConsumerWidget {
  final Circle circle;

  const OtherWidget(this.circle, {super.key});

  Widget _buildCircle(int encoded) =>
      CircleAvatar(backgroundColor: Color(encoded).withOpacity(0.8));

  @override
  build(_, ref) => Positioned(
        top: circle.y.toDouble(),
        left: circle.x.toDouble(),
        child: _buildCircle(circle.color),
      );
}

Future<void> updatePositionFirestore() {
  print("I'm throttled");
  return FirebaseFirestore.instance
      .collection(Collection.position.name)
      .doc(idCircle)
      .update({
    "x": myThrottledOffset.dx,
    "y": myThrottledOffset.dy,
  });
}

class DraggableWidget extends ConsumerWidget {
  final Circle circle;

  const DraggableWidget(this.circle, {Key? key}) : super(key: key);

  Widget _buildCirle(Color color) => CircleAvatar(backgroundColor: color);

  @override
  build(_, ref) => Positioned(
      top: ref.watch(offsetProvider).dy,
      left: ref.watch(offsetProvider).dx,
      child: Draggable(
        feedback: _buildCirle(Colors.green),
        onDragUpdate: (details) {
          myThrottledOffset = details.localPosition;
          throttler.add(updatePositionFirestore);
        },
        onDraggableCanceled: (_, Offset offset) {
          ref.read(offsetProvider.notifier).update((state) => offset);
          // FirebaseFirestore.instance.collection(Collection.position.name).doc(idCircle).update(
          //     {
          //       "x": offset.dx,
          //       "y": offset.dy,
          //     });
        },
        child: _buildCirle(Colors.green),
      ));
}
