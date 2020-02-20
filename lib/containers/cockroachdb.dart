import 'dart:io';

import 'package:docker_process/docker_process.dart';
import 'package:meta/meta.dart';

export 'package:docker_process/docker_process.dart';

Future<DockerProcess> startCockroachDB({
  @required String name,
  @required String version,
  String imageName = 'cockroachdb/cockroach',
  String network,
  int pgPort = 26257,
  int httpPort = 8080,
  bool cleanup,
  bool secure = false,
  bool initialize = false,
  List<String> attrs,
  List<String> join,
  String advertiseHost,
  int advertisePort,
}) async {
  final isJoining = join != null && join.isNotEmpty;
  var starting = false;
  var initialized = !initialize;
  return await DockerProcess.start(
    name: name,
    image: '$imageName:$version',
    network: network,
    hostname: name,
    ports: ['$pgPort:26257', '$httpPort:8080'],
    cleanup: cleanup,
    readySignal: (line) async {
      if (!initialized) {
        if (!line.contains('cockroach init')) {
          return false;
        }
        final pr = await Process.run(
          'docker',
          [
            'exec',
            name,
            './cockroach',
            'init',
            if (!secure) '--insecure',
          ],
        );
        if (pr.exitCode != 0) {
          throw Exception(
              '`docker exec $name cockroach init` failed:\n${pr.stdout}\n\n${pr.stderr}');
        }
        initialized = true;
        return false;
      }

      starting |= line.contains('CockroachDB node starting');
      return starting && line.contains('nodeID:');
    },
    imageArgs: [
      'start',
      if (!secure) '--insecure',
      if (attrs != null && attrs.isNotEmpty) ...['--attrs', attrs.join(',')],
      if (advertiseHost != null) '--advertise-host=$advertiseHost',
      if (advertisePort != null) '--advertise-port=$advertisePort',
      if (isJoining) ...['--join', join.join(',')],
    ],
  );
}
