import 'dart:async' as async;
import 'dart:html' as dom;
import 'dart:web_audio' as audio;
import 'dart:math' as math;
import 'dart:typed_data' as typed;

import 'package:observe/observe.dart';
import 'package:observe/mirrors_used.dart'; // for smaller code
import 'package:uuid/uuid_client.dart';

import 'package:wave/wave.dart' as wave;

var uuid = new Uuid();

printInputBuffer(audio.AudioBuffer b) {
  print("duration: ${b.duration}\n");
  print("length: ${b.length}\n");
  print("numberOfChannels: ${b.numberOfChannels}\n");
}

var bufferSize = 2048;

/*
 *
 * new -> initialize() -> ( start <-> pause ) -> stop() -> GC
 *
 */
class SoundRecorder {
  var context;
  dom.MediaStream stream;
  audio.MediaStreamAudioSourceNode source;
  audio.ChannelSplitterNode splitter;
  audio.ScriptProcessorNode recorder;
  audio.MediaStreamAudioDestinationNode drain;

  int bufferIndex = 0;
  var buffers = [];

  get onNewFrame {
    return onNewFrameSc.stream;
  }
  var onNewFrameSc = new async.StreamController();

  SoundRecorder(this.context);

  async.Future askPermission() {
    var completer = new async.Completer();
    dom.window.navigator.getUserMedia(audio: true).then( (dom.MediaStream stream) {
      this.stream = stream;
      source = context.createMediaStreamSource(stream);
      completer.complete();
    },
    onError: (_) {
      completer.completeError(null);
    });
    return completer.future;
  }
  initialize() {
    splitter = context.createChannelSplitter(source.channelCount);
    recorder = context.createScriptProcessor(bufferSize, 1, 1);
    drain = context.createMediaStreamDestination();
    recorder.onAudioProcess.listen((audio.AudioProcessingEvent e) {
      //var output = e.outputBuffer.getChannelData(0);
      //output.setAll(0, e.inputBuffer.getChannelData(0));

      printInputBuffer(e.inputBuffer);

      var buffer = new typed.Float32List.fromList(e.inputBuffer.getChannelData(0));
      if (bufferIndex < buffers.length) {
        buffers[bufferIndex] = buffer;
      } else {
        buffers.add(buffer);
      }
      bufferIndex++;
      onNewFrameSc.add((bufferIndex * bufferSize) / context.sampleRate);
    });

    source.connectNode(splitter);

    for (var i = 0; i < source.channelCount; i++) {
      splitter.connectNode(recorder, i, 0);
    }
  }

  start() {
    recorder.connectNode(drain);
  }
  pause() {
    recorder.disconnect(0);
  }
  stop() {
    pause();
    stream.stop();
  }
  audio.AudioBuffer render() {
    var length = buffers.length;
    if (length == 0) {
      return context.createBuffer(1, bufferSize, context.sampleRate);
    }

    audio.AudioBuffer buffer = context.createBuffer(1, bufferSize * length, context.sampleRate);
    var data = buffer.getChannelData(0);

//      var fake = new List<double>(bufferSize);
//      for(var i = 0; i < bufferSize; i++) {
//        fake[i] = (math.sin(i));
//      }

    for(var i = 0; i < length; i++) {
      data.setRange(bufferSize*i, bufferSize*(i+1), buffers[i]);
      //print(soundRecorder.buffers[i]);
    }
    return buffer;
  }

  dom.Blob encodeWave() {
    return new dom.Blob([wave.fromAudioBuffer(render())], 'audio/wav');
  }

  setPosition(Duration position) {
    bufferIndex = (position.inSeconds * context.sampleRate) ~/ bufferSize;
  }

}

class SoundEditorUI {
  dom.Element element;
  dom.Element loader;
  dom.Element loadProgress;
  dom.Element playProgress;
  dom.Element recordButton;
  dom.Element pauseButton;
  dom.Element playButton;
  dom.Element rewindButton;

  bool enabled = false;
  var soundRecorder;

  SoundEditorUI(this.element, {Duration recordingLength}) {
    loader = element.querySelector('.loader');
    loadProgress = element.querySelector('.load-progress');
    playProgress = element.querySelector('.play-progress');
    recordButton = element.querySelector('.controls .record');
    pauseButton = element.querySelector('.controls .pause');
    rewindButton = element.querySelector('.controls .rewind');
    playButton = element.querySelector('.controls .play');
  }

  loadPercentage(num p) {
    int width = (p*loader.clientWidth).toInt();
    loadProgress.style.width = "${width}px";
  }
  playPercentage(num p) {
    int width = (p*loader.clientWidth).toInt();
    playProgress.style.width = "${width}px";
  }
  setPosition(Duration position) {
    playPercentage(position.inSeconds/60);
  }


}

abstract class SoundEditorState {
  SoundEditor that;

  SoundEditorState(this.that);

  transition(newState) {
    that.state = newState;
    that.state.enter();
  }

  enter(){} //noop
  exit(){} //noop

  record();
  play();
  rewind(Duration position);
}

class SoundEditorRecording extends SoundEditorState {
  SoundEditorRecording(that) : super(that);

  record() {
    exit();
    transition(that.IdleState);
  }
  play() {
    exit();
    transition(that.IdleState);
  }
  rewind(Duration position) {
    exit();
    that.position = position;
    that.soundRecorder.setPosition(position);
    //that.ui.setPosition(position);
    transition(that.IdleState);
  }

  enter() {
    that.soundRecorder.start();
  }
  exit() {
    that.soundRecorder.pause();
  }
}

class SoundEditorPlaying extends SoundEditorState {
  SoundEditorPlaying(that) : super(that);
  record() {
    exit();
    transition(that.RecordingState);
  }
  play() {
    exit();
    transition(that.IdleState);
  }
  rewind(Duration position) {
    if(position.inMicroseconds == 0) {
      exit();
    }
    that.position = position;
    that.soundRecorder.setPosition(position);
    //that.ui.setPosition(position);
    if(position.inMicroseconds == 0) {
      this.transition(that.IdleState);
    }
  }

  enter() {
    that.soundPlayer.play(that.soundRecorder.render(), that.position);
  }
  exit() {
    that.position += that.soundPlayer.durationPlayed();
    //that.ui.setPosition(that.position);
    that.soundPlayer.pause();
  }
}

class SoundEditorIdle extends SoundEditorState {
  SoundEditorIdle(that) : super(that);
  record() {
    exit();
    transition(that.RecordingState);
  }
  play() {
    exit();
    transition(that.PlayingState);
  }
  rewind(Duration position) {
    that.setPosition(position);
    //that.ui.setPosition(position);
  }
}

class SoundPlayer {
  audio.AudioContext context;
  var onEndedCallback;
  async.Timer timer; //workaround the broken onEnded event
  num startTime; // to update position. FIXME: Need to keep updating _during_ playback
  audio.AudioBufferSourceNode node;
  SoundPlayer(this.context, {this.onEndedCallback});
  Duration lastBufferPlayTime;
  play(audio.AudioBuffer buffer, Duration offset) {
    lastBufferPlayTime = new Duration(microseconds: (buffer.duration * Duration.MICROSECONDS_PER_SECOND).toInt()) - offset;
    node = context.createBufferSource();
    node.connectNode(context.destination);
    node.buffer = buffer;

    // WORKAROUND:
    var duration = new Duration(microseconds:
      (buffer.length/buffer.sampleRate*Duration.MICROSECONDS_PER_SECOND).toInt()) - offset;
    timer = new async.Timer(duration, (){
      onEndedCallback();
    });
//    node.onEnded.listen((_) {
//      onEnded();
//      node.disconnect(0);
//    });

    node.start(0, offset.inMicroseconds/Duration.MICROSECONDS_PER_SECOND);
    startTime = context.currentTime;
  }
  pause() {
    timer.cancel();
    node.stop(0);
  }
  Duration durationPlayed() {
    if (timer.isActive) {
      var currentTime = context.currentTime;
      return new Duration(microseconds: ((currentTime - startTime) * Duration.MICROSECONDS_PER_SECOND).toInt());
    } else {
      return lastBufferPlayTime;
    }
  }
}

class SoundEditor extends Observable {
  var RecordingState;
  var PlayingState;
  var IdleState;

  var context = new audio.AudioContext();


  SoundEditorUI ui;
  SoundRecorder soundRecorder;
  SoundPlayer soundPlayer;

  SoundEditorState state;

  @observable
    Duration position = new Duration();

  SoundEditor(this.ui) {
    RecordingState = new SoundEditorRecording(this);
    PlayingState = new SoundEditorPlaying(this);
    IdleState = new SoundEditorIdle(this);

    state = IdleState;

    soundRecorder = new SoundRecorder(context);
    soundPlayer = new SoundPlayer(context, onEndedCallback: () {
      state.exit();
      state.transition(IdleState);
    });
  }

  initialize() {
    onPropertyChange(this, #position, () {
      ui.setPosition(position);
      //print("onPropertyChange\n");
    });
    soundRecorder.askPermission().then((_) {
        soundRecorder.initialize();
        ui.recordButton.onClick.listen((_)=>record());
        ui.playButton.onClick.listen((_)=>play());
        ui.rewindButton.onClick.listen((_)=>rewind(new Duration()));

        soundRecorder.onNewFrame.listen((time) {
          position = new Duration(microseconds: (time*Duration.MICROSECONDS_PER_SECOND).toInt());
          //ui.setPosition(position);
        });
      },
      onError: (_) {
        dom.window.alert('Klikni že Ano, jinak nebude nic!');
      });
  }

  record() => state.record();
  play() => state.play();
  rewind(Duration position) => state.rewind(position);

  setPosition(Duration position) {
    this.position = position;
    soundRecorder.setPosition(position);
  }
}

upload(SoundEditor soundEditor, onUploadProgress) {
  var questionarieName = dom.document.querySelector('#exerciseName').text;
  var fileName = uuid.v5(Uuid.NAMESPACE_NIL, questionarieName) + '.wav';

  var fileBlob = soundEditor.soundRecorder.encodeWave();
  uploadAudio(fileName, fileBlob, onUploadProgress);
}

main() {
  var soundEditor = new SoundEditor(new SoundEditorUI(dom.document.querySelector('#recorder')));
  dom.document.querySelector('#enable').onClick.first.then((_) {
    soundEditor.initialize();

    dom.ButtonElement uploadButton = dom.document.querySelector('#upload-button');
    dom.ParagraphElement uploadProgress = dom.document.querySelector('#upload-progress');
    uploadButton.onClick.listen((_) => upload(soundEditor, (dom.ProgressEvent p) {
      uploadProgress.innerHtml = "${p.loaded}/${p.total}";
    }));
  });

  var progressBar = new ProgressBar(dom.document.querySelector('#progress'));
  progressBar.initialize('pes.wav', 44);

  //soundRecorder.start();
}

///http://www.sitepoint.com/html5-javascript-file-upload-progress-bar/
class ProgressBar {
  dom.Element root;
  dom.Element root_progress;
  ProgressBar(this.root) {
    root_progress = new dom.ParagraphElement();
    root.append(root_progress);
  }
  initialize(fileName, remainingPercentage) {
    root_progress.setInnerHtml('upload ${fileName}');
    setProgress(remainingPercentage);
  }
  setProgress(num remainingPercentage) {
    root_progress.style.backgroundPositionX = "${remainingPercentage}%";
  }
}


/**
 *
 * is_upload_file.dart
 *
 **/

// requires Chromium logged to https://is.muni.cz/auth started with --disable-web-security flag

async.Future<String> uploadAudio(fileName, fileBlob, onUploadProgress) {
  var formUrl = 'https://is.muni.cz/auth/dok/rfmgr.pl';
  var targetDirectory = "/el/1441/jaro2014/ONLINE_A/ode/49089695/";
  var csrfToken = "isNotChecked";

  var description = '';
  var newFileName = '';
  var options = 'er';

  return uploadFile(formUrl, targetDirectory, csrfToken, fileBlob, fileName, description, newFileName, options, onUploadProgress);
}


async.Future<dom.HttpRequest> requestUpload(String url, {String method,
  bool withCredentials, String responseType, String
  mimeType, Map<String, String> requestHeaders,
  dynamic sendData, void onProgress(ProgressEvent),
  void onUploadProgress(ProgressEvent)}) {

  var completer = new async.Completer<dom.HttpRequest>();

  var xhr = new dom.HttpRequest();
  if (method == null) {
    method = 'GET';
  }
  xhr.open(method, url, async: true);

  if (withCredentials != null) {
    xhr.withCredentials = withCredentials;
  }

  if (responseType != null) {
    xhr.responseType = responseType;
  }

  if (mimeType != null) {
    xhr.overrideMimeType(mimeType);
  }

  if (requestHeaders != null) {
    requestHeaders.forEach((header, value) {
      xhr.setRequestHeader(header, value);
    });
  }

  if (onProgress != null) {
    xhr.onProgress.listen(onProgress);
  }

  //////////////////////////////
  if (onUploadProgress != null) {
    xhr.upload.onProgress.listen(onUploadProgress);
  }
  //////////////////////////////

  xhr.onLoad.listen((e) {
    // Note: file:// URIs have status of 0.
    if ((xhr.status >= 200 && xhr.status < 300) ||
        xhr.status == 0 || xhr.status == 304) {
      completer.complete(xhr);
    } else {
      completer.completeError(e);
    }
  });

  xhr.onError.listen(completer.completeError);

  if (sendData != null) {
    xhr.send(sendData);
  } else {
    xhr.send();
  }

  return completer.future;
}


// see https://github.com/jirkadanek/SendGrades/blob/master/src/main/java/cz/dnk/UpdateGrades/FileAction.java

/*
 *
 * returns Future csrfToken
 */
async.Future<String> getUploadForm(formUrl, targetDirectory) {
  var csrfToken = 'isNotChecked';
  var completer = new async.Completer<String>();
  Map data = {
    "use" : "fmgrfo",
    "so" : "pd",
    "op" : "vlso",
    "furl2" : "",
    "ch2" : "",
    "furlf" : targetDirectory,
    "submit" : "Použít"
  };
  dom.HttpRequest.postFormData(formUrl, data).then((dom.HttpRequest r) {
    //print(r.response);
    completer.complete(csrfToken);
  },
  onError: (e) {
    print('error');
    completer.completeError(e);
  });
  return completer.future;
}

// returns Future filename
async.Future<String> uploadFile(String formUrl, String targetDirectory, String csrfToken, dom.Blob fileBlob, fileName, String description, String newFileName, String options, dynamic onUploadProgress) {
  var completer = new async.Completer<String>();
  var data = new dom.FormData();
  var _ = {
    "op" : "vlso",
     "furl" : targetDirectory,
     "so" : "pd",
     "info" : "1",
     "_" : csrfToken,
     "furl2" : "",
     "NAZEV_1" : fileName,
     "POPIS_1" : description,
     "NJMENO_1" : newFileName,
     "OPT" : options,
     "proved" : "Zavést"
    }..forEach((name, value) {
      data.append(name, value);
    });
    data.appendBlob("FILE_1", fileBlob, fileName);

  requestUpload(formUrl, method: 'POST', onUploadProgress: onUploadProgress, sendData: data).then((dom.HttpRequest r) {
    //TODO: check the response and see if it is true
    var actualFileName = fileName;
    completer.complete(actualFileName);
  },
  onError: (err) {
    completer.completeError(err);
  });
  return completer.future;
}