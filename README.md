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
- (必要に応じて docker login を実行する)
- (イメージ再ビルドする場合) docker compose build
- ./mariadb-new.sh
  - 初回、クラスタ作成時のみ
- 起動を確認:
  - ./mariadb-status.sh

### 追加 DB ノード構築・参加 (2台目以降)

- `make shell@kc2`
  - or `make shell@kc3`
- (必要に応じて docker login を実行する)
- (イメージ再ビルドする場合) docker compose build
- ./mariadb-join.sh
  - 2台目以降参加する場合
- 起動を確認:
  - ./mariadb-status.sh
- mariadb のみ動作確認:
  - ./mariadb-benchmark.sh
  - 3 台とも Synced になるまで確認して待つ

ホスト OS にて全体確認

- make mariadb-status

### mariadb 以外のコンテナ起動

上記のように mariadb 起動後、各ノードにて以下を実行する。

- docker compose up -d --no-recreate
- 間違えて --no-recreate をつけなかった場合にやり直す方法
  - docker compose down -v
  - ./mariadb-join.sh
  - ./mariadb-status.sh

TODO jwt-server

## ブラウザアクセス

kc1 コンテナの eth0 IPアドレスを lxc ls で確認しておく。

```
Host {任意名(以下の例ではdev1)}
HostName {サーバのIPアドレス}
User ユーザ名
Port 22
LocalForward 57000 {kc1コンテナのIPアドレス}:13128
```

- ssh dev1
- SwitchyOmega の設定 localhost 57000 を追加
- keycloak.example.org 上記で追加した設定に関連づけて auto switch に追加

## 単体ノード停止・再開

TODO

## 全ノード停止・再開

TODO mariadb の停止順序、起動順序が重要

## 単体 DB データ破棄(故障想定)

- make shell@???
- docker compose down -v
- 再度、初期ノードだとしても「追加ノード構築・参加」可能

## コンテナ再構築

mariadb コンテナ再構築は、上記「単体 DB データ破棄」の項目参照

mariadb 以外は以下の方法で再構築する。

- docker compose up -d keycloak
- docker compose up -d nginx
- docker compose up -d keepalived
- docker compose up -d squid

TODO jwt-server

## 全ノード破棄

- ./99_delete-hosts.sh

## DB データバックアップ

## ログの確認

- docker compose logs -f
