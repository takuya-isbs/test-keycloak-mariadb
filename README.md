# test-keycloak-mariadb

(((Keycloak + MariaDB + jwt-server + NGINX + Keepalived) on Docker) on LXD) x 3

## 概要

- LXD を利用し、実ホストと実ネットワークを想定した環境を構築
  - LXD コンテナは、固定 IP アドレス
  - LXD 自体は、実環境では利用しない想定
- 3 台のホストが同一ネットワークに存在
- それぞれの LXD コンテナホストに Docker をインストール
- それぞれのホストにて、docker compose でアプリ一式を起動
  - docker compose で起動する一式が実環境でも動作することを想定
- MariaDB Galera cluster で DB を冗長化
  - 停止しないことが前提で、再起動はできない
  - 破損・停止した場合は再所属手続きが必要
- それぞれのホストで Keycloak が動作
- 代表アドレスで Keycloak にアクセス
  - Keepalived (VRRP) 利用
  - NGINX で https 化、リバースプロキシ
- Keepalived が無応答で(restart でも) 他のホストが代表に昇格

## 必要

- LXD
- Disk (LXD storage pool): 200GB
- Memory: 16GB

## 自動構築

TODO

## ステップ実行

- ./01_create-hosts.sh
- ./02_install.sh
- ./03_ca.sh

### 初期 DB ノード構築 (初期起動ノード)

- make shell@kc1
- (必要に応じて docker login を実行する)
- (イメージ再ビルドする場合) docker compose build
- ./mariadb-stop.sh
- ./mariadb-new.sh
  - 初回、クラスタ作成時のみ
- 起動を確認:
  - ./mariadb-status.sh
- (バックアップデータから戻す場合) ./mariadb-restore.sh ./BACKUP/ファイル名
- jwt-server 用のユーザ追加
   - docker compose exec mariadb sh /mariadb-add-jwt-server.sh

### 追加 DB ノード構築・参加 (2台目以降)

- `make shell@kc2`
  - or `make shell@kc3`
- (必要に応じて docker login を実行する)
- (イメージ再ビルドする場合) docker compose build
- ./mariadb-stop.sh
- ./mariadb-join.sh
  - 2台目以降参加する場合
- 起動を確認:
  - ./mariadb-status.sh
  - 3 台とも Synced になるまで確認して待つ
- mariadb のみ動作確認:
  - ./mariadb-benchmark.sh

ホスト OS にて全体確認

- make mariadb-status

### mariadb 以外のコンテナ起動

上記のように mariadb 起動後、各ノードにて以下を実行する。

- ./up.sh ALL
  - 処理概要
    - ホスト名から IP アドレスを推定
    - docker compose up -d --no-recreate を実行
- 間違えて --no-recreate をつけずに起動してしまった場合
  - mariadb が起動しない
  - 再度 mariadb をクラスタに所属しなおす
  - docker compose down -v --remove-orphans
  - ./mariadb-join.sh
  - ./mariadb-status.sh

## Keycloak 設定

- make shell@manage
- ./up.sh squid
- ./install-keycloak-api.sh
- ./keycloak-config.sh

## squid 経由でウェブブラウザアクセス

manage コンテナにて squid を起動する。

- make shell@manage
- ./up.sh squid
- exit

manage コンテナの eth0 IPアドレスを lxc ls で確認しておく。
(172.* ではないアドレス)

```
Host {任意名(以下の例ではdev1)}
HostName {サーバのIPアドレス}
User ユーザ名
Port 22
LocalForward 57000 {manageコンテナのIPアドレス}:13128
```

- ssh dev1
- SwitchyOmega の設定 localhost 57000 を追加
- keycloak.example.org 上記で追加した設定に関連づけて auto switch に追加

## 単体ノード停止・再開

- ./mariadb-stop.sh
- ./mariadb-join.sh

## 全ノード停止・再開

- kc3, kc2, kc1 の順で一つずつ mariadb コンテナ停止
  - ./mariadb-stop.sh
  - コンテナは消えるが volume は残る
- ./mariadb-show-bootstrap.sh が safe_to_bootstrap: 1 となるホストを探す
  - 最後に停止したコンテナが 1 になる
  - ./mariadb-stop.sh を念のため実行
  - ./mariadb-new.sh を実行
- その他ホスト
  - ./mariadb-stop.sh を念のため実行
  - ./mariadb-join.sh を実行

## 単体 DB データ破棄(故障想定)

- make shell@???
- docker compose down -v --remove-orphans
- 再度、初期ノードだとしても「追加ノード構築・参加」可能
- 全ノードの DB を破棄した場合は、「初期 DB ノード構築」から再構築する

## コンテナ再構築

mariadb コンテナ再構築は、上記「単体 DB データ破棄」の項目参照

mariadb 以外は以下の方法で再構築する。

- ./recreate.sh keycloak
- ./recreate.sh nginx
- ./recreate.sh keepalived
- ./recreate.sh squid

## 全ノード破棄 (完全初期化)

- ./99_delete-hosts.sh

## DB データバックアップ

- ./mariadb-backup.sh

## ログの確認

- docker compose logs -f

## テスト

### ウェブブラウザ

- squid 経由で https://keycloak.example.org に接続
- admin:admin でログイン
- レルム作成、ユーザ作成、ユーザ詳細画面表示したままにしておく
- lxc ls で IPアドレスを確認
  - ./myip.sh を LXD コンテナそれぞれで実行するでも良い
- 10.60.204.11 のアドレスも追加でついているコンテナで操作
  - docker compose restart keepalived
  - ./myip.sh
- 10.60.204.11 のアドレスが他のホストに移転されたことを確認
- ユーザ詳細画面をリロード
- 再度ログイン画面が出ずにユーザ詳細画面のままであれば成功
