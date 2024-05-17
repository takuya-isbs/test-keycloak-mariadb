# test-keycloak-mariadb

(((Keycloak + MariaDB + NGINX) on Docker + Keepalived) on LXD) x 3

## 自動構築

TODO

## ステップ実行

- ./01_create-hosts.sh
- ./02_install.sh
- ./03_ca.sh

TODO
- XX_update-etchosts.sh
- XX_squid.sh


### 初期 DB ノード構築 (初期起動ノード)

- make shell@kc1
- (イメージ再ビルドする場合) docker compose build
- ./mariadb-new.sh
  - 初回、クラスタ作成時のみ
- 起動を確認:
  - ./mariadb-status.sh

### 追加 DB ノード構築・参加 (2台目以降)

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

### 各アプリ起動

各ノードにて以下を実行する。

- docker compose up -d keycloak nginx squid

TODO keepalived, jwt-server

## ブラウザアクセス

kc1コンテナのeth0 IPアドレスを lxc ls で確認

```
Host dev(任意名)
HostName サーバのIPアドレス
User ユーザ名
Port 22
LocalForward 57000 kc1コンテナのIPアドレス:13128
```

ssh dev
SwitchyOmega の設定 localhost 57000
keycloak.example.org を auto switch

## 単体ノード停止・再開

TODO

## 全ノード停止・再開

TODO mariadb の停止順序、起動順序が重要

## 単体 DB データ破棄(故障想定)

- make shell@???
- docker compose down -v
- 再度、初期ノードだとしても「追加ノード構築・参加」可能

## 全ノード破棄

- ./99_delete-hosts.sh

## データバックアップ

## ログ

- docker compose logs -f
