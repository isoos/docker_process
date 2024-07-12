import 'package:docker_process/docker_process.dart';

export 'package:docker_process/docker_process.dart';

/// Starts a postgres container with the given [name] using the given
/// [imageName] and [version].
///
/// Use [postgresqlConfPath] or [pgHbaConfPath] to mount `postgresql.conf`
/// or `pg_hba.conf` on the container, respectively.
///
/// Use [configurations] to pass list of configs to the `postgres` image. For
/// example: ['shared_buffers=256MB', 'max_connections=200']. As shown, each
/// item in the list must contain the parameter and its assignment in as a single
/// item.
///
/// For other options, please refer to [DockerProcess.start].
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
  String? postgresqlConfPath,
  String? pgHbaConfPath,
  List<String>? configurations,
  String? timeZone,
}) async {
  var ipv4 = false;

  final dockerArgs = <String>[];
  final imageArgs = <String>[];

  if (configurations != null) {
    for (var config in configurations) {
      imageArgs.add('-c');
      imageArgs.add(config);
    }
  }

  // see Database Configuration section at official image page:
  // https://hub.docker.com/_/postgres/
  if (postgresqlConfPath != null) {
    dockerArgs.add('-v');
    dockerArgs.add('$postgresqlConfPath:/etc/postgresql/postgresql.conf');

    imageArgs.add('-c');
    imageArgs.add('config_file=/etc/postgresql/postgresql.conf');
  }

  if (pgHbaConfPath != null) {
    dockerArgs.add('-v');
    dockerArgs.add('$pgHbaConfPath:/etc/postgresql/pg_hba.conf');

    imageArgs.add('-c');
    imageArgs.add('hba_file=/etc/postgresql/pg_hba.conf');
  }

  return await DockerProcess.start(
    name: name,
    dockerArgs: dockerArgs,
    image: '$imageName:$version',
    imageArgs: imageArgs,
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
      if (timeZone != null) 'TZ': timeZone,
      if (timeZone != null) 'PGTZ': timeZone,
    },
  );
}
