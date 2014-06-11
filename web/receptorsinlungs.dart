import 'dart:html';
import 'dart:math' as math;

void main() {
  // find elements
  var page = querySelector("body");
  var stop = querySelector("#stop");
  AudioElement player = querySelector("#player");
  
  // enable docs
  querySelectorAll(".unavailable.dart").forEach((i){ // we have this script
    i.classes.remove("unavailable");
  });
  player.onPlay.listen((e){
    if(player.seekable.length > 0) {
      querySelectorAll(".unavailable.seek").forEach((i){ // we can seek
        i.classes.remove("unavailable");
      });
    }
  });
  
  // config
  final num rewindAmount = 8;
  final String canhasspace = "canhasspace";
  
  //enable stop button
  stop.onClick.listen((e) {
    player.load();
    player.pause();
  });
  
  //enable shortcuts  
  page.onKeyDown.listen((KeyboardEvent e){
    switch(e.keyCode) {
      case KeyCode.SPACE:
        if (document.activeElement.parent.classes.contains(canhasspace)) {  // allow writing space
          return;
        }
        e.preventDefault();
        e.stopPropagation();
        if (e.shiftKey) { // rewind
          player.currentTime = math.max(0, player.currentTime - rewindAmount);
          player.play();
          return;
        }
        if (player.paused) {  // play/pause
          player.play();
        } else {
          player.pause();
        }
        break;
    }
  });
}