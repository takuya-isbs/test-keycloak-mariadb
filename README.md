# test-keycloak-mariadb

(((Keycloak + MariaDB + jwt-server + NGINX + Keepalived) on Docker) on LXD) x 3

## 概要

- LXD を利用し、実ホストと実ネットワークを想定した環境を構築
  - LXD コンテナは、固定 IP アドレス
  - LXD 自体は、実環境では利用しない想定
- 3 台のホスト相当 (LXD コンテナノード) が同一ネットワークに存在
- それぞれの LXD コンテナノードに Docker をインストール
- それぞれのノードにて、docker compose でアプリ一式を起動
  - アプリ一式が実環境でも動作することを想定
- MariaDB Galera cluster で DB を冗長化
  - 全ノード停止しない前提
  - 破損したら再構築して再所属すれば復旧
  - 全ノード停止した場合、DB バックアップデータから再構築可能
- それぞれのノードで Keycloak が動作
  - Keycloak 同士でログインセッション情報など、DB データ以外のキャッシュ情報を共有
- それぞれのノードで jwt-server が動作
  - https://github.com/oss-tsukuba/jwt-server
  - Keycloak で認証・ログイン
- 代表アドレスで Keycloak にアクセス
  - Keepalived (VRRP) 利用
  - NGINX で https 化、リバースプロキシ
- Keepalived が無応答で他のノードが代表に昇格
- manage ノード (LXD コンテナ)
  - 上記 3 ノードとは別のホスト
    - 管理ホストやクライアントを想定した用途
  - squid を実行 (http proxy)
    - ここを中継して、テスト用ネットワークにアクセスできる。
  - docker registry (proxy) を実行
    - Docker イメージをキャッシュ (高速化、通信節約)
    - 外部に設置しても良い
  - ここを起点に Keycloak の API を使って設定
  - jwt-agent の動作確認

## 必要

- LXD
- Disk (LXD storage pool): 200GB
- Memory: 16GB

## (オプション) Docker registry proxy

manage コンテナにて docker registry proxy が標準で動作する。
dockerhub (docker.io) と quay.io のイメージをキャッシュする。

それとは別のホストに docker registry proxy を構築する場合は以下のように構築する。

認証・アクセス制限が無いので注意。

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

## 設定ファイル

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

## 環境構築手順

- LXD のインストール (ここでは説明省略)
  - 以下の手順では LXD のストレージプールは default を使用する。
  - LXD の profile, network が自動作成される。
- ./00_init.sh
  - LXD 自体に http_proxy を設定
- ./01_create-hosts.sh
  - LXD コンテナ作成
- ./02_install.sh
  - LXD コンテナ内に Docker などをインストール
- ./03_ca.sh
  - テスト用の CA と証明書が作成される。
  - 有効期限が切れたら、SHARE/certs/ 以下を削除し、再度作成が必要

### 初期 DB ノード構築 (初期起動ノード)

- make shell@kc1
- (option: Dockerfile イメージを再ビルドする場合)
  - docker compose build
- ./setup-glusterfs.sh
  - 初期ノードのみで実行する
  - /mnt/glusterfs にマウントされる
  - 以降で起動する Docker コンテナを停止しても、このマウントポイントは停止しない
- ./mariadb-new.sh
  - 初回、DB クラスタ作成時のみ実行する。
  - (メモ) 内部で ./fluentd-start.sh を実行している。
  - (メモ) 内部で ./mariadb-wait.sh を実行している。
- (option: バックアップデータから戻す場合)
  - このタイミングでリストアする
  - ./mariadb-restore.sh ./BACKUP/ファイル名
- ./mariadb-init-jwt-server.sh
  - (リストア時には実行不要)
  - jwt-server 用のユーザを DB に追加
  - 何度実行しても問題ない。

### 追加 DB ノード構築・参加 (2台目以降)

- (このセクションの操作は、後述の Keycloak コンテナなど起動に関して、初期ノードのみ起動した後でおこなっても良い)
- `make shell@kc2`
  - or `make shell@kc3`
  - (kc1 を再参加する場合も同様)
- (option: イメージ再ビルドする場合)
  - docker compose build
- ./mariadb-join.sh
  - 2台目以降参加する場合
  - 間違えて ./mariadb-new.sh を実行した場合
    - 初期ノードと同じ mariadb クラスタに所属できない
    - 間違えても他のノードに影響は無い
    - docker compose down -v で初期化してやりなおす
- 起動を確認:
  - ./mariadb-status.sh
- mariadb のみ動作確認:
  - ./mariadb-benchmark.sh
- ホスト OS にて全体の状態を確認:
  - watch make mariadb-status
  - 3 台とも同じ wsrep_local_state_uuid であることを確認
  - 3 台とも Synced になるまで確認して待つ
  - ctrl-c で停止

### Keycloak コンテナなど起動 (mariadb 以外のコンテナ起動)

上記のように mariadb 起動後、全 kc? ノードそれぞれにて、以下を実行する。
最初に起動したノードが代表ノードになる。

- ./up.sh INIT
  - 処理内容概要
    - ホスト名から IP アドレスを推定
    - docker compose up -d --no-recreate を実行
    - 初期ノード初回実行時、ここではまだ jwt-server は起動しない
      - Keycloak にまだ jwt-server の設定をしていないため
- 間違えて up.sh を使わず --no-recreate をつけずに docker compose up -d を実行してしまった場合
  - mariadb が起動しない
  - 以下を実行し、再度 mariadb をクラスタに所属しなおす
  - docker compose down -v --remove-orphans
  - ./mariadb-join.sh

## Keycloak 初期設定

以下の手順では、Keycloak の Web UI を操作せずに、Keycloak の API を Python プログラムから呼び出して設定をおこなう。

この手順をおこなうには、Keycloak が 1 台以上のノードで動作していれば良い。

- make shell@manage
- ./install-keycloak-api.sh
- (Keycloak が起動するまで待つ)
  - TODO ./keycloak-wait.sh を用意する
- ./keycloak-config.sh
  - ### DONE #### のあと TypeError: 'NoneType' object is not callable  になるが問題ない
    - 処理がすべて完了したあとにエラーが発生する
    - Python 3.12 など新しくすると治るので、ライブラリの問題と考えている
- kc1 ノードで以下を実行 (keycloak-old コンテナ使用時は実行不要)
  - ./keycloak-config-for-localhost.sh
    - 補足: manage コンテナだけでは設定が不十分となっているため
      - python-keycloak は、users/profile API を発行できないため
      - ./keycloak-config-for-localhost.sh は、keycloak コンテナ内で kcadm.sh を使って設定している
- 各 kc? ノードそれぞれで以下を実行
  - ./up.sh jwt-server
- 後述「テスト」を参照
  - このタイミングでは、まだ Keycloak のユーザー未登録なので、jwt-server にログインはできない

次に、keycloak-old を起動している場合 (keycloak コンテナ (Keycloak 24) では不要) は、
以下の操作をおこなう。

(MEMO: Keycloak 24 から、ユーザ拡張属性のサイズ制限が無くなった。)
  https://www.keycloak.org/docs/latest/release_notes/index.html#user-attribute-value-length-extension

Keycloak が動作しているノード一台で、以下を実行する。
(データベースの USER_ATTRIBUTE 領域の最大サイズを拡張するための操作。)

- make shell@kc1
- ./mariadb-init-keycloak.sh

VALUE の Type が varchar(255) から mediumtext に変わっていれば成功。

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

## ヘルスチェック

- bash health-check.sh; echo $?
  - エラー数が返る

## 単体ノード停止・再開

1 ノードずつ停止ならば可能。
同時に 3 ノード停止することはできない。

- 停止
  - docker compose stop
  - (ホストを停止可能な状態になる)
- 再開
  - ./fluentd-start.sh
  - docker compose start

## 全ノード停止・再開

- 停止手順
  - 全ノードの Keycloak, jwt-server を停止する
    - docker compose stop keycloak
    - docker compose stop jwt-server
  - ./mariadb-backup.sh を念のため実行
  - kc3, kc2, kc1 の順で一つずつ mariadb コンテナ停止
    - ./mariadb-stop.sh; sleep 5
    - 同時に停止すると破損する
  - docker compose down
  - コンテナは消えるが volume (DB データ) は残る
  - ログが消える (TODO ログの永続化)

- 起動手順
  - ./mariadb-show-bootstrap.sh が safe_to_bootstrap: 1 となるホストを探す
    - 最後に停止したコンテナが 1 になっている
  - safe_to_bootstrap: 1 のホストにて
    - ./mariadb-stop.sh を念のため実行
    - ./mariadb-new.sh
    - ./up.sh ALL
  - その他ノード
    - ./mariadb-stop.sh を念のため実行
    - ./mariadb-join.sh
    - ./up.sh ALL

- 別の方法
  - 各ノードの DB データを破棄 (後述)
  - バックアップデータからリストアして起動

## 単体 DB データ破棄(故障想定)

- make shell@???
- docker compose down -v --remove-orphans
  - そのノードの Docker コンテナ・データが全て消える。
- 再度「追加ノード構築・参加」の手順にて再構築可能
  - そのノードが、以前、初期ノード (mariadb-new.sh を実行した) だったかどうかは無関係
- 全ノードの DB を破棄した場合は、「初期 DB ノード構築」から再構築する。

## コンテナ再構築

docker-compose.yaml や .env を更新した場合は、コンテナを再構築する必要がある。

mariadb コンテナを再構築するには、上記「単体 DB データ破棄」の項目参照。

mariadb 以外の コンテナについて、以下を実行する。

- ./recreate.sh keycloak
- ./recreate.sh nginx
- ./recreate.sh keepalived
- ./recreate.sh squid


## 全ノード破棄 (完全初期化)

LXD コンテナをすべて削除する。
バックアップデータは消えない。

- ./99_delete-hosts.sh

## DB データバックアップ

- make shell@kc1
- ./mariadb-backup.sh

## ログの確認

- docker compose logs -f

## テスト

### keycloak + mariadb の動作確認

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

### jwt-server の動作確認

- HPCI レルムにユーザを作成、属性(Attributes)にキー hpci.id、値をユーザ名として設定して保存
  - Credentials でパスワードをセットする (テンポラリ状態を解除する)
  - Keycloak 24 では属性タブが廃止された
    - レルム設定に User Profile タブがあるので、そこに hpci.id を追加する
    - その後、ユーザの設定に hpci.id が増えているので、値を入れる
- squid 経由で https://jwtserver.example.org に接続 (Web ブラウザ)
- make shell@manage にて jwt-agent を起動
  - ./install-jwt-agent.sh
    - 取得された SHARE/jwt-agent ディレクトリは以後更新されない。
      - (更新・変更する場合は、手動で変更する)
  - ./jwt-agent-via-squid.sh <jwt-agent引数...>
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

## アップデート (バージョン変更)

DB バックアップを作成しておく。

### Keycloak の更新

- VIP が付いていないノードから更新していく
- SHARE/keycloak-quarkus/Dockerfile を編集
  - ARG KEYCLOAK_IMAGE=keycloak/keycloak:24.0 の値を変更
- docker compose build
- docker compose rm -sf keycloak
- ./up.sh keycloak
- VIP が付いていないノード更新後、VIP のノードにて
  - docker compose stop keepalived
  - その後同様に更新する
  - docker compose start keepalived

### 無停止で Keycloak を大幅更新の練習

- (WildFly版[~v16] から Quarkus版[v17~] への更新)
- 新規構築時: (INIT の代わりに) ./up.sh INIT-OLD を使用して全体を構築
- ウェブブラウザで Keycloak, jwt-server にログインしておく。
- jwt-agent を起動しておく。(動作確認目的)
- VIP が付いていないノード(2台)にて
  - docker compose build
  - docker compose rm -sf keycloak-old
  - ./up.sh keycloak
- VIP が付いているノードにて
  - docker compose stop keepalived
  - (以下、上記同様の更新処理をおこなう)
  - docker compose build
  - docker compose rm -sf keycloak-old
  - ./up.sh keycloak
  - docker compose start keepalived
- Keycloak ログイン中のウェブブラウザはエラーになった。
  - 再度ログインしなおすと正常表示できた。
- jwt-agent は動き続けた。
- TODO user attribute 領域はどうなったか確認 (Keycloak 24 から仕様が変わったので)

### Keycloak バージョンダウンはできない

- 試したところ Web UI でログインできなくなった。
- 対応していないようだ。

### TODO

- パラメータの一元管理
