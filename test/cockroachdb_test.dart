import 'package:docker_process/containers/cockroachdb.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group('CockroachDB', () {
    DockerProcess dp;

    tearDownAll(() async {
      await dp?.stop();
      await dp?.kill();
    });

    test('run', () async {
      dp = await startCockroachDB(
          name: 'test_crdb', version: 'latest', cleanup: true);

      final c = PostgreSQLConnection('localhost', 26257, 'root',
          username: 'root', password: 'crdb');
      await c.open();
      await c.close();
    });
  });
}
