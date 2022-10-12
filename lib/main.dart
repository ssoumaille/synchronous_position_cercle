import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  build(_) => Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: DragGame()

    );
}


class DragGame extends StatefulWidget {
  @override
  _DragGameState createState() => new _DragGameState();
}

class _DragGameState extends State<DragGame> {
  var boxNumberIsDragged = null;

  @override
  void initState() {
    // boxNumberIsDragged = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: BoxConstraints.expand(),
        color: Colors.grey,
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.green,
              width: 500,
              height: 500,
            ),
            buildDraggableBox(1, Colors.red, const Offset(30.0, 100.0)),

          ],
        ));
  }

  Widget buildDraggableBox(int boxNumber, Color color, Offset offset) {
    Offset offsetChange;
    return Draggable(
      maxSimultaneousDrags: boxNumberIsDragged == null ||
          boxNumber == boxNumberIsDragged ? 1 : 0,
      child: _buildBox(Colors.white, offset),
      feedback: _buildBox(color, offset),
      childWhenDragging: _buildBox(Color.fromRGBO(0, 0, 0, 0), offset, onlyBorder: true),
      onDragStarted: () {
        setState(() {
          boxNumberIsDragged = boxNumber;
        });
      },
      onDragCompleted: () {
        setState(() {
          boxNumberIsDragged = null;
        });
      },
      onDragUpdate: (details) {
        print(details.localPosition);
      },
      onDraggableCanceled: (_, offset) {
        offsetChange = offset;
        print(offsetChange);
        setState(() {
          boxNumberIsDragged = null;
        });
      },
    );
  }

  Widget _buildBox(Color color, Offset offset, {bool onlyBorder: false}) {
    return CircleAvatar(
      backgroundColor: color,

    );
    Container(
      height: 50.0,
      width: 50.0,
      margin: EdgeInsets.only(left: offset.dx, top: offset.dy),
      decoration: BoxDecoration(
          color: !onlyBorder ? color : Colors.grey,
          border: Border.all(color: color)),
    );
  }
}
