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
