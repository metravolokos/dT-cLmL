import 'dart:math';

import 'remote_track.dart';

enum PlayerRepeatMode { off, all, one }

/// A deterministic playback queue independent of the audio engine and UI.
class TrackQueue {
  TrackQueue(List<RemoteTrack> selection, int selectedIndex)
    : assert(selection.isNotEmpty),
      assert(selectedIndex >= 0 && selectedIndex < selection.length),
      _original = List.unmodifiable(selection),
      _currentIndex = selectedIndex {
    _order = List.of(_original);
  }

  final List<RemoteTrack> _original;
  late List<RemoteTrack> _order;
  int _currentIndex;
  bool _shuffled = false;
  PlayerRepeatMode repeatMode = PlayerRepeatMode.off;

  RemoteTrack get current => _order[_currentIndex];
  bool get shuffled => _shuffled;
  int get count => _order.length;

  /// Shuffle keeps the currently playing track and does not reorder the
  /// original library. Turning shuffle off restores the initial order.
  void setShuffled(bool enabled, {Random? random}) {
    if (enabled == _shuffled) return;
    final active = current.path;
    _shuffled = enabled;
    if (enabled) {
      final rest = _order.where((t) => t.path != active).toList()
        ..shuffle(random ?? Random());
      _order = [current, ...rest];
      _currentIndex = 0;
    } else {
      _order = List.of(_original);
      final position = _order.indexWhere((track) => track.path == active);
      _currentIndex = position >= 0 ? position : 0;
    }
  }

  PlayerRepeatMode cycleRepeat() {
    repeatMode = PlayerRepeatMode
        .values[(repeatMode.index + 1) % PlayerRepeatMode.values.length];
    return repeatMode;
  }

  /// Repeat-one applies only to automatic track completion, not a manual skip.
  RemoteTrack? next({bool manual = true}) {
    if (!manual && repeatMode == PlayerRepeatMode.one) return current;
    final nextIndex = _currentIndex + 1;
    if (nextIndex < _order.length) {
      _currentIndex = nextIndex;
      return current;
    }
    if (repeatMode == PlayerRepeatMode.all) {
      _currentIndex = 0;
      return current;
    }
    return null;
  }

  RemoteTrack? previous() {
    final index = _currentIndex - 1;
    if (index >= 0) {
      _currentIndex = index;
      return current;
    }
    if (repeatMode == PlayerRepeatMode.all) {
      _currentIndex = _order.length - 1;
      return current;
    }
    return null;
  }

  /// Returns the next actual file for the two-track prefetch subsystem.
  RemoteTrack? nextForPrefetch() {
    if (repeatMode == PlayerRepeatMode.one) return current;
    if (_currentIndex + 1 < _order.length) return _order[_currentIndex + 1];
    return repeatMode == PlayerRepeatMode.all ? _order.first : null;
  }
}
