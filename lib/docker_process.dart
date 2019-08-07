import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final _logger = Logger('docker_process');

/// Access wrapper to interact with a docker container as a process.
class DockerProcess {
  final String _dockerExecutable;
  final String _name;

  DockerProcess._(this._dockerExecutable, this._name);

  /// Starts a docker container.
  static Future<DockerProcess> start({
    @required String image,
    @required String name,
    String dockerExecutable,
    String dockerCommand,
    List<String> dockerArgs,
    String network,
    String hostname,
    Map<String, String> environment,
    List<String> ports,
    List<String> imageArgs,
    bool sudo = false,
    bool cleanup,
    bool readySignal(String line),
    Duration timeout,
  }) async {
    dockerExecutable ??= 'docker';
    cleanup ??= false;
    String command = dockerExecutable;
    final args = <String>[];

    if (sudo) {
      args.add(command);
      command = 'sudo';
    }
    dockerCommand ??= readySignal == null ? 'start' : 'run';

    args.add(dockerCommand);
    if (cleanup) {
      args.add('--rm');
    }

    args.addAll(<String>[
      '--name',
      name,
    ]);

    if (network != null) {
      args.add('--net');
      args.add(network);
    }
    if (hostname != null) {
      args.add('-h');
      args.add(hostname);
    }
    ports?.forEach((p) {
      args.add('-p');
      args.add(p);
    });
    environment?.forEach((k, v) {
      args.add('-e');
      args.add('$k=$v');
    });
    if (dockerArgs != null && dockerArgs.isNotEmpty) {
      args.addAll(dockerArgs);
    }
    args.add(image);
    if (imageArgs != null) {
      args.addAll(imageArgs);
    }

    _logger.info({
      'starting': {'name': name, 'command': command, 'args': args},
    });
    if (readySignal != null) {
      final process = await Process.start(command, args);

      final c = Completer();
      final timer = Timer(timeout ?? const Duration(minutes: 1), () {
        if (c.isCompleted) return;
        c.completeError('timeout');
      });
      StreamSubscription subs1;
      StreamSubscription subs2;
      StreamSubscription subs(Stream<List<int>> stream) {
        return stream
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((String line) {
          if (readySignal(line)) {
            subs1?.cancel();
            subs1 = null;
            subs2?.cancel();
            subs2 = null;
            if (c.isCompleted) return;
            c.complete();
          }
        });
      }

      subs1 = subs(process.stdout);
      subs2 = subs(process.stderr);

      final dp = DockerProcess._(dockerExecutable, name);

      try {
        await c?.future;
      } catch (_) {
        await dp.kill();
        rethrow;
      } finally {
        timer?.cancel();
      }
      return dp;
    } else {
      final pr = await Process.run(command, args);
      if (pr.exitCode != null) {
        throw Exception(
            'exitCode: ${pr.exitCode}\n\nstdout: ${pr.stdout}\n\nstderr: ${pr.stderr}');
      }
      return DockerProcess._(dockerExecutable, name);
    }
  }

  /// Executes the command
  Future<ProcessResult> exec(List<String> args) async {
    _logger.info({
      'executing': {'name': _name, 'args': args},
    });
    return Process.run(
        _dockerExecutable, <String>['exec', _name]..addAll(args));
  }

  /// Kill the docker container.
  Future kill({
    ProcessSignal signal = ProcessSignal.sigkill,
  }) async {
    try {
      _logger.info({
        'killing': {'name': _name}
      });
      await Process.run(_dockerExecutable, ['kill', '--signal=$signal', _name]);
    } catch (e, st) {
      _logger.warning({
        'kill-error': {'name': _name},
      }, e, st);
    }
  }

  /// Stop the docker container.
  Future stop() async {
    try {
      _logger.info({
        'stopping': {'name': _name}
      });
      await Process.run(_dockerExecutable, ['stop', _name]);
    } catch (e, st) {
      _logger.warning({
        'stop-error': {'name': _name},
      }, e, st);
    }
  }

  /// Checks whether the container is running.
  Future<bool> isRunning() async {
    final pr = await Process.run(
      _dockerExecutable,
      ['ps', '--format', '{{.Names}}'],
    );
    return pr.stdout
        .toString()
        .split('\n')
        .map((s) => s.trim())
        .contains(_name);
  }
}
