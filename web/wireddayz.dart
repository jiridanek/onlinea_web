import 'dart:html' as dom;
import 'dart:convert' as convert;

import 'dart:collection' as collection;

class V {
  var question = false;
  var text = '';
  var options = '';
  V(html) {
    parse(html);
  }
  parse(String text) {
    options = '';
    var j = 'a';
      var newtext = text.replaceAllMapped(new RegExp(r'\[([^\]]*)\]'), (Match m) {
        this.question = true;
        var rightWrong = m.group(1).split('||');
        if (rightWrong.length != 2) {
          throw ('wrong format ${m.group(1)}');
        }
        var right = rightWrong[0].split('|');
        var wrong = rightWrong[1].split('|');
        var i = 1;
        for (String r in right) {
          options += '\n:v${i}${j}="${r.trim()}" ok';
          i++;
        }
        for (var w in wrong) {
          options += '\n:v${i}${j}="${w.trim()}"';
          i++;
        }
        var symb = ' :v1${j} ';
        j = convert.UTF8.decode([convert.UTF8.encode(j)[0] + 1]);
        return symb;
      });
      this.text = newtext;
  }
}

rewrite(dom.Element element) {
  for (dom.Element e in element.children) {
    var a = [];
    e.attributes.forEach((k, v) => a.add('$k="$v"'));
    var v = new V(e.innerHtml.replaceAll(new RegExp('\n *'), ' ').trim());
    var prefix = (v.question) ? '':'++';
    print(prefix + '<${e.tagName} ${a.join(" ")}>');
    print(v.text);
    print('</${e.tagName}>');
    print(v.options);
    print('--');
  }
}

_streamSubtree(sc, dom.Element e) {
  sc.add(e);
  if (e.hasChildNodes()) {
    for(dom.Element c in e.children) {
      _streamSubtree(sc, c);
    }
  }
}

List<dom.Element> streamSubtree(dom.Element e) {
  List l = [];
  _streamSubtree(l, e);
  return l;
}

main() {
  var clipAction = dom.querySelector('#clipboard');
  clipAction.onClick.listen((e) {
    dom.Element article = dom.querySelector('article');

    dom.Element container = article.querySelector('#container');
    var clone = article.clone(true);
    rewrite(container);
  });


}