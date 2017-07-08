import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // for firebase login with Google
import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';


final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.pink,
  primaryColor: Colors.pink,
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.pink,
  accentColor: Colors.pink,
);

final googleSignIn = new GoogleSignIn();
final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final reference = FirebaseDatabase.instance.reference().child('messages');

void main() {
  runApp(new ChouettesListesApp());
}

Future<Null> _ensureLoggedIn() async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null)
    user = await googleSignIn.signInSilently();
  if (user == null) {
    user = await googleSignIn.signIn();
    analytics.logLogin();
  }
  if (auth.currentUser == null) {
    GoogleSignInAuthentication credentials =
    await googleSignIn.currentUser.authentication;
    await auth.signInWithGoogle(
      idToken: credentials.idToken,
      accessToken: credentials.accessToken,
    );
  }
}

class ChouettesListesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Chouettes Listes",
      theme: defaultTargetPlatform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      home: new ChatScreen(),
    );
  }
}


@override
class ChatMessage extends StatelessWidget {
  ChatMessage({this.snapshot, this.animation});

  final DataSnapshot snapshot;
  final Animation animation;


  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
          parent: animation, curve: Curves.bounceIn),
      axisAlignment: 0.0,
      child: new Container(
        //margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: new EdgeInsets.only(left: 32.0, top: 8.0, bottom: 8.0, right: 16.0),
        decoration: new BoxDecoration(
          //set the product backgrounds with alternative colors
          //color: index modulo 2 == 0 ? Colors.grey[300] : Colors.grey[100],
          color: Colors.grey[300],
        ),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: <Widget>[
            new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Container(
                  margin: const EdgeInsets.only(top: 0.0),
                  child: new Text(
                    snapshot.value['text'],
                  ),
                ),
                new Divider(height: 2.0, color: Colors.grey,),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          //title: new Text('Liste "Quotidienne"'),
          title: new Row(
              children: [
                new Expanded(
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      new Container(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: new Text(
                          'Liste quotidienne',
                          style: new TextStyle(
                            //fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      new Text(
                        '21 Produits',
                        style: new TextStyle(
                          fontSize: 12.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                new Column(
                  children: <Widget>[
                    new Text(
                        '31.00€',
                        style: new TextStyle(
                          //fontSize: 32.0,
                          color: Colors.white,
                        )
                    ),
                    new Text(
                        'estimation',
                        style: new TextStyle(
                          fontSize: 12.0,
                          color: Colors.white,

                        )
                    ),
                  ],
                ),
              ]

          ),
          backgroundColor: Colors.pink[500],

        ),
        body: new Column(children: <Widget>[
          new Flexible(
            child: new FirebaseAnimatedList(
              query: reference,
              sort: (a, b) => b.key.compareTo(a.key),
              padding: new EdgeInsets.all(0.0),
              reverse: false,
              itemBuilder: (_, DataSnapshot snapshot,
                  Animation<double> animation) {
                return new ChatMessage(
                    snapshot: snapshot,
                    animation: animation
                );
              },
            ),
          ),
          new Divider(height: 1.0),
          new Container(
            decoration:
            new BoxDecoration(color: Theme
                .of(context)
                .cardColor),
            child: _buildTextComposer(),
          ),
        ]));
  }

  Widget _buildTextComposer() {
    return new Container(
      //no left&right margins
      padding: const EdgeInsets.only(
          top: 10.0, bottom: 10.0, left: 32.0, right: 32.0),
      decoration: new BoxDecoration(
        gradient: new LinearGradient(
          //begin: FractionalOffset.topLeft,
          //end: FractionalOffset.bottomRight,
          begin: const FractionalOffset(0.5, 0.0),
          end: const FractionalOffset(0.5, 0.8),
          colors: <Color>[const Color(0xccffffff), const Color(0xffffffff)],
        ),
      ),
      child: new Row(
          children: <Widget>[
            new Flexible(
              child: new Container(
                margin: const EdgeInsets.symmetric(horizontal: 6.0),
                padding: const EdgeInsets.symmetric(
                    vertical: 14.0, horizontal: 5.0),
                decoration: new BoxDecoration(
                    borderRadius: new BorderRadius.circular(6.0),
                    color: Colors.grey[300]
                ),
                child: new TextField(
                  controller: _textController,
                  onChanged: (String text)  {
                    setState(() {
                      _isComposing = text.length > 0;
                    });
                  },
                  onSubmitted: _handleSubmitted,
                  decoration: new InputDecoration.collapsed(
                      hintText: "Ajouter un article"),
                ),
              ),
            ),

            new Container(
                margin: new EdgeInsets.symmetric(horizontal: 6.0),
                //padding: new EdgeInsets.all(5.0),
                decoration: new BoxDecoration(
                    borderRadius: new BorderRadius.circular(6.0),
                    color: Colors.pink[500]
                ),
                child: new IconButton(
                  icon: new Icon(Icons.add, color: Colors.white),
                  color: Colors.white,
                  onPressed: _isComposing
                      ? () => _handleSubmitted(_textController.text)
                      : null,
                )),
          ]
      ),
    );
  }

  Future<Null> _handleSubmitted(String text) async {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    await _ensureLoggedIn();
    _sendMessage(text: text);
  }

  void _sendMessage({ String text }) {
    reference.push().set({
      'text': text,
      'senderName': googleSignIn.currentUser.displayName,
    });
    analytics.logEvent(name: 'send_message');
  }

}
/*
void main() {
  runApp(new FriendlychatApp());
}

final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

final googleSignIn = new GoogleSignIn();



const String _name = "Michel et Augustin";

Future<Null> _ensureLoggedIn() async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null)
    user = await googleSignIn.signInSilently();
  if (user == null) {
    await googleSignIn.signIn();
  }
}



class FriendlychatApp extends StatelessWidget {
 @override
 Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Friendlychat",
      theme: defaultTargetPlatform == TargetPlatform.iOS
        ? kIOSTheme
        : kDefaultTheme,
      home: new ChatScreen(),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({this.text, this.animation});
  final String text;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(parent: animation, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: new GoogleUserCircleAvatar(googleSignIn.currentUser.photoUrl),
            ),
            new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text(googleSignIn.currentUser.displayName,  // modified
                    style: Theme.of(context).textTheme.subhead),
                new Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: new Text(text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;

  Future<Null> _handleSubmitted(String text) async {         //modified
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    await _ensureLoggedIn();                                       //new
    _sendMessage(text: text);                                      //new
  }

  void _sendMessage({ String text }) {
    ChatMessage message = new ChatMessage(
      text: text,
      animationController: new AnimationController(
        duration: new Duration(milliseconds: 700),
        vsync: this,
      ),
    );
    setState(() {
      _messages.insert(0, message);
    });
    message.animationController.forward();
  }

  void dispose() {
    for (ChatMessage message in _messages)
      message.animationController.dispose();
    super.dispose();
  }

  Widget _buildTextComposer() {
   return new IconTheme(
     data: new IconThemeData(color: Theme.of(context).accentColor),
       child: new Container(
         margin: const EdgeInsets.symmetric(horizontal: 8.0),
         child: new Row(
            children: <Widget>[
              new Flexible(
                child: new TextField(
                  controller: _textController,
                  onChanged: (String text)  {
                    setState(() {
                      _isComposing = text.length > 0;
                    });
                  },
                  onSubmitted: _handleSubmitted,
                  decoration: new InputDecoration.collapsed(
                  hintText: "Send a message"),
                ),
              ),
              new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS ?
                new CupertinoButton(
                  child: new Text("Send"),
                  onPressed: _isComposing
                      ? () =>  _handleSubmitted(_textController.text)
                      : null,) :
                new IconButton(
                    icon: new Icon(Icons.send),
                    onPressed: _isComposing ?
                        () =>  _handleSubmitted(_textController.text) : null,
                    )
                ),
           ]
         )
       )
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Friendlychat"),
        elevation:
            Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0
      ),
      body: new Container(
        child: new Column(
          children: <Widget>[
          new Flexible(
            child: new ListView.builder(
              padding: new EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            )
          ),
          new Divider(height: 1.0),
          new Container(
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
         ]
       ),
       decoration: Theme.of(context).platform == TargetPlatform.iOS ? new BoxDecoration(border: new Border(top: new BorderSide(color: Colors.grey[200]))) : null),
   );
  }

  Future<Null> _ensureLoggedIn() async {
    GoogleSignInAccount user = googleSignIn.currentUser;
    if (user == null)
      user = await googleSignIn.signInSilently();
    if (user == null) {
      await googleSignIn.signIn();
    }
  }


}
*/


//Widget _buildTextComposer() {
//  return new IconTheme(
//    data: new IconThemeData(color: Theme
//        .of(context)
//        .accentColor),
//    child: new Container(
//        margin: const EdgeInsets.symmetric(horizontal: 8.0),
//        padding: const EdgeInsets.symmetric(
//            vertical: 14.0, horizontal: 5.0),
//
//        child: new Row(children: <Widget>[
//          new Flexible(
//            child: new TextField(
//              controller: _textController,
//              onChanged: (String text) {
//                setState(() {
//                  _isComposing = text.length > 0;
//                });
//              },
//              onSubmitted: _handleSubmitted,
//              decoration:
//              new InputDecoration.collapsed(hintText: "Ajouter un article"),
//            ),
//          ),
//          new Container(
//              margin: new EdgeInsets.symmetric(horizontal: 4.0),
//              child: Theme
//                  .of(context)
//                  .platform == TargetPlatform.iOS
//                  ? new CupertinoButton(
//                child: new Icon(Icons.add),
//                onPressed: _isComposing
//                    ? () => _handleSubmitted(_textController.text)
//                    : null,
//              )
//                  : new IconButton(
//                icon: new Icon(Icons.add),
//                onPressed: _isComposing
//                    ? () => _handleSubmitted(_textController.text)
//                    : null,
//              )),
//        ]),
//        decoration: Theme
//            .of(context)
//            .platform == TargetPlatform.iOS
//            ? new BoxDecoration(
//            border:
//            new Border(top: new BorderSide(color: Colors.grey[200])))
//            : null),
//  );
//}