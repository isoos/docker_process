## 1.3.1

- Added new optional parameters to `startPostgres` ([#2][] by [osaxma][]):
  - `postgresqlConfPath` to mount a custom `postgresql.conf` file
  - `pgHbaConfPath` to mount a custom `pg_hba.conf` file
  - `configurations` to supply any individual configs (e.g. `['shared_buffers=256MB']`)

[#2]: https://github.com/isoos/docker_process/pull/2
[osaxma]: https://github.com/osaxma

## 1.3.0

- Migrated to null safety.

## 1.2.0

- Updated code to modern SDK and current lints.
- `readySignal` can be async
- CockroachDB extra arguments:
  - `attrs`: the list of attributes to set for the node
  - `advertiseHost` and `advertisePort` to control what the node tells about itself
  - `join`: the list of nodes to join
  - `initialize`: set to true if you want the first node to get initialized

## 1.1.2

- `network` and `hostname` setting in pre-configured containers.

## 1.1.1

- Helper method for running the CockroachDB container.

## 1.1.0

- Helper method for running the `postgres` container.

## 1.0.0

- Start and stop docker container (like a process).
