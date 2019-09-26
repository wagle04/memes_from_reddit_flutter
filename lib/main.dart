import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memes_from_reddit/post.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as JSON;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:memes_from_reddit/restart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool downloaded = prefs.getBool('downloaded');
  if (downloaded == null) downloaded = false;
  try {
    String jsonfile = await _MyHomePageState.readFile();
    print(jsonfile);
    List<dynamic> jsondata = JSON.jsonDecode(jsonfile);

    for (int i = 0; i < jsondata.length; i++) {
      MyHomePage.postList.add(Post.fromJson(jsondata[i]));
    }
  } on Exception catch (e) {
    print(e);
  }

  runApp(RestartWidget(
      child: MaterialApp(
    title: 'Memes from Reddit',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: downloaded
        ? PostViews(
            postlist: MyHomePage.postList,
          )
        : MyHomePage(title: 'Memes from Reddit'),
  )));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  static List<String> subreddit = [];
  static List<Post> postList = [];
  static List<String> allSubreddits = [
    "memes",
    "funny",
    "dankmemes",
    "wholesomememes",
    "pewdiepiesubmissions",
    "tinder",
    "facepalm",
    "comedycemetery"
  ];

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String time = "day";
  int limit = 1;
  final limitController = TextEditingController();

  bool memes = false;
  bool funny = false;
  bool dankmemes = false;
  bool wholesomememes = false;
  bool pewdiepiesubmissions = false;
  bool tinder = false;
  bool facepalm = false;
  bool comedycemetery = false;

  bool downloadedPosts = false;

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/data.txt');
  }

  static Future<File> writeFile(String data) async {
    final file = await _localFile;
    return file.writeAsString(data);
  }

  static Future<String> readFile() async {
    final file = await _localFile;
    String jsonfile = await file.readAsString();
    return jsonfile;
  }

  fetchPost(String time, int limit, List<String> subreddits) async {
    Map<String, dynamic> body = {
      "time": time,
      "limit": limit,
      "subreddits": subreddits
    };
    Map<String, String> headers = {"Content-type": "application/json"};

    final response = await http.post(
        "https://memes-from-reddit.herokuapp.com/redditposts",
        headers: headers,
        body: JSON.jsonEncode(body));
    if (response.statusCode == 200) {
      //return response;
      print("Success");
      writeFile(" ");
      List<dynamic> jsonfile = await JSON.jsonDecode(response.body);

      MyHomePage.postList = [];
      for (int i = 0; i < jsonfile.length; i++) {
        MyHomePage.postList.add(Post.fromJson(jsonfile[i]));
      }
      // DateTime now = new DateTime.now();
      for (int i = 0; i < jsonfile.length; i++) {
        // print(MyHomePage.postList[i].subreddit);
        // print(MyHomePage.postList[i].caption);
        // print(MyHomePage.postList[i].photolink);

        FileInfo photo = await DefaultCacheManager()
            .downloadFile(MyHomePage.postList[i].photolink);

        String filepath = photo.file.toString();

        MyHomePage.postList[i].photolink =
            filepath.substring(7, filepath.length - 1);

        // print(MyHomePage.postList[i].photolink);
        jsonfile[i][1] = MyHomePage.postList[i].photolink;
        print("Post Count: " + i.toString());
      }
      // DateTime now2 = new DateTime.now();
      // print("time..........");
      // print(now2.difference(now));

      writeFile(JSON.jsonEncode(jsonfile));
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('downloaded', true);
    } else {
      print("Error");
      print(response.body);
      //throw Exception('Failed to load post');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        print("back pressed");
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                print("Restart App");
                MyHomePage.subreddit = [];
                RestartWidget().restartApp(context);
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                elevation: 10.0,
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 30, 5),
                      child: Text(
                        'Time:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    DropdownButton<String>(
                      value: time,
                      hint: Text(time),
                      style: TextStyle(color: Colors.black, fontSize: 15.0),
                      underline: Container(
                        height: 2,
                        color: Colors.blueAccent,
                      ),
                      onChanged: (String newValue) {
                        setState(() {
                          MyHomePage.subreddit = [];
                          time = newValue;
                          print("Time: " + time);
                          print("Limit: " + limit.toString());
                          print("Subreddits: ${MyHomePage.subreddit}");
                        });
                      },
                      items: <String>['day', 'month', 'year']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 10.0,
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 30, 5),
                      child: Text(
                        'Post per Subreddit:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      height: 50.0,
                      width: 50.0,
                      child: TextField(
                        autocorrect: false,
                        controller: limitController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 20.0),
                        decoration: InputDecoration(
                            hintText: "1 - 99", counterText: ""),
                        maxLength: 2,
                        onTap: () {
                          setState(() {
                            MyHomePage.subreddit = [];
                            memes = funny = dankmemes = wholesomememes =
                                pewdiepiesubmissions =
                                    tinder = facepalm = comedycemetery = false;
                          });
                        },
                        onChanged: (value) {
                          limit = int.parse(limitController.text);
                          print("Time: " + time);
                          print("Limit: " + limit.toString());
                          print("Subreddits: ${MyHomePage.subreddit}");
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 10.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 30, 5),
                      child: Text(
                        'Subreddits:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SubReddit(
                          subredditbool: memes,
                          subredditname: "memes",
                        ),
                        SubReddit(
                          subredditbool: funny,
                          subredditname: "funny",
                        ),
                        SubReddit(
                          subredditbool: dankmemes,
                          subredditname: "dankmemes",
                        ),
                        SubReddit(
                          subredditbool: wholesomememes,
                          subredditname: "wholesomememes",
                        ),
                        SubReddit(
                          subredditbool: pewdiepiesubmissions,
                          subredditname: "pewdiepiesubmissions",
                        ),
                        SubReddit(
                          subredditbool: tinder,
                          subredditname: "tinder",
                        ),
                        SubReddit(
                          subredditbool: facepalm,
                          subredditname: "facepalm",
                        ),
                        SubReddit(
                          subredditbool: comedycemetery,
                          subredditname: "comedycemetery",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: FlatButton(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  color: Colors.red,
                  child: Text(
                    'Download',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    if (MyHomePage.subreddit.isNotEmpty) {
                      print('download posts');

                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Container(
                                height: 75,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                        'Downloading ${limit * MyHomePage.subreddit.length} Posts'),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                        backgroundColor: Colors.white,
                                        strokeWidth: 5,
                                      )),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });

                      await fetchPost(time, limit, MyHomePage.subreddit);

                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (BuildContext context) {
                        return PostViews(
                          postlist: MyHomePage.postList,
                        );
                      }));
                    } else {
                      print("No subreddit selected");
                      showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                'No subreddit selected',
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Post {
  String subreddit;
  String caption;
  String photolink;

  Post({this.subreddit, this.caption, this.photolink});

  Post.fromJson(List<dynamic> data)
      : subreddit = data[0],
        photolink = data[1],
        caption = data[2];
}

class SubReddit extends StatefulWidget {
  bool subredditbool;
  String subredditname;
  SubReddit(
      {Key key, @required this.subredditbool, @required this.subredditname})
      : super(key: key);

  _SubRedditState createState() => _SubRedditState();
}

class _SubRedditState extends State<SubReddit> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Checkbox(
          value: widget.subredditbool,
          onChanged: (value) {
            setState(() {
              widget.subredditbool = value;
              print('${widget.subredditname}: ${widget.subredditbool}');
              if (value)
                MyHomePage.subreddit.add(widget.subredditname);
              else
                MyHomePage.subreddit.remove(widget.subredditname);
              print("Subreddits: ${MyHomePage.subreddit}");
            });
          },
        ),
        Text(
          "r/${widget.subredditname}",
          style: TextStyle(
              fontSize: 17.0,
              color: widget.subredditbool ? Colors.black : Colors.grey),
        )
      ],
    );
  }
}
