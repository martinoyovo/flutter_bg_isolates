import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    getDataFromFirebase();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container()
    );
  }
}

//[token, port]
Future<void> _isolateGetJobs(List<Object> args) async {
  final rootIsolateToken = args[0] as RootIsolateToken;
  final sendPort = args[1] as SendPort;

  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final jobRef = FirebaseFirestore.instance.collection('jobs');

  final jobs = await jobRef.get();

  final jobFirst = jobs.docs.first["jobName"];

  print('isolate response: $jobFirst');
  sendPort.send(jobFirst);
}

Future getDataFromFirebase() async {
  RootIsolateToken? rootIsolateToken = RootIsolateToken.instance;
  if(rootIsolateToken == null) {
    print('Cannot get the RootIsolateToken');
    return;
  }

  ReceivePort receivePort = ReceivePort();
  await Isolate.spawn(_isolateGetJobs, [rootIsolateToken, receivePort.sendPort]);

  receivePort.listen((message) {
    print('isolate response: $message');
  });
}