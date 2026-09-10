import 'dart:convert';
import 'dart:io';

/// Pipeline de conteúdo (idempotente). Para cada categoria do index:
///   final = shuffle( combos[id]  +  originais[id] ), deduplicado.
///
/// Fontes (nunca lê o resultado como entrada, então pode rodar quantas vezes
/// quiser sem duplicar):
///   - tool/frases_combos/<id>.json  (snapshot dos combos "ideia + arremate")
///   - tool/frases_orig/<id>.json    (frases ORIGINAIS curadas — cresce por lote)
/// Saída:
///   - assets/frases/<id>.json       (o que o app carrega)
///
/// O embaralhamento é DETERMINÍSTICO (seed por id): mesma entrada => mesma
/// ordem, e aberturas iguais ficam espalhadas (some a sensação de "tudo igual").
///
/// Rode:  dart run tool/merge_frases.dart
const _origDirs = ['tool/frases_orig', 'tool/frases_orig2'];

void main() {
  final index = (json.decode(File('assets/frases/index.json').readAsStringSync())
          as List)
      .cast<Map<String, dynamic>>();

  var totalFinal = 0;
  var totalOrig = 0;
  for (final meta in index) {
    final id = meta['id'] as String;
    final combos = _read('tool/frases_combos/$id.json');
    // Originais podem vir de vários lotes (frases_orig, frases_orig2, ...).
    final orig = <String>[
      for (final dir in _origDirs) ..._read('$dir/$id.json'),
    ];
    totalOrig += orig.length;

    // Dedup preservando 1ª ocorrência (case/space-insensitive).
    final seen = <String>{};
    final merged = <String>[];
    for (final s in [...orig, ...combos]) {
      final t = s.trim();
      final k = t.toLowerCase();
      if (t.isEmpty || !seen.add(k)) continue;
      merged.add(t);
    }

    _shuffle(merged, _seed(id));
    File('assets/frases/$id.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(merged));
    totalFinal += merged.length;
    stdout.writeln(
        '$id: ${combos.length} combos + ${orig.length} orig => ${merged.length}');
  }
  stdout.writeln('---');
  stdout.writeln('TOTAL: $totalFinal frases (${totalOrig} originais).');
}

List<String> _read(String path) {
  final f = File(path);
  if (!f.existsSync()) return const [];
  return (json.decode(f.readAsStringSync()) as List).cast<String>();
}

int _seed(String s) {
  var h = 2166136261;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  return h;
}

/// Fisher-Yates com LCG (determinístico).
void _shuffle(List<String> list, int seed) {
  var s = seed & 0xFFFFFFFF;
  int next() {
    s = (s * 1664525 + 1013904223) & 0xFFFFFFFF;
    return s;
  }

  for (var i = list.length - 1; i > 0; i--) {
    final j = next() % (i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
}
