import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'firebase_options.dart';
import 'circle/circle.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.collection(Collection.position.name)
      .doc(idCircle).set({"x" : 20, "y" : 20, "color": color});
  final document  = await FirebaseFirestore.instance
      .collection(Collection.position.name)
      .doc(idCircle).get();
  myCircle = Circle(id: idCircle, x: document.data()!['x'], y:document.data()!['y'], color:document.data()!['color']);

  throttler.throttleTime(const Duration(seconds: 1)).forEach((element) {
    element();
  });

  runApp(const ProviderScope(child: MyApp()));
}

enum Collection { position }

// Random color for circles
final color = (math.Random().nextDouble() * 0xFFFFFF).toInt();
final randomColor = Color(color).withOpacity(1.0);

// Throttler
final throttler = PublishSubject<Function()>();
Offset myThrottledOffset = Offset(20, 20);

// instantiate myCircle
Circle myCircle = Circle(id: "0", x: 20, y: 20, color: 0);

// Providers
final offsetProvider = StateProvider<Offset>((ref) => Offset(20, 20));
final firestoreSCircleProvider = StreamProvider<List<Circle>>((ref) => FirebaseFirestore.instance
    .collection(Collection.position.name).snapshots().map((event) {
    final rs = event.docs.where((ee) => ee.id != idCircle).map((e) {
        return Circle(
          id: e.id,
          x: e.data()['x'],
          y: e.data()['y'],
          color: e.data()['color']
,        );
      }).toList();
    return rs;
}));

final idCircle = '123456788';//'''${Random().nextInt(9999999)}';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  build(_) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(primarySwatch: Colors.blue,),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  build(_) => const Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: DragGame()
  );
}

class DragGame extends ConsumerWidget {
   const DragGame({super.key});

  @override
  build(_,ref) {
    final listCircle = ref.watch(firestoreSCircleProvider).value ?? [];
    return Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: 520,
                height: 20,
                color: Colors.red.shade400,
              ),
            ),
            Positioned(
              left: 0,
              child: Container(
                width: 20,
                height: 520,
                color: Colors.red.shade400,
              ),
            ),
            Positioned(
              top: 500,
              child: Container(
                width: 520,
                height: 20,
                color: Colors.red.shade400,
              ),
            ),
            Positioned(
              left: 500,
              child: Container(
                width: 20,
                height: 500,
                color: Colors.red.shade400,
              ),
            ),
            for (Circle circle in listCircle)
              CirclesFromFirestore(circle),
            MyDraggableCircle(myCircle),
          ],
    );
  }
}

class CirclesFromFirestore extends ConsumerWidget {
  final Circle circle;
  const CirclesFromFirestore(this.circle, {Key? key}) : super(key: key);

  Widget _buildCircle(int color) {
    final _color = Color(color).withOpacity(0.8);
    return CircleAvatar(backgroundColor: _color,);
  }

  @override
  build(_, ref) => Positioned(
      top: circle.y.toDouble(),
      left: circle.x.toDouble(),
      child: _buildCircle(circle.color),
  );
}

Future<void> updatePositionFirestore() {
  print("updating position in firestore document...");
  return FirebaseFirestore.instance.collection(Collection.position.name).doc(idCircle).update(
      {
        "x": myThrottledOffset.dx,
        "y": myThrottledOffset.dy,
      });
}

class MyDraggableCircle extends ConsumerWidget {
  final Circle circle ;
  const MyDraggableCircle(this.circle,  {Key? key}) : super(key: key);

  Widget _buildCircle(Color color) => CircleAvatar(backgroundColor: color,);

  Offset _limitingMovementToWindowOnly(Offset position) {
    myThrottledOffset = position;
    if (myThrottledOffset.dy > 460) {
      myThrottledOffset = Offset(myThrottledOffset.dx, 460);
    }
    if (myThrottledOffset.dy < 20) {
      myThrottledOffset = Offset(myThrottledOffset.dx, 20);
    }
    if (position.dx < 20) {
      myThrottledOffset = Offset(20, myThrottledOffset.dy);
    }
    if (position.dx > 460) {
      myThrottledOffset = Offset(460, myThrottledOffset.dy);
    }
    return myThrottledOffset;
  }

  @override
  build(_, ref) => Positioned(
      top: ref.watch(offsetProvider).dy,
      left: ref.watch(offsetProvider).dx,
      child: Draggable(
        feedback: _buildCircle(Color.fromRGBO(0, 0, 0, 0)),
        childWhenDragging: _buildCircle(Colors.red.shade50),
        onDragUpdate: (details) {
          Offset position = _limitingMovementToWindowOnly(details.localPosition);
          throttler.add(updatePositionFirestore);
          ref.read(offsetProvider.notifier).update((state) => position);
        },
        // onDraggableCanceled: (_,Offset offset){
        // },
        child: _buildCircle(Colors.green),
    ));
}
