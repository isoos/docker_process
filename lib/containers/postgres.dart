import 'package:docker_process/docker_process.dart';
import 'package:meta/meta.dart';

export 'package:docker_process/docker_process.dart';

Future<DockerProcess> startPostgres({
  @required String name,
  @required String version,
  String imageName = 'postgres',
  String pgUser,
  String pgPassword = 'postgres',
  String pgDatabase,
  int pgPort = 5432,
  bool cleanup,
}) async {
  bool ipv4 = false;

  return await DockerProcess.start(
    name: name,
    image: '$imageName:$version',
    ports: ['$pgPort:5432'],
    cleanup: cleanup,
    readySignal: (line) {
      ipv4 |= line.contains('listening on IPv4 address "0.0.0.0", port 5432');
      return ipv4 &&
          line.contains('database system is ready to accept connections');
    },
    environment: {
      if (pgUser != null) 'POSTGRES_USER': pgUser,
      'POSTGRES_PASSWORD': pgPassword,
      if (pgDatabase != null) 'POSTGRES_DB': pgDatabase,
    },
  );
}
