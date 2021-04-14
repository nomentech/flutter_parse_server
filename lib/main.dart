import 'package:flutter/material.dart';
import 'package:flutter_parse_server/pages/loading_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Parse',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Parse Server'),
        ),
        body: Center(
          child: LoadingPage(),
        ),
      ),
    );
  }
}
