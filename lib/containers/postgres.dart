import 'package:docker_process/docker_process.dart';

export 'package:docker_process/docker_process.dart';

Future<DockerProcess> startPostgres({
  required String name,
  required String version,
  String imageName = 'postgres',
  String? network,
  String? pgUser,
  String pgPassword = 'postgres',
  String? pgDatabase,
  int pgPort = 5432,
  bool? cleanup,
}) async {
  var ipv4 = false;

  return await DockerProcess.start(
    name: name,
    image: '$imageName:$version',
    network: network,
    hostname: name,
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
