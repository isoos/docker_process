import 'package:docker_process/containers/postgres.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group('postgres', () {
    DockerProcess? dp;

    tearDownAll(() async {
      await dp?.stop();
      await dp?.kill();
    });

    test('run', () async {
      dp = await startPostgres(
        name: 'test_postgres',
        version: 'latest',
        cleanup: true,
      );

      final c = PostgreSQLConnection(
        'localhost',
        5432,
        'postgres',
        username: 'postgres',
        password: 'postgres',
      );
      await c.open();
      await c.close();
    });
  });
}
