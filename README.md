# test-keycloak-mariadb

(((Keycloak + MariaDB + NGINX) on Docker + Keepalived) on LXD) x 3

## 自動構築

TODO

## ステップ実行

- ./01_create-hosts.sh
- ./02_install.sh

### 初期ノード構築 (初期起動ノード)

- make shell@kc1
- (イメージ再ビルドする場合) docker compose build
- ./mariadb-new.sh
  - 初回、クラスタ作成時のみ
- 起動を確認:
  - ./mariadb-status.sh

### 追加ノード構築・参加 (2台目以降)

- `make shell@kc2`
  - or `make shell@kc3`
- (イメージ再ビルドする場合) docker compose build
- ./mariadb-join.sh
  - 2台目以降参加する場合
- 起動を確認:
  - ./mariadb-status.sh
- mariadb のみ動作確認:
  - ./mariadb-benchmark.sh

ホスト OS にて全体確認

- make mariadb-status

## 単体ノード停止・再開

TODO

## 全ノード停止・再開

TODO 停止順序、

## 単体ノード破棄(故障想定)

- make shell@???
- docker compose down -v
- 再度、初期ノードだとしても「追加ノード構築・参加」可能

## 全ノード破棄

- ./99_delete-hosts.sh

## データバックアップ

## ログ

- docker compose logs -f
