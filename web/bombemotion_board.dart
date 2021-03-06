import 'dart:html';
import 'dart:async';
import 'dart:math';
import 'package:polymer/polymer.dart';
import 'package:forcetictactoe/shared.dart';
import 'package:firebase/firebase.dart' show Firebase;

import 'package:stagexl/stagexl.dart' as StageXL;

/**
 * The Bombemotion Board component
 */
@CustomTag('bombemotion-board')
class BombemotionBoard extends PolymerElement with Client {
  @observable User user;

  @observable List<User> leaderBoard = toObservable([]);

  @observable List<User> topList = toObservable([]);

  @observable List<User> startChallengeUsers = toObservable([]);

  @observable String winnerTime;

  @observable String challengeTime = '';

  @observable String startChallengeStatus = '';

  @observable String startChallengeBtnLabel = 'Start';

  @observable String errorMessage = '';

  @observable bool challengeOngoing = false;
  @observable num counter = 0;

  bool bomb = false;

  CanvasElement canvas;

  BombemotionBoard.created() : super.created() {
    onConnect("anonymous");
  }

  Random random = new Random();
  StageXL.Stage stage;
  StageXL.RenderLoop renderLoop;
  StageXL.ResourceManager resourceManager;

  @override
  void domReady() {
    var navicon = $['navicon'];
    var drawerPanel = $['drawerPanel'];

    navicon.onClick.listen((e) => drawerPanel.togglePanel());
  }

  void userChanged(User oldValue, User newValue) {
    playName = newValue.name;
    sendProfile();
    _connect();
    _connectFirebase();
  }

  void _connect() {
    canvas = this.shadowRoot.querySelector('#stage');
    stage = new StageXL.Stage(canvas, webGL: true, width: 800, height: 600);
    stage.scaleMode = StageXL.StageScaleMode.SHOW_ALL;
    stage.align = StageXL.StageAlign.NONE;

    renderLoop = new StageXL.RenderLoop();
    renderLoop.addStage(stage);

    resourceManager = new StageXL.ResourceManager()
      ..addTextureAtlas("dartbird", "img/dart-bird-sprite.json",
          StageXL.TextureAtlasFormat.JSONARRAY)
      ..addTextureAtlas(
          "bomb", "img/dartbirdbomb.json", StageXL.TextureAtlasFormat.JSONARRAY)
      ..load().then((result) => freeBird());
  }

  void _connectFirebase() {
    var fb = new Firebase('${firebaseUrl}/toplist');
    print("Firebase");
    fb.onValue.listen((event) {
      List users = event.snapshot.val();
      if (users != null) topList =
          users.map((u) => new User.fromMap(u)).toList();
      leaderBoard = topList;
      for (User user in leaderBoard) {
        print(user.name);
      }
    });
  }

  void showAbout() {
    async((_) => $['about_dialog'].toggle());
  }

  /// Returns the player info for the [side] ('Black' or 'White')
  String getPlayerInfo(String side) {
    // if (_chessBoard == null) {
    //  return '';
    // }
    var name = "prova"; //_chessBoard.header[side];
    if (name == null) {
      return '';
    }
    var rating = "180"; //_chessBoard.header[side + 'Elo'];
    if (rating != null) {
      return '${name} (${rating})';
    }
    return name;
  }

  bombed() {
    count = 0;
    bomb = true;
  }

  saved() {
    hasBomb = false;
    bomb = false;
  }

  die() {
    stage.mouseChildren = false;
    stage.juggler.clear();
    stage.removeChildren();

    var textField = new StageXL.TextField();
    textField.defaultTextFormat = new StageXL.TextFormat(
        "Arial", 36, StageXL.Color.Black,
        align: StageXL.TextFormatAlign.CENTER);
    textField.width = 400;
    textField.x = stage.contentRectangle.center.x - 200;
    textField.y = stage.contentRectangle.center.y - 20;
    textField.text = "Game OVER!";
    textField.addTo(stage);
  }

  survive() {
    stage.mouseChildren = false;
    stage.juggler.clear();
    stage.removeChildren();

    var textField = new StageXL.TextField();
    textField.defaultTextFormat = new StageXL.TextFormat(
        "Arial", 36, StageXL.Color.Black,
        align: StageXL.TextFormatAlign.CENTER);
    textField.width = 400;
    textField.x = stage.contentRectangle.center.x - 200;
    textField.y = stage.contentRectangle.center.y - 20;
    textField.text = "You Survived";
    textField.addTo(stage);
  }

  void throwBomb(StageXL.Event ev, StageXL.FlipBook fb) {
    launch();
    counter = count;
    bomb = true;
    fb.alpha = 0;
  }

  void freeBird() {
    var random = new Random();
    var scaling = 0.5 + 0.5 * random.nextDouble();

    //------------------------------------------------------------------
    // Get all the "walk" bitmapDatas from the texture atlas.
    //------------------------------------------------------------------

    var textureAtlasDart = resourceManager.getTextureAtlas("dartbird");
    var bitmapDatasDart = textureAtlasDart.getBitmapDatas("dart-bird");
    //------------------------------------------------------------------
    // Create a flip book with the list of bitmapDatas.
    //------------------------------------------------------------------

    var rect = stage.contentRectangle;
    var transition = StageXL.TransitionFunction.linear;

    var tween;
    var flipbook;

    if (bomb == true) {
      var textureAtlasBomb = resourceManager.getTextureAtlas("bomb");
      var bitmapDatasBomb = textureAtlasBomb.getBitmapDatas("dart-bird");
      //------------------------------------------------------------------
      // Create a flip book with the list of bitmapDatas.
      //------------------------------------------------------------------

      flipbook = new StageXL.FlipBook(bitmapDatasBomb, 30)
        ..x = rect.left - 128
        ..y = rect.top + (scaling - 0.5) * 2.0 * (rect.height - 260)
        ..scaleX = scaling
        ..scaleY = scaling
        ..addTo(stage)
        ..play();

      bomb = false;
      flipbook.onMouseClick.listen((ev) => throwBomb(ev, flipbook));
      flipbook.onTouchTap.listen((ev) => throwBomb(ev, flipbook));
      tween = new StageXL.Tween(
          flipbook, rect.width / 200.0 / scaling, transition)
        ..animate.x.to(rect.right)
        ..onComplete = () {
          stopAnimation(flipbook);
          if ( hasBomb == true ) {
            bomb = true;
          }
            
        };
    } else {
      flipbook = new StageXL.FlipBook(bitmapDatasDart, 50)
        ..x = rect.left - 128
        ..y = rect.top + (scaling - 0.5) * 2.0 * (rect.height - 260)
        ..scaleX = scaling
        ..scaleY = scaling
        ..addTo(stage)
        ..play();

      tween = new StageXL.Tween(
          flipbook, rect.width / 200.0 / scaling, transition)
        ..animate.x.to(rect.right)
        ..onComplete = () => stopAnimation(flipbook);
    }

    stage.sortChildren((c1, c2) {
      if (c1.y < c2.y) return -1;
      if (c1.y > c2.y) return 1;
      return 0;
    });

    stage.juggler
      ..add(flipbook)
      ..add(tween)
      ..delayCall(freeBird, 0.5);
  }

  void stopAnimation(StageXL.FlipBook flipbook) {
    stage.removeChild(flipbook);
    stage.juggler.remove(flipbook);
  }
}
