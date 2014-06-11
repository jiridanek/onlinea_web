import "dart:html" as dom;

main() {
  for(dom.AudioElement e in dom.querySelectorAll('audio')) {
    e.onEnded.listen((_) {
      e.load();
    });
  }
}