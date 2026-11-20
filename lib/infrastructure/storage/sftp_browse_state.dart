import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/host.dart';
import '../ssh/sftp_service.dart';

/// Device-local browsing history, independent of transient SSH session IDs.
class SftpBrowseState {
  SftpBrowseState(this._preferences);

  final SharedPreferences? _preferences;
  static const _prefix = 'netcatty_mobile_sftp_last_path_v1.';
  static const _maxCachedDirectories = 32;
  static const _maxCachedEntries = 2000;
  final _lastPaths = <String, String>{};
  final _cache = <(String, String), List<RemoteEntry>>{};

  static String hostKey(HostProfile host) => jsonEncode([
        host.id,
        host.hostname,
        host.port,
        host.username,
        host.hostChainIds,
        host.proxyProfileId,
      ]);

  String? _key(FileTransferService source) =>
      source is SftpService ? hostKey(source.session.host) : null;

  String? lastPath(FileTransferService source) {
    final key = _key(source);
    if (key == null) return null;
    final path = _lastPaths[key] ?? _preferences?.getString('$_prefix$key');
    return path != null && path.startsWith('/') ? path : null;
  }

  List<RemoteEntry>? cachedEntries(FileTransferService source, String path) {
    final key = _key(source);
    if (key == null) return null;
    final cacheKey = (key, path);
    final entries = _cache.remove(cacheKey);
    if (entries != null) _cache[cacheKey] = entries;
    return entries;
  }

  Future<void> remember(FileTransferService source, String path,
      List<RemoteEntry> entries) async {
    final key = _key(source);
    if (key == null || !path.startsWith('/')) return;
    final cacheKey = (key, path);
    _cache.remove(cacheKey);
    if (entries.length <= _maxCachedEntries) {
      _cache[cacheKey] = List.unmodifiable(entries);
      while (_cache.length > _maxCachedDirectories) {
        _cache.remove(_cache.keys.first);
      }
    }
    final previous = lastPath(source);
    _lastPaths[key] = path;
    if (previous == path) return;
    try {
      await _preferences?.setString('$_prefix$key', path);
    } catch (_) {
      // In-memory browsing remains available when persistence fails.
    }
  }

  void invalidate(FileTransferService source, String path) {
    final key = _key(source);
    if (key != null) _cache.remove((key, path));
  }
}
