import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'package:flutter_parse_server/models/user.dart';
import 'package:flutter_parse_server/base/api_response.dart';
import 'package:flutter_parse_server/models/diet_plan.dart';
import 'package:flutter_parse_server/repositories/diet_plan_provider_contract.dart';

class HomePage extends StatefulWidget {
  const HomePage(this._dietPlanProvider, this._user);

  final DietPlanProviderContract _dietPlanProvider;
  final User _user;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isUploading = false;
  final ImagePicker picker = ImagePicker();

  List<DietPlan> randomDietPlans = <DietPlan>[];

  @override
  void initState() {
    super.initState();
    final List<dynamic> json = const JsonDecoder().convert(dietPlansToAdd);
    for (final Map<String, dynamic> element in json) {
      final DietPlan dietPlan = DietPlan();
      element.forEach(
          (String k, dynamic v) => dietPlan.set<dynamic>(k, parseDecode(v)));
      randomDietPlans.add(dietPlan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () async {
                final ParseUser user = await ParseUser.currentUser();
                user.logout(deleteLocalUserData: true);
                Navigator.pop(context, true);
              },
              child: Text(
                'Logout',
                style: TextStyle(fontSize: 17.0, color: Colors.white),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _showDietList(),
            _showProfile(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final DietPlan dietPlan =
                randomDietPlans[Random().nextInt(randomDietPlans.length - 1)];
            final ParseUser user = await ParseUser.currentUser();
            dietPlan.set('user', user);
            await widget._dietPlanProvider.add(dietPlan);
            setState(() {});
          },
          tooltip: 'Add Diet Plans',
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index)),
      ),
    );
  }

  Widget _showProfile() {
    String imageUrl;
    if (widget._user.displayPicture == null) {
      imageUrl = 'https://thinkforactions.com/images/team/avatar.png';
    } else {
      imageUrl = widget._user.displayPicture;
    }

    return Center(
      child: _isUploading
          ? CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    updateDisplayPicture();
                  },
                  child: Container(
                      height: 100, width: 100, child: Image.network(imageUrl)),
                ),
                SizedBox(height: 10),
                Text(widget._user.username),
                SizedBox(height: 10),
                Text(widget._user.emailAddress),
              ],
            ),
    );
  }

  void updateDisplayPicture() async {
    PickedFile pickedFile = await picker.getImage(source: ImageSource.gallery);
    ParseFileBase parseFile;
    if (kIsWeb) {
      //Seems weird, but this lets you get the data from the selected file as an Uint8List very easily.
      ParseWebFile file =
          ParseWebFile(null, name: 'displayPicture', url: pickedFile.path);
      await file.download();
      parseFile = ParseWebFile(file.file, name: file.name);
    } else {
      parseFile = ParseFile(File(pickedFile.path));
    }
    setState(() => _isUploading = true);
    await parseFile.upload();
    widget._user.displayPicture = parseFile.url;
    await widget._user.save();
    await widget._user.getUpdatedUser();
    setState(() => _isUploading = false);
  }

  Widget _showDietList() {
    return FutureBuilder<ApiResponse>(
        future: widget._dietPlanProvider.getAll(),
        builder: (BuildContext context, AsyncSnapshot<ApiResponse> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.success) {
              if (snapshot.data.results == null ||
                  snapshot.data.results.isEmpty) {
                return const Center(
                  child: Text('No Data'),
                );
              }
            }
            return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data.results.length,
                itemBuilder: (BuildContext context, int index) {
                  final DietPlan dietPlan = snapshot.data.results[index];
                  final String id = dietPlan.objectId;
                  final String name = dietPlan.name;
                  final String description = dietPlan.description;
                  final bool status = dietPlan.status;
                  return Dismissible(
                    key: Key(id),
                    background: Container(color: Colors.red),
                    onDismissed: (DismissDirection direction) async {
                      widget._dietPlanProvider.remove(dietPlan);
                    },
                    child: ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(fontSize: 20.0),
                      ),
                      subtitle: Text(description),
                      trailing: IconButton(
                          icon: status
                              ? const Icon(
                                  Icons.done_outline,
                                  color: Colors.green,
                                  size: 20.0,
                                )
                              : const Icon(Icons.done,
                                  color: Colors.grey, size: 20.0),
                          onPressed: () async {
                            dietPlan.status = !dietPlan.status;
                            await dietPlan.save();
                            setState(() {});
                          }),
                    ),
                  );
                });
          } else {
            return const Center(
              child: Text('No Data'),
            );
          }
        });
  }

  String dietPlansToAdd =
      '[{"className":"Diet_Plans","Name":"Textbook","Description":"For an active lifestyle and a straight forward macro plan, we suggest this plan.","Fat":25,"Carbs":50,"Protein":25,"Status":false},'
      '{"className":"Diet_Plans","Name":"Body Builder","Description":"Default Body Builders Diet","Fat":20,"Carbs":40,"Protein":40,"Status":true},'
      '{"className":"Diet_Plans","Name":"Zone Diet","Description":"Popular with CrossFit users. Zone Diet targets similar macros.","Fat":30,"Carbs":40,"Protein":30,"Status":true},'
      '{"className":"Diet_Plans","Name":"Low Fat","Description":"Low fat diet.","Fat":15,"Carbs":60,"Protein":25,"Status":false},'
      '{"className":"Diet_Plans","Name":"Low Carb","Description":"Low Carb diet, main focus on quality fats and protein.","Fat":35,"Carbs":25,"Protein":40,"Status":true},'
      '{"className":"Diet_Plans","Name":"Paleo","Description":"Paleo diet.","Fat":60,"Carbs":25,"Protein":10,"Status":false},'
      '{"className":"Diet_Plans","Name":"Ketogenic","Description":"High quality fats, low carbs.","Fat":65,"Carbs":5,"Protein":30,"Status":true}]';
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key key,
    @required this.currentIndex,
    @required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'List',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}
