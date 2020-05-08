import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/library/configuration.dart';
import 'package:the_spot/services/library/search_engine.dart';
import 'package:the_spot/services/library/usersListView.dart';
import 'package:the_spot/theme.dart';

class ChatListPage extends StatefulWidget {
  ChatListPage({this.configuration});

  final Configuration configuration;

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool userIsSearching = false;
  bool isWaiting = true;

  String query;

  List<UserProfile> queryResult = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
      body: Column(
        children: <Widget>[
          showSearchBarWidget(),
          userIsSearching ? showQueryResultsWidget() : showChatListWidget(),
        ],
      ),
    );
  }

  Widget showSearchBarWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          widget.configuration.screenWidth / 26,
          widget.configuration.screenWidth / 10,
          widget.configuration.screenWidth / 26,
          0),
      child: Container(
        height: widget.configuration.screenWidth / 10,
        decoration: BoxDecoration(
            color: PrimaryColor,
            borderRadius: BorderRadius.all(Radius.circular(100))),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 10, 0),
          child: TextField(
            onChanged: (String value) async {
              setState(() {
                isWaiting = true;
                if (value.trim().length > 0) {
                  query = value.trim();
                  userIsSearching = true;
                } else {
                  userIsSearching = false;
                }
              });
              queryResult = await getUsers();
              setState(() {
                isWaiting = false;
              });
            },
            style: TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: "Search...",
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget showQueryResultsWidget() {
    if (isWaiting)
      return Padding(
          padding: EdgeInsets.only(top: widget.configuration.screenWidth / 20),
          child: Center(
            child: CircularProgressIndicator(),
          ));
    else if (queryResult.length == 0 || queryResult == null)
      return Padding(
        padding: EdgeInsets.only(top: widget.configuration.screenWidth / 40),
        child: Text("No result found for \"$query\""),
      );
    else
      return UsersListView(
        configuration: widget.configuration,
        query: queryResult,
      );
  }

  Widget showChatListWidget() {
    return Text("userIsNotSearching");
  }

  Future<List> getUsers() async {
    return await searchUsers(context, query, widget.configuration);
  }
}
