import 'dart:html';

test_appendBlob () {
        var form = new FormData();
        var blob = new Blob(
            ['Indescribable... Indestructible! Nothing can stop it!'],
            'text/plain');
        form.appendBlob('theBlob', blob, 'theBlob.txt');
}

main() {
  print(FormData.supported);
  test_appendBlob();
}