import 'dart:math' as math;
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
  firestoreInstance = FirebaseFirestore.instance;

  await initApp();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> initApp() async{
  isSync = false;
  firestoreInstance.collection(Collection.position.name)
      .doc(idCircle).set({"x" : 20, "y" : 20, "color": color});
  final document  = await firestoreInstance
      .collection(Collection.position.name)
      .doc(idCircle).get();
  myCircle = Circle(id: idCircle, x: document.data()!['x'], y:document.data()!['y'], color:document.data()!['color']);

  /* TODO  Find a way to not comment theses lines for testing*/
  // throttler.throttleTime(const Duration(milliseconds: 100)).forEach((element) {
  //   isSync =true;
  //   element();
  // });
}
late  FirebaseFirestore  firestoreInstance;
final idCircle = '9999999';//'''${Random().nextInt(9999999)}';

enum Collection { position }
late bool isSync;

// Random color for circles
final color = (math.Random().nextDouble() * 0xFFFFFF).toInt();
final randomColor = Color(color).withOpacity(1.0);

// Throttler
final throttler = PublishSubject<Function()>();
Offset myThrottledOffset = Offset(20, 20);
late Circle myCircle;

// Providers
final offsetProvider = StateProvider<Offset>((ref) => Offset(20, 20));
final firestoreSCircleProvider = StreamProvider<List<Circle>>((ref) => firestoreInstance
    .collection(Collection.position.name).snapshots().map((event) {
  return event.docs.where((ee) => ee.id != idCircle).map((e) {
        return Circle(
          id: e.id,
          x: e.data()['x'],
          y: e.data()['y'],
          color: e.data()['color']
,        );
      }).toList();
}));

Offset limitingMovementToWindowOnly(Offset position) {
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
            Positioned(
              top: 540,
              left: 200,
              child: ElevatedButton(
                child: Text("add user"),
                onPressed: (){
                  firestoreInstance.collection(Collection.position.name)
                      .doc((math.Random().nextInt(99999)).toInt().toString())
                      .set({"x" : Random().nextInt(460),
                    "y" : Random().nextInt(460),
                    "color": (math.Random().nextDouble() * 0xFFFFFF).toInt()});
                },
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

updatePositionFirestore() {
  return firestoreInstance.collection(Collection.position.name).doc(idCircle).update(
      {
        "x": myThrottledOffset.dx,
        "y": myThrottledOffset.dy,
      });
}

class MyDraggableCircle extends ConsumerWidget {
  final Circle circle ;
  const MyDraggableCircle(this.circle,  {Key? key}) : super(key: key);

  Widget buildCircle(Color color) => CircleAvatar(backgroundColor: color,);
  
  @override
  build(_, ref) => Positioned(
      top: ref.watch(offsetProvider).dy,
      left: ref.watch(offsetProvider).dx,
      child: Draggable(
        feedback: buildCircle(const Color.fromRGBO(0, 0, 0, 0)),
        childWhenDragging: buildCircle(randomColor.withOpacity(0.5)),
        onDragUpdate: (details) {
          limitingMovementToWindowOnly(details.localPosition);
          throttler.add(updatePositionFirestore);
          ref.read(offsetProvider.notifier).update((state) => myThrottledOffset);
        },
        // onDraggableCanceled: (_,Offset offset){
        // },
        child: buildCircle(randomColor),
    ));
}
