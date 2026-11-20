import 'package:flutter_test/flutter_test.dart';
import 'package:netcatty_mobile/domain/models/host.dart';
import 'package:netcatty_mobile/infrastructure/ssh/sftp_service.dart';
import 'package:netcatty_mobile/infrastructure/ssh/ssh_service.dart';
import 'package:netcatty_mobile/infrastructure/storage/sftp_browse_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xterm2/xterm.dart';

SftpService source(String sessionId, String hostId, {String user = 'root'}) =>
    SftpService(ActiveTerminalSession(
      id: sessionId,
      host: HostProfile.create(
          id: hostId, label: hostId, hostname: 'example.org', username: user),
      terminal: Terminal(),
      verifyHostKey: (_, __, ___) async => true,
      keyboardInteractive: null,
    ));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores directories per host across reconnect and app restart',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final state = SftpBrowseState(preferences);
    final a = source('session-a', 'host-a');
    final b = source('session-b', 'host-b');
    await state.remember(a, '/opt/game', []);
    await state.remember(b, '/var/log', []);
    final reconnected = source('new-session', 'host-a');
    expect(state.lastPath(reconnected), '/opt/game');
    expect(state.lastPath(b), '/var/log');
    expect(state.lastPath(source('new-user', 'host-a', user: 'other')), isNull);
    final restarted = SftpBrowseState(preferences);
    expect(restarted.lastPath(reconnected), '/opt/game');
    expect(restarted.cachedEntries(reconnected, '/opt/game'), isNull);
  });

  test('isolates cached listings by host and path and invalidates stale data',
      () async {
    final state = SftpBrowseState(null);
    final a = source('one', 'a');
    final b = source('two', 'b');
    const entry = RemoteEntry(
        name: 'file', path: '/work/file', isDirectory: false, size: 1);
    await state.remember(a, '/work', [entry]);
    await state.remember(a, '/other', []);
    expect(state.cachedEntries(source('reconnected', 'a'), '/work'), [entry]);
    expect(state.cachedEntries(a, '/other'), isEmpty);
    expect(state.cachedEntries(b, '/work'), isNull);
    state.invalidate(a, '/work');
    expect(state.cachedEntries(a, '/work'), isNull);
    expect(state.lastPath(a), '/other');
  });

  test('bounds cached directory count', () async {
    final state = SftpBrowseState(null);
    final a = source('one', 'a');
    for (var i = 0; i < 33; i++) {
      await state.remember(a, '/dir$i', []);
    }
    expect(state.cachedEntries(a, '/dir0'), isNull);
    expect(state.cachedEntries(a, '/dir32'), isEmpty);
    expect(state.lastPath(a), '/dir32');
  });
}
