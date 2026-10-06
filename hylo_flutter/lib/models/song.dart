// Song model — ported from Hylo/Song.swift
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String? coverArtId;
  bool isLiked;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.coverArtId,
    this.isLiked = false,
  });

  /// Map from Subsonic API song object (shared shape used by album tracks,
  /// playlist entries, and search results).
  factory Song.fromSubsonic(Map<String, dynamic> json) {
    final rawDuration = json['duration'];
    final seconds = rawDuration is int
        ? rawDuration
        : int.tryParse(rawDuration?.toString() ?? '0') ?? 0;
    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      album: json['album']?.toString() ?? 'Unknown Album',
      duration: _formatDuration(seconds),
      coverArtId: json['coverArt']?.toString(),
      isLiked: json['starred'] != null,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      album: json['album']?.toString() ?? 'Unknown Album',
      duration: json['duration']?.toString() ?? '0:00',
      coverArtId: json['coverArtId']?.toString(),
      isLiked: json['isLiked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'duration': duration,
        'coverArtId': coverArtId,
        'isLiked': isLiked,
      };

  static String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Song copyWith({bool? isLiked}) => Song(
        id: id,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        coverArtId: coverArtId,
        isLiked: isLiked ?? this.isLiked,
      );
}
