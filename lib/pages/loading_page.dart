import 'package:flutter/material.dart';
import 'package:flutter_parse_server/pages/home_page.dart';
import 'package:flutter_parse_server/pages/login_page.dart';
import 'package:flutter_parse_server/repositories/diet_plan_provider_api.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  String _parseServerState = 'Checking Parse Server...';

  final appId = const String.fromEnvironment('appId');
  final serverUrl = const String.fromEnvironment('serverUrl');

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initParse();
    });
    super.initState();
  }

  Future<void> _initParse() async {
    try {
      await Parse().initialize(
        appId,
        serverUrl,
        coreStore: await CoreStoreSharedPrefsImp
            .getInstance(), // SharedPref is the default store
      );

      final ParseResponse response = await Parse().healthCheck();
      if (response.success) {
        final ParseUser user = await ParseUser.currentUser();
        if (user == null) {
          _redirectToPage(context, LoginPage());
        } else {
          _redirectToPage(context, HomePage(DietPlanProviderApi()));
        }
      } else {
        print(
            'Parse Server Not avaiable\n due to ${response.error.toString()}');
        setState(() {
          _parseServerState =
              'Unable to connect to Parse Server, Please try again later.';
        });
      }
    } catch (e) {
      print('Parse Server Not avaiable\n due to ${e.toString()}');
      setState(() {
        _parseServerState =
            'Unable to connect to Parse Server, Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _showLogo(),
          const SizedBox(height: 20),
          Center(
            child: Text(_parseServerState),
          ),
        ],
      ),
    );
  }

  Widget _showLogo() {
    return Hero(
      tag: 'hero',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('parse.png'),
        ),
      ),
    );
  }

  Future<void> _redirectToPage(BuildContext context, Widget page) async {
    final MaterialPageRoute<bool> newRoute =
        MaterialPageRoute<bool>(builder: (BuildContext context) => page);

    final bool nav = await Navigator.of(context)
        .pushAndRemoveUntil<bool>(newRoute, ModalRoute.withName('/'));
    if (nav == true) {
      _initParse();
    }
  }
}
