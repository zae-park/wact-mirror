import 'package:flutter/material.dart';

class QTRoom extends StatefulWidget {
  const QTRoom({super.key});

  @override
  State<QTRoom> createState() => _QTRoomState();
}

class _QTRoomState extends State<QTRoom> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('준비중'),
      ),
    );
  }
}
