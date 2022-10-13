import 'dart:math';

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
      .doc(idCircle).set({"x" : 0, "y" : 0});
  final document  = await FirebaseFirestore.instance
      .collection(Collection.position.name)
      .doc(idCircle).get() ;
  myCircle = Circle(id: idCircle, x: document.data()!['x'], y:document.data()!['y']);

  throttler.throttleTime(const Duration(milliseconds: 2500)).forEach((element) {
    element();
  });
  throttler.add(updatePositionFirestore);

  runApp(const ProviderScope(child: MyApp()));
}

final throttler = PublishSubject<Function()>();
late final Circle myCircle;

final circleProvider = StreamProvider<List<Circle>>((ref) => FirebaseFirestore.instance
    .collection(Collection.position.name).snapshots().map((event) {
    final rs = event.docs.where((ee) => ee.id != idCircle).map((e) {
        return Circle(
          id: e.id,
          x: e.data()['x'],
          y: e.data()['y'],
        );
      }).toList();
    return rs;
}));

final idCircle = '9999999';//'''${Random().nextInt(9999999)}';

enum Collection { position }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  build(_) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
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
  build(_) => Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: DragGame()
  );
}

class DragGame extends ConsumerWidget {
   DragGame({super.key});

  @override
  build(_,ref) {
    final listCircle = ref.watch(circleProvider).value ?? [];
    return Stack(
          children: [
            for (Circle circle in listCircle)
              OtherWidget(circle),

            DraggableWidget(myCircle),
          ],
    );
  }
}

class OtherWidget extends ConsumerWidget {
  final Circle circle;
  OtherWidget(this.circle, {Key? key}) : super(key: key);

  // late int boxNumberIsDragged = 0;

  Widget _buildBox(Color color, Offset offset, {bool onlyBorder: false}) {
    return CircleAvatar(
      backgroundColor: color,
    );
  }

  @override
  build(_, ref) {
    return Positioned(
        top:circle.y.toDouble(),left: circle.x.toDouble() ,
        child: _buildBox(Colors.blue, const Offset(30.0, 100.0))) ;
  }
}

final offsetProvider = StateProvider<Offset>((ref) => Offset(0, 0));

late Offset myThrottledOffset = Offset(0, 0);
Future<void> updatePositionFirestore() {
  print("I'm throttled");
  return FirebaseFirestore.instance.collection(Collection.position.name).doc(idCircle).update(
      {
        "x": myThrottledOffset.dx,
        "y": myThrottledOffset.dy,
      });
}

class DraggableWidget extends ConsumerWidget {
  final Circle circle ;
  DraggableWidget(this.circle,  {Key? key}) : super(key: key);

  Widget _buildBox(Color color, Offset offset, {bool onlyBorder: false}) {
    return CircleAvatar(
      backgroundColor: color,
    );
  }

  @override
  build(_, ref) {
    return Positioned(
        top:ref.watch(offsetProvider).dy ,
        left:ref.watch(offsetProvider).dx ,

        child: Draggable(
      feedback: _buildBox(Colors.green, Offset.zero),
      childWhenDragging:
      _buildBox(Color.fromRGBO(0, 0, 0, 0.5), Offset.zero, onlyBorder: true),
      onDragUpdate: (details) {
        myThrottledOffset = details.localPosition;
        throttler.add(updatePositionFirestore);
      },
      onDraggableCanceled: (_,Offset offset){
        ref.read(offsetProvider.notifier).update((state) => offset);

        // FirebaseFirestore.instance.collection(Collection.position.name).doc(idCircle).update(
        //     {
        //       "x": offset.dx,
        //       "y": offset.dy,
        //     });
      },

      child: _buildBox(Colors.green, const Offset(30.0, 100.0)),
    )) ;
  }
}
