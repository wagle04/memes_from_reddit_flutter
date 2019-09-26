import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memes_from_reddit/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PostViews extends StatefulWidget {
  List<Post> postlist;
  PostViews({Key key, this.postlist}) : super(key: key);

  @override
  _PostViewsState createState() => _PostViewsState();
}

class _PostViewsState extends State<PostViews> {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> get _localFile async {
    final path = await _localPath;
    return '$path/data.txt';
  }

  reloadApp() async {
    print("Restart App");
    MyHomePage.postList = [];
    MyHomePage.subreddit = [];
    print("post list:");
    print(MyHomePage.postList);
    print("Subreddit list:");
    print(MyHomePage.subreddit);
    DefaultCacheManager().emptyCache();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloaded', false);
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (BuildContext context) {
      return MyHomePage(title: 'Memes from Reddit');
    }));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print("back pressed");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('downloaded', true);
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Posts"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          "Are you sure? Pressing 'Yes' will clear all the downloaded content ! ",
                          style: TextStyle(fontSize: 15.0),
                        ),
                        content: (Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                              child: Text('No'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            FlatButton(
                              child: Text('Yes'),
                              onPressed: reloadApp,
                            ),
                          ],
                        )),
                      );
                    });
              },
            )
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: widget.postlist.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Card(
                      elevation: 10,
                      child: PostView(
                        caption: widget.postlist[i].caption,
                        subreddit: widget.postlist[i].subreddit,
                        photolink: widget.postlist[i].photolink,
                      ),
                      shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostView extends StatelessWidget {
  String subreddit;
  String caption;
  String photolink;

  PostView({Key key, this.subreddit, this.caption, this.photolink})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: 100,
      width: MediaQuery.of(context).size.width * 0.975,
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'From Subreddit:',
                  style: TextStyle(fontSize: 15),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    subreddit,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              caption,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Image.file(File(photolink)),
        ],
      ),
    );
  }
}
