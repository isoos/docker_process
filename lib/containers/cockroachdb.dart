import 'package:docker_process/docker_process.dart';
import 'package:meta/meta.dart';

export 'package:docker_process/docker_process.dart';

Future<DockerProcess> startCockroachDB({
  @required String name,
  @required String version,
  String imageName = 'cockroachdb/cockroach',
  int pgPort = 26257,
  int httpPort = 8080,
  bool cleanup,
  bool secure = false,
}) async {
  bool starting = false;
  return await DockerProcess.start(
    name: name,
    image: '$imageName:$version',
    ports: ['$pgPort:26257', '$httpPort:8080'],
    cleanup: cleanup,
    readySignal: (line) {
      starting |= line.contains('CockroachDB node starting');
      return starting && line.contains('nodeID:');
    },
    imageArgs: [
      'start',
      if (!secure) '--insecure',
    ],
  );
}
