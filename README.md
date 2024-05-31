# test-keycloak-mariadb

(((Keycloak + MariaDB + jwt-server + NGINX + Keepalived) on Docker) on LXD) x 3

## 概要

- LXD を利用し、実ホストと実ネットワークを想定した環境を構築
  - LXD コンテナは、固定 IP アドレス
  - LXD 自体は、実環境では利用しない想定
- 3 台のホスト相当 (LXD コンテナノード) が同一ネットワークに存在
- それぞれの LXD コンテナノードに Docker をインストール
- それぞれのノードにて、docker compose でアプリ一式を起動
  - docker compose で起動する一式が実環境でも動作することを想定
- MariaDB Galera cluster で DB を冗長化
  - 停止しないことが前提で、再起動はできない
  - 破損・停止した場合は再所属手続きが必要
- それぞれのノードで Keycloak が動作
- 代表アドレスで Keycloak にアクセス
  - Keepalived (VRRP) 利用
  - NGINX で https 化、リバースプロキシ
- Keepalived が無応答で(restart でも) 他のノードが代表に昇格
- manage コンテナ
  - squid を実行
    - http proxy をここに設定して、このネットワーク内の名前でブラウザアクセス用
  - docker registry (proxy) を実行
    - dockerhub, quay.io からのダウンロードをキャッシュ
    - 外部に設置しても良い

## 必要

- LXD
- Disk (LXD storage pool): 200GB
- Memory: 16GB

## (オプション) Docker registry proxy

manage コンテナにてdocker registry proxy が標準で動作する。
dockerhub (docker.io) と quay.io のイメージをキャッシュする。

それとは別のホストに docker registry proxy を構築する場合は以下のように構築する。

SHARE/compose-manage.yml を参考にして、
新規ディレクトリに compose.yml を作成する。

.env を作成 (Docker にログインする場合にだけ設定すれば良い)

```
DOCKER_USER=...
DOCKER_PASS=...
```

起動

```
docker compose up -d
```

停止

```
docker compose down
または volume を消す場合
docker compose down -v
```

## 設定

必要に応じて config.sh ファイルを作成する。

例 (192.168.0.10 にて、apt-cacher-ng, Docker registry proxy が動作)

```bash
## HTTP プロキシサーバを利用して LXD, Docker を利用する場合
HTTP_PROXY=http://192.168.0.10:3142
HTTPS_PROXY=http://192.168.0.10:3142
NO_PROXY=192.168.0.10

## 自前で registry proxy を設置した場合
DOCKER_REGISTRY_PROXY=http://192.168.0.10:50000,http://192.168.0.10:50001
```

## 構築手順

- ./00_init.sh
  - LXD 自体に http_proxy の設定
- ./01_create-hosts.sh
- ./02_install.sh
- ./03_ca.sh

### 初期 DB ノード構築 (初期起動ノード)

- make shell@kc1
- (option: Dockerfile イメージを再ビルドする場合)
  - docker compose build
- ./mariadb-stop.sh
- ./mariadb-new.sh
  - 初回、クラスタ作成時のみ
- 起動を確認:
  - ./mariadb-status.sh
- (option: バックアップデータから戻す場合)
  - (このタイミングでリストアする)
  - ./mariadb-restore.sh ./BACKUP/ファイル名
- ./mariadb-init-jwt-server.sh
  - jwt-server 用のユーザを DB に追加

### 追加 DB ノード構築・参加 (2台目以降)

- `make shell@kc2`
  - or `make shell@kc3`
- (option: イメージ再ビルドする場合)
  - docker compose build
- ./mariadb-stop.sh
- ./mariadb-join.sh
  - 2台目以降参加する場合
- 起動を確認:
  - ./mariadb-status.sh
- mariadb のみ動作確認:
  - ./mariadb-benchmark.sh
- ホスト OS にて全体確認:
  - make mariadb-status
  - 3 台とも Synced になるまで確認して待つ
  - ctrl-c で停止

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

## Keycloak 初期設定

jwt-server が動作するための設定を Keycloak に投入する。

以下の手順では、Keycloak の Web UI を操作せずに、Keycloak の API を Python プログラムから呼び出して設定をおこなう。

- make shell@manage
- ./install-keycloak-api.sh
- ./keycloak-config.sh

## squid 経由でウェブブラウザアクセス

squid (http プロキシ) が manage コンテナで動作している。

その squid を経由して、手元の Web ブラウザを利用することで、LXD コンテナと同じネットワークに所属したようなアクセスができる。

LXD ネットワーク内のホスト名の名前解決を squid コンテナ側でおこなうことで、テスト用のホスト名 *.example.org を利用できる。

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
- Webブラウザに SwitchyOmega の拡張をインストール
- SwitchyOmega の設定
  - 新規追加: localhost 57000
  - auto swich 設定: *.example.org に対して、上記で追加した設定に関連づけ

## 単体ノード停止・再開

- ./mariadb-stop.sh
- ./mariadb-join.sh

## 全ノード停止・再開

- 停止手順
  - ./mariadb-backup.sh を念のため実行
  - kc3, kc2, kc1 の順で一つずつ mariadb コンテナ停止
  - ./mariadb-stop.sh
  - コンテナは消えるが volume は残る

- 起動手順
  - ./mariadb-show-bootstrap.sh が safe_to_bootstrap: 1 となるホストを探す
  - 最後に停止したコンテナが 1 になる
  - ./mariadb-stop.sh を念のため実行
  - ./mariadb-new.sh を実行

- その他ノード
  - ./mariadb-stop.sh を念のため実行
  - ./mariadb-join.sh を実行

- 別の方法
  - 各ノードの DB データを破棄 (後述)
  - バックアップデータからリストアして起動する

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

- (keycloak + mariadb フェイルオーバーの動作確認)
  - squid 経由で https://keycloak.example.org に接続 (Web ブラウザ)
  - admin:admin でログイン
  - レルム作成、ユーザ作成、ユーザ詳細画面表示したままにしておく
  - lxc ls で IPアドレスを確認
    - ./myip.sh を LXD コンテナそれぞれで実行するでも良い
  - 10.60.204.11 のアドレスも追加でついているコンテナで操作
    - docker compose restart keepalived
    - ./myip.sh
  - 10.60.204.11 のアドレスが他のノードに移転されたことを確認
  - ユーザ詳細画面をリロード
  - 再度ログイン画面が出ずにユーザ詳細画面のままであれば成功
- (jwt-server の動作確認)
  - HPCI レルムにユーザを作成、属性に hpci.id を設定して保存
  - squid 経由で https://jwtserver.example.org に接続 (Web ブラウザ)
  - make shell@manage にて jwt-agent を起動
    - ./install-jwt-agent.sh
      - 取得された SHARE/jwt-agent ディレクトリは以降更新されない
        - (更新・変更する場合は、手動で変更する)
    - ./jwt-agent-with-proxy.sh <jwt-agent引数...>
    - manage コンテナの squid を利用してホスト名解決される
  - 10.60.204.11 のアドレスがついているコンテナで操作
    - docker compose restart keepalived
    - ./myip.sh
  - 10.60.204.11 のアドレスが他のノードに移転されたことを確認
  - jwt-agent が停止しないことを確認
    - 例: `while :;do ls -l /tmp/jwt_user_u0/token.jwt ; sleep 5; done`
    ```
    -rw------- 1 root root 835 May 31 04:11 /tmp/jwt_user_u0/token.jwt
    -rw------- 1 root root 835 May 31 04:19 /tmp/jwt_user_u0/token.jwt
    ```

## アップデート

- ./mariadb-backup.sh
- Keycloak の更新
  - SHARE/keycloak-quarkus/Dockerfile を編集
    - ARG KEYCLOAK_IMAGE=keycloak/keycloak:24.0 の値を変更
  - docker compose rm -sf keycloak
  - ./up.sh keycloak
- Keycloak の大幅更新を試す
  - (WildFly版[~v16] から Quarkus版[v17~])
  - 新規構築時: ./up.sh ALL-OLD で全体を一旦構築
  - docker compose rm -sf keycloak-old
  - ./up.sh keycloak
- Keycloak 大幅バージョンダウン
  - WebUI でログインできなくなった。

### 無停止で大幅アップデート

- マスターとなっていないノード(2台)にて
  - docker compose build
  - docker compose rm -sf keycloak-old
  - ./up.sh keycloak
- マスターノードにて
  - docker compose restart keepalived
  - (以下上記同様更新処理)
  - docker compose rm -sf keycloak-old
  - docker compose build
  - ./up.sh keycloak
  - Keycloak ログイン中のウェブブラウザは一旦エラーが出た。
    - 再度ログインしなおすと正常表示できた。
  - jwt-agent が動き続けた。
