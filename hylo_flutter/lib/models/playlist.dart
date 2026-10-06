// Playlist model — ported from Hylo/Models.swift (Playlist struct)
class Playlist {
  final String id;
  final String name;
  final int songCount;
  final String? coverArt;

  const Playlist({
    required this.id,
    required this.name,
    required this.songCount,
    this.coverArt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawCount = json['songCount'];
    return Playlist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Playlist',
      songCount: rawCount is int
          ? rawCount
          : int.tryParse(rawCount?.toString() ?? '0') ?? 0,
      coverArt: json['coverArt']?.toString(),
    );
  }
}
