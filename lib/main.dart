import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Parse Server Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final appId = '123456789';
  final serverUrl = 'http://192.168.1.200:1337/parse';

  int _currentIndex = 0;
  dynamic user;

  ParseResponse response;
  ParseUser parseUser;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    await Parse().initialize(appId, serverUrl);
    user = await ParseUser.currentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: IndexedStack(
          index: _currentIndex,
          children: <Widget>[
            Text(
              'List Page',
            ),
            user == null ? signupOrLogin() : profile(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add',
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'List'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget profile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(user.toString()),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              authOps('logout');
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget signupOrLogin() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              authOps('signup');
            },
            child: Text('Sign Up'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              authOps("login");
            },
            child: Text('Login'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              authOps('reset');
            },
            child: Text('Reset Password'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              authOps('verify');
            },
            child: Text('Send Verification Email'),
          ),
        ],
      ),
    );
  }

  void authOps(String ops) async {
    parseUser =
        ParseUser.createUser('testuser', 'password', 'zhw516@yahoo.com');
    switch (ops) {
      case 'signup':
        response = await parseUser.signUp();
        break;
      case 'login':
        response = await parseUser.login();
        break;
      case 'logout':
        response = await parseUser.logout();
        break;
      case 'reset':
        response = await parseUser.requestPasswordReset();
        break;
      case 'verify':
        response = await parseUser.verificationEmailRequest();
        break;
      default:
    }

    if (response.success) {
      setState(() {
        if (ops == 'login' || ops == 'signup') {
          user = response.result;
        } else {
          user = null;
        }
      });
    } else {
      print(response.error.message);
    }
  }
}
