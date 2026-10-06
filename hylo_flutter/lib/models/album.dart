// Album model — ported from Hylo/Models.swift (Album struct)
class Album {
  final String id;
  final String name;
  final String? artist;
  final String? coverArt;
  final int? songCount;

  const Album({
    required this.id,
    required this.name,
    this.artist,
    this.coverArt,
    this.songCount,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    final rawSongCount = json['songCount'];
    return Album(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Album',
      artist: json['artist']?.toString(),
      coverArt: json['coverArt']?.toString(),
      songCount: rawSongCount is int
          ? rawSongCount
          : int.tryParse(rawSongCount?.toString() ?? ''),
    );
  }
}
