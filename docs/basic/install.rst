..
    .. _installation:

    Installation
    ============

.. _installation:

インストール
============

..
    In short, if you use a :ref:`supported system<supported-systems>`::

簡潔に言うと、:ref:`サポートされているシステム <supported-systems>` を使っている場合は、次のコマンドでインストールできます。

..
    pip install --upgrade pip           # upgrade pip to at least 20.3
    pip install "psycopg[binary]"

.. code:: shell

    pip install --upgrade pip           # pip を 20.3 以上にアップグレードする
    pip install "psycopg[binary]"

..
    and you should be :ref:`ready to start <module-usage>`. Read further for
    alternative ways to install.

これで、:ref:`始める準備ができた <module-usage>` はずです。他のインストール方法については、続きを読み進めてください。

..
    .. _supported-systems:

    Supported systems
    -----------------

.. _supported-systems:

サポートされているシステム
--------------------------

..
    The Psycopg version documented here has *official and tested* support for:

ここにドキュメントされている psycopg のバージョンは、以下の環境で *公式かつテスト済みで* サポートされます。

..
    - Python: from version 3.7 to 3.11

      - Python 3.6 supported before Psycopg 3.1

    - PostgreSQL: from version 10 to 15
    - OS: Linux, macOS, Windows

- Python: バージョン 3.7 から 3.11

  - Python 3.6 は psycopg 3.1 より前までサポートされていました

- PostgreSQL: バージョン 10 から 15
- OS: Linux、macOS、Windows

..
    The tests to verify the supported systems run in `Github workflows`__:
    anything that is not tested there is not officially supported. This includes:

サポートされたシステムを検証するテストは `Github workflows`__ で実行されています。そこでテストされていないものはすべて公式にはサポートされません。これには、次のものが含まれます。

.. __: https://github.com/psycopg/psycopg/actions

..
    - Unofficial Python distributions such as Conda;
    - Alternative PostgreSQL implementation;
    - macOS hardware and releases not available on Github workflows.

- Conda などの非公式の Python ディストリビューション
- PostgreSQL の代替実装
- GitHub ワークフローで利用可能ではない macOS ハードウェアおよびリリース

..
    If you use an unsupported system, things might work (because, for instance, the
    database may use the same wire protocol as PostgreSQL) but we cannot guarantee
    the correct working or a smooth ride.

サポートされていないシステムで使用した場合でも、動作するかもしれません (なぜなら、たとえば、データベースが PostgreSQL と同一のワイヤープロトコルを使用しているかもしれないため) が、正しい動作や快適な使い勝手は保証できません。

..
    .. _binary-installation:

    Binary installation
    -------------------

.. _binary-installation:

バイナリのインストール
----------------------

..
    The quickest way to start developing with Psycopg 3 is to install the binary
    packages by running::

psycopg 3 を使用して開発を始める最も早い方法は、次のようにバイナリパッケージをインストールすることです。

.. code:: shell

    pip install "psycopg[binary]"

..
    This will install a self-contained package with all the libraries needed.
    **You will need pip 20.3 at least**: please run ``pip install --upgrade pip``
    to update it beforehand.

これにより、必要なすべてのライブラリが同梱された自己完結のパッケージがインストールされます。**最低でも pip 20.3 が必要です**。``pip install --upgrade pip`` を実行して事前にアップデートしてください。

..
    The above package should work in most situations. It **will not work** in
    some cases though.

上のパッケージはほとんどの状況で動作するはずです。ただし、いくつかの場合には **動作しません**。

..
    If your platform is not supported you should proceed to a :ref:`local
    installation <local-installation>` or a :ref:`pure Python installation
    <pure-python-installation>`.

プラットフォームがサポートされていない場合、:ref:`ローカル インストール <local-installation>` か :ref:`純粋な Python インストール <pure-python-installation>` に進んでください。

..
    .. seealso::

        Did Psycopg 3 install ok? Great! You can now move on to the :ref:`basic
        module usage <module-usage>` to learn how it works.

        Keep on reading if the above method didn't work and you need a different
        way to install Psycopg 3.

        For further information about the differences between the packages see
        :ref:`pq-impl`.

.. seealso::

    psycopg 3 は上手くインストールできましたか？ 素晴らしい！ これで :ref:`module-usage` に進んで動作方法が学べます。

    上記のメソッドが上手く動作しない場合は、読み進めて、他の方法で psycopg 3 をインストールする必要があります。

    パッケージ間の違いについての詳しい情報は、:ref:`pq-impl` を参照してください。

..
    .. _local-installation:

    Local installation
    ------------------

.. _local-installation:

ローカル インストール
---------------------

..
    A "Local installation" results in a performing and maintainable library. The
    library will include the speed-up C module and will be linked to the system
    libraries (``libpq``, ``libssl``...) so that system upgrade of libraries will
    upgrade the libraries used by Psycopg 3 too. This is the preferred way to
    install Psycopg for a production site.

「ローカル インストール」により、機能するメンテナンス可能なライブラリが得られます。ライブラリはスピードアップのための C モジュールを含み、ライブラリのシステム アップグレードが psycopg 3 でも使われているライブラリをアップグレードできるように、システム ライブラリ (``libpq``, ``libssl``...) にリンクされます。これは psycopg を本番環境にインストールするための望ましい方法です。

..
    In order to perform a local installation you need some prerequisites:

ローカル インストールを実行するためには、いくつかの前提条件が必要です。

..
    - a C compiler,
    - Python development headers (e.g. the ``python3-dev`` package).
    - PostgreSQL client development headers (e.g. the ``libpq-dev`` package).
    - The :program:`pg_config` program available in the :envvar:`PATH`.

- C コンパイラ。
- Python development ヘッダ (たとえば、``python3-dev`` パッケージ)。
- PostgreSQL クライアント development ヘッダ (たとえば、``libpq-dev`` パッケージ)。
- :program:`pg_config` プログラムが :envvar:`PATH` で利用可能であること。

..
    You **must be able** to troubleshoot an extension build, for instance you must
    be able to read your compiler's error message. If you are not, please don't
    try this and follow the `binary installation`_ instead.

あなたは extension のビルドのトラブルシューティングが **できなければいけません**。たとえば、あなたはコンパイラのエラーメッセージを読んで理解できる必要があります。もしそれができないなら、この方法を試すのはやめて、代わりに `binary-installation`_ に従ってください。

..
    If your build prerequisites are in place you can run::

ビルドの前提条件が満たされていれば、次のコマンドが実行できます。

.. code:: shell

    pip install "psycopg[c]"

..
    .. _pure-python-installation:

    Pure Python installation
    ------------------------

.. _pure-python-installation:

純粋な Python インストール
--------------------------

..
    If you simply install::

単純に以下のコマンドでインストールした場合

.. code:: shell

    pip install psycopg

..
    without ``[c]`` or ``[binary]`` extras you will obtain a pure Python
    implementation. This is particularly handy to debug and hack, but it still
    requires the system libpq to operate (which will be imported dynamically via
    `ctypes`).

extras に ``[c]`` や ``[binary]`` を指定しなければ、純粋な Python 実装が取得されます。これは特にデバッグやハックのためには便利ですが、操作するためには依然としてシステム上に libpq が必要です (`ctypes` 経由で動的にインポートされます)。

..
    In order to use the pure Python installation you will need the ``libpq``
    installed in the system: for instance on Debian system you will probably
    need::

純粋な Python インストールを使用するためには、``libpq`` がシステムにインストールされている必要があります。たとえば、Debian システムではおそらく以下のコマンドを実行する必要があります。

.. code:: shell

    sudo apt install libpq5

..
    .. note::

        The ``libpq`` is the client library used by :program:`psql`, the
        PostgreSQL command line client, to connect to the database.  On most
        systems, installing :program:`psql` will install the ``libpq`` too as a
        dependency.

.. note::

    ``libpq`` は、PostgreSQL コマンドラインクライアントの :program:`psql` がデータベースに接続するために使用するクライアントライブラリです。ほとんどのシステムでは、:program:`psql` をインストールすると依存関係として ``libpq`` もインストールされます。

..
    If you are not able to fulfill this requirement please follow the `binary
    installation`_.

この要件を満たせない場合は、`binary-installation`_ に従ってください。

..
    .. _pool-installation:

    Installing the connection pool
    ------------------------------

.. _pool-installation:

コネクションプールのインストール
--------------------------------

..
    The :ref:`Psycopg connection pools <connection-pools>` are distributed in a
    separate package from the `!psycopg` package itself, in order to allow a
    different release cycle.

:ref:`Psycopg のコネクション プール <connection-pools>` は、異なるリリースサイクルを可能にするために、`!psycopg` パッケージ自体とは独立して配布されています。

..
    In order to use the pool you must install the ``pool`` extra, using ``pip
    install "psycopg[pool]"``, or install the `psycopg_pool` package separately,
    which would allow to specify the release to install more precisely.

プールを使用するためには、``pip install "psycopg[pool]"`` コマンドを実行して ``pool`` extra をインストールするか、`psycopg_pool` パッケージを別にインストールする必要があります。`psycopg_pool` を使用するとインストールするリリースをより詳細に指定できます。

..
    Handling dependencies
    ---------------------

依存関係の処理
---------------------

..
    If you need to specify your project dependencies (for instance in a
    ``requirements.txt`` file, ``setup.py``, ``pyproject.toml`` dependencies...)
    you should probably specify one of the following:

プロジェクトの依存関係を指定する必要がある場合 (たとえば、``requirements.txt``、``setup.py``、``pyproject.toml`` ファイルの依存関係として)、おそらく以下のいずれか1つを指定する必要があります。

..
    - If your project is a library, add a dependency on ``psycopg``. This will
      make sure that your library will have the ``psycopg`` package with the right
      interface and leaves the possibility of choosing a specific implementation
      to the end user of your library.

- プロジェクトがライブラリである場合、``psycopg`` を依存関係として追加する。これにより、ライブラリが正しいインターフェイスを持つ ``psycopg`` パッケージをインストールし、ライブラリのエンドユーザーに特定の実装を選択できる可能性を残せます。

..
    - If your project is a final application (e.g. a service running on a server)
      you can require a specific implementation, for instance ``psycopg[c]``,
      after you have made sure that the prerequisites are met (e.g. the depending
      libraries and tools are installed in the host machine).

- プロジェクトが最終的なアプリケーションである場合 (たとえば、サーバー上で実行されるサービスなど)、前提条件が満たされていることを確認した後 (たとえば、依存ライブラリとツールがホストマシンにインストールされていることなど)、``psycopg[c]`` などの特定の実装を要求できます。

..
    In both cases you can specify which version of Psycopg to use using
    `requirement specifiers`__.

いずれの場合でも、`requirement specifiers`__ を利用することで、使用する psycopg のバージョンを指定できます。

.. __: https://pip.pypa.io/en/stable/cli/pip_install/#requirement-specifiers

..
    If you want to make sure that a specific implementation is used you can
    specify the :envvar:`PSYCOPG_IMPL` environment variable: importing the library
    will fail if the implementation specified is not available. See :ref:`pq-impl`.

特定の実装が使用されることを保証したい場合、:envvar:`PSYCOPG_IMPL` 環境変数を指定できます。これにより、指定された実装が利用できない場合にライブラリのインポートが失敗するようになります。詳しくは :ref:`pq-impl` 参照してください。
