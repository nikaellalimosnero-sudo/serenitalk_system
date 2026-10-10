/// Community posts never show real names. Every user gets a stable, friendly
/// keeps the same alias across posts and comments, with nothing extra to store.
class CommunityAlias {
  static const _adjectives = [
    'quiet',
    'gentle',
    'calm',
    'brave',
    'kind',
    'soft',
    'steady',
    'warm',
    'bright',
    'patient',
    'hopeful',
    'mellow',
    'cozy',
    'humble',
    'serene',
    'tender',
  ];
  static const _nouns = [
    'river',
    'amber',
    'willow',
    'meadow',
    'ember',
    'harbor',
    'pebble',
    'cloud',
    'maple',
    'lantern',
    'breeze',
    'sparrow',
    'orchid',
    'forest',
    'comet',
    'tide',
  ];

  static String forUid(String uid) {
    var h = 0x811c9dc5;
    for (final c in uid.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    final adjective = _adjectives[h % 16];
    final noun = _nouns[(h ~/ 16) % 16];
    final number = 10 + (h ~/ 256) % 90;
    return '${adjective}_$noun$number';
  }
}
