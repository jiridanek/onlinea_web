import 'dart:web_audio' as audio;
import 'dart:html' as dom;
import 'dart:math' as math;

import 'package:observe/observe.dart';
import 'package:observe/mirrors_used.dart'; // for smaller code

onended() {
  var context = new audio.AudioContext();

  var length = context.sampleRate.toInt();
  audio.AudioBuffer buffer = context.createBuffer(1, length, context.sampleRate);
  var data = buffer.getChannelData(0);
  for(var i = 0; i < length; i++) {
    data[i] = (math.sin(i));
  }

  var source = context.createBufferSource();
  source.buffer = buffer;
  source.onEnded.listen((e) {
    print(e);
  });
  source.connectNode(context.destination);
  source.start(0);
}

class Monster extends Observable {
  @observable int health = 100;
}

main() {
  var display = dom.querySelector('#text');

  var m = new Monster();

//  observe.onPropertyChange(s, #test, () {
//    print("baf");
//  });

  m.changes.listen((List<ChangeRecord> l) {
    for (var r in l) {
      print(r);
    }
  });

  m.health = 20;
}