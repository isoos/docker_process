import 'dart:io';

import 'package:docker_process/containers/postgres.dart';
import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

final _samplesDir = p.join(Directory.current.path, 'test', 'samples');

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

  group('mounting conf files', () {
    DockerProcess? dp1;
    DockerProcess? dp2;

    tearDownAll(() async {
      await dp1?.stop();
      await dp2?.stop();
      await dp1?.kill();
      await dp2?.kill();
    });

    test('mount custom postgresql.conf', () async {
      final postgresqlConfPath = p.join(_samplesDir, 'sample_postgresql.conf');
      dp1 = await startPostgres(
        name: 'test_postgresql_conf_mounting',
        version: 'latest',
        cleanup: true,
        pgPort: 5432,
        postgresqlConfPath: postgresqlConfPath,
      );

      // confirm sample_postgresql.conf is mounted correctly
      final res = await dp1!.exec([
        'cat',
        '/etc/postgresql/postgresql.conf',
      ]);

      final file = res.stdout as String;

      expect(file.startsWith('# sample_postgresql.conf'), true);
    });

    test('mount custom pg_hba.conf', () async {
      final pgHbaConfPath = p.join(_samplesDir, 'sample_pg_hba.conf');

      dp2 = await startPostgres(
        name: 'test_pg_hba_conf_mounting',
        version: 'latest',
        cleanup: true,
        // this would conflict with the other test in the group 
        // so it's a different number
        pgPort: 54321, 
        pgHbaConfPath: pgHbaConfPath,
      );
      final res = await dp2!.exec([
        'cat',
        '/etc/postgresql/pg_hba.conf',
      ]);

      final file = res.stdout as String;

      expect(file.startsWith('# sample_pg_hba.conf'), true);
    });
  });

  group('mounting postgresql.conf is effective', () {
    DockerProcess? dp;

    tearDownAll(() async {
      await dp?.stop();
      await dp?.kill();
    });

    // in the `sample_postgresql.conf`, the `wal_level` was changed to `logical`
    // here we test if this has taken effect after mounting the sample conf.
    test('wal_level should be logical', () async {
      final postgresqlConfPath = p.join(_samplesDir, 'sample_postgresql.conf');
      dp = await startPostgres(
        name: 'check_wal_level',
        version: 'latest',
        cleanup: true,
        pgPort: 5432,
        postgresqlConfPath: postgresqlConfPath,
      );

      // confirm sample_postgresql.conf is mounted correctly
      final c = PostgreSQLConnection(
        'localhost',
        5432,
        'postgres',
        username: 'postgres',
        password: 'postgres',
      );

      await c.open();
      final res = await c.query('show wal_level');
      expect(res.first.first, 'logical');
      await c.close();
    });
  });

  group('test postgres configuration arguments', () {
    DockerProcess? dp;

    tearDownAll(() async {
      await dp?.stop();
      await dp?.kill();
    });

    test('Adding configuration arguments is reflected on the image', () async {
      dp = await startPostgres(
        name: 'test_postgresql_conf_mounting',
        version: 'latest',
        cleanup: true,
        pgPort: 5432,
        configuraions: ['max_connections=42'],
      );

      // confirm sample_postgresql.conf is mounted correctly
      final c = PostgreSQLConnection(
        'localhost',
        5432,
        'postgres',
        username: 'postgres',
        password: 'postgres',
      );

      await c.open();
      final res = await c.query('show max_connections');
      expect(res.first.first, '42');
      await c.close();
    });
  });
}
