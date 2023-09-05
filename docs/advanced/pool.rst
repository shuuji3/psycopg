.. currentmodule:: psycopg_pool

..
    .. _connection-pools:
    Connection pools
    ================

.. _connection-pools:

コネクションプール
==================

..
    A `connection pool`__ is an object managing a set of connections and allowing
    their use in functions needing one. Because the time to establish a new
    connection can be relatively long, keeping connections open can reduce latency.

`コネクションプール`__ は、複数のコネクションをまとめて管理し、コネクションが必要なときに関数が利用できるようにするオブジェクトです。新しいコネクションを確立するための時間は相対的に長いため、コネクションをオープンにしておくことでレイテンシを削減できます。

.. __: https://en.wikipedia.org/wiki/Connection_pool

..
    This page explains a few basic concepts of Psycopg connection pool's
    behaviour. Please refer to the `ConnectionPool` object API for details about
    the pool operations.

このページでは、psycopg のコネクションプールの動作について、いくつかの基本的な概念を説明します。プールの操作に関する詳細は、`ConnectionPool` オブジェクト API を参照してください。

..
    .. note:: The connection pool objects are distributed in a package separate
       from the main `psycopg` package: use ``pip install "psycopg[pool]"`` or ``pip
       install psycopg_pool`` to make the `psycopg_pool` package available. See
       :ref:`pool-installation`.

.. note:: コネクションプールオブジェクトはメインの `psycopg` パッケージとは別のパッケージとして配布されています。`psycopg_pool` パッケージを使えるようにするには、``pip install "psycopg[pool]"`` または ``pip
   install psycopg_pool`` を使ってください。詳しくは :ref:`pool-installation` を参照してください。

..
    Pool life cycle
    ---------------

プールのライフサイクル
----------------------

..
    A simple way to use the pool is to create a single instance of it, as a
    global object, and to use this object in the rest of the program, allowing
    other functions, modules, threads to use it::

プールを使うシンプルな方法は、次のようにグローバルオブジェクトとして単一のプールのインスタンスを作り、プログラムの他の場所でこのオブジェクトを使い、他の関数・モジュール・スレッドがプールを使えるようにするという方法です。

..
        # module db.py in your program
        from psycopg_pool import ConnectionPool

        pool = ConnectionPool(conninfo, **kwargs)
        # the pool starts connecting immediately.

        # in another module
        from .db import pool

        def my_function():
            with pool.connection() as conn:
                conn.execute(...)

.. code:: python

    # プログラム内の db.py モジュール
    from psycopg_pool import ConnectionPool

    pool = ConnectionPool(conninfo, **kwargs)
    # プールは直後に接続を開始する

    # 他のモジュール内
    from .db import pool

    def my_function():
        with pool.connection() as conn:
            conn.execute(...)

..
    Ideally you may want to call `~ConnectionPool.close()` when the use of the
    pool is finished. Failing to call `!close()` at the end of the program is not
    terribly bad: probably it will just result in some warnings printed on stderr.
    However, if you think that it's sloppy, you could use the `atexit` module to
    have `!close()` called at the end of the program.

理想的には、プールの使用が完了したときに `~ConnectionPool.close()` を呼び出したいかもしれませんが、プログラムの最後で `!close()` の呼び出しに失敗することは、それほど悪いことではありません。おそらくいくつかの警告が stderr に出力されるだけでしょう。しかし、それがいい加減なことだと感じる場合は、`atexit` モジュールを使用してプログラムの最後に `!close()` を呼び出すこともできます。

..
    If you want to avoid starting to connect to the database at import time, and
    want to wait for the application to be ready, you can create the pool using
    `!open=False`, and call the `~ConnectionPool.open()` and
    `~ConnectionPool.close()` methods when the conditions are right. Certain
    frameworks provide callbacks triggered when the program is started and stopped
    (for instance `FastAPI startup/shutdown events`__): they are perfect to
    initiate and terminate the pool operations::

import 時にデータベースへの接続の開始を避け、アプリケーションの準備ができるのを待ちたい場合には、`!open=False` を使用してプールを作り、条件が正しいときに `~ConnectionPool.open()` と
`~ConnectionPool.close()` メソッドを呼び出せます。特定のフレームワークはプログラムの開始と停止したときにトリガされるコールバックを提供しています (たとえば、`FastAPI の startup/shutdown イベント`__)。これらは、プール操作の開始と終了に最適です。

.. code:: python

    pool = ConnectionPool(conninfo, open=False, **kwargs)

    @app.on_event("startup")
    def open_pool():
        pool.open()

    @app.on_event("shutdown")
    def close_pool():
        pool.close()

.. __: https://fastapi.tiangolo.com/advanced/events/#events-startup-shutdown

..
    Creating a single pool as a global variable is not the mandatory use: your
    program can create more than one pool, which might be useful to connect to
    more than one database, or to provide different types of connections, for
    instance to provide separate read/write and read-only connections. The pool
    also acts as a context manager and is open and closed, if necessary, on
    entering and exiting the context block::

単一のプールをグローバル変数をして作成することは必須ではありません。プログラムでは、2つ以上のプールを作成できます。これは、2つ以上のデータベースに接続したり、異なる種類のコネクション、たとえば readwrite と read-only のコネクションを別に提供する場合に便利です。また、プールはコンテクスト マネージャとして振る舞うため、コンテクスト ブロックに入るときと出るときに、必要に応じてオープンしたりクローズしたりします。

..
    from psycopg_pool import ConnectionPool

    with ConnectionPool(conninfo, **kwargs) as pool:
        run_app(pool)

    # the pool is now closed

.. code:: python

    from psycopg_pool import ConnectionPool

    with ConnectionPool(conninfo, **kwargs) as pool:
        run_app(pool)

    # ここでプールはクローズしている

..
    When the pool is open, the pool's background workers start creating the
    requested `!min_size` connections, while the constructor (or the `!open()`
    method) returns immediately. This allows the program some leeway to start
    before the target database is up and running.  However, if your application is
    misconfigured, or the network is down, it means that the program will be able
    to start, but the threads requesting a connection will fail with a
    `PoolTimeout` only after the timeout on `~ConnectionPool.connection()` is
    expired. If this behaviour is not desirable (and you prefer your program to
    crash hard and fast, if the surrounding conditions are not right, because
    something else will respawn it) you should call the `~ConnectionPool.wait()`
    method after creating the pool, or call `!open(wait=True)`: these methods will
    block until the pool is full, or will raise a `PoolTimeout` exception if the
    pool isn't ready within the allocated time.

プールがオープンすると、プールのバックグラウンドワーカーが要求された `!min_size` のコネクションを作成を開始し、コンストラクタ (または `!open()` メソッド) はすぐに返ります。これにより、ターゲットのデータベースが起動する前にプログラムを開始するための余裕が生まれます。しかし、アプリケーションが正しく設定されていなかったり、ネットワークがダウンしている場合、プログラムが起動できたとしても、コネクションをリクエストしているスレッドが `~ConnectionPool.connection()` のタイムアウトが切れた後にのみ `PoolTimeout` とともに失敗するということです。この動作が望ましくない場合 (周囲の状況が正しくない場合には他の何かがプログラムを再起動するため、プログラムが激しく早くクラッシュしてほしい場合)、プールの作成後に `~ConnectionPool.wait()` メソッドを呼ぶか、`!open(wait=True)` を呼ぶ必要があります。これらのメソッドはプールがフルになるまでブロックするか、もしプールが割り当てられた時間内に ready にならなかった場合は `PoolTimeout` 例外を発生させます。

..
    Connections life cycle
    ----------------------

コネクションのライフサイクル
----------------------------

..
    The pool background workers create connections according to the parameters
    `!conninfo`, `!kwargs`, and `!connection_class` passed to `ConnectionPool`
    constructor, invoking something like :samp:`{connection_class}({conninfo},
    **{kwargs})`. Once a connection is created it is also passed to the
    `!configure()` callback, if provided, after which it is put in the pool (or
    passed to a client requesting it, if someone is already knocking at the door).

プールのバックグラウンド ワーカーは、`ConnectionPool` コンストラクタに渡された `!conninfo`、`!kwargs`、`!connection_class` のパラメータに従って、:samp:`{connection_class}({conninfo},
**{kwargs})` のように実行することでコネクションを作成します。コネクションが一度作成されると、もし与えられた場合には `!configure()` コールバックにも渡され、その後、コネクションはプールに入れられます (または、もし誰かがすでにドアをノックしているなら、コネクションをリクエストしているクライアントに渡されます)。

..
    If a connection expires (it passes `!max_lifetime`), or is returned to the pool
    in broken state, or is found closed by `~ConnectionPool.check()`), then the
    pool will dispose of it and will start a new connection attempt in the
    background.

コネクションが期限切れになった場合 (`!max_lifetime` を超えた場合) や、壊れた状態でプールに戻された場合、`~ConnectionPool.check()` によってクローズしていることがわかった場合、プールはそのコネクションを破棄し、新しいコネクションの開始をバックグラウンドで試みます。

..
    Using connections from the pool
    -------------------------------

プールからコネクションを使用する
-----------------------------------

..
    The pool can be used to request connections from multiple threads or
    concurrent tasks - it is hardly useful otherwise! If more connections than the
    ones available in the pool are requested, the requesting threads are queued
    and are served a connection as soon as one is available, either because
    another client has finished using it or because the pool is allowed to grow
    (when `!max_size` > `!min_size`) and a new connection is ready.

プールは複数のスレッドや並行タスクからコネクションをリクエストするために使えます――ほとんど役に立たないでしょう！ プール内で使用できるより多くのコネクションがリクエストされた場合、リクエストしているスレッドはキューに入れられ、別のクライアントが使用を完了したか、プールの拡大が許可されているので (`!max_size` > `!min_size` の場合) 新しいコネクションの準備ができる場合、利用可能になるとすぐにコネクションが提供されます。

..
    The main way to use the pool is to obtain a connection using the
    `~ConnectionPool.connection()` context, which returns a `~psycopg.Connection`
    or subclass::

プールの主な使用方法は、次のように `~psycopg.Connection` またはそのサブクラスを返す `~ConnectionPool.connection()` コンテクストを使用してコネクションを取得することです。

.. code:: python

    with my_pool.connection() as conn:
        conn.execute("what you want")

..
    The `!connection()` context behaves like the `~psycopg.Connection` object
    context: at the end of the block, if there is a transaction open, it will be
    committed, or rolled back if the context is exited with as exception.

`!connection()` コンテクストは `~psycopg.Connection` オブジェクトのコンテクストのように振る舞います。ブロックの終わりでもしオープンなトランザクションが存在する場合、トランザクションはコミットされるか、コンテクストが例外とともに終了した場合はロールバックされます。

..
    At the end of the block the connection is returned to the pool and shouldn't
    be used anymore by the code which obtained it. If a `!reset()` function is
    specified in the pool constructor, it is called on the connection before
    returning it to the pool. Note that the `!reset()` function is called in a
    worker thread, so that the thread which used the connection can keep its
    execution without being slowed down by it.

ブロックの終わりで、コネクションはプールに返され、そのコネクションを取得したコードにはもう使用されません。もしプールのコンストラクタで `!reset()` 関数が指定されていた場合、プールに返される前にコネクションで呼ばれます。`!reset()` 関数は、コネクションを使用したスレッドが遅くならならずに実行を続けられるようにするため、ワーカースレッド内で呼ばれることに注意してください。

..
    Pool connection and sizing
    --------------------------

プールのコネクションとサイズ
----------------------------

..
    A pool can have a fixed size (specifying no `!max_size` or `!max_size` =
    `!min_size`) or a dynamic size (when `!max_size` > `!min_size`). In both
    cases, as soon as the pool is created, it will try to acquire `!min_size`
    connections in the background.

プールは固定サイズにすることも (`!max_size` を設定しない、または `!max_size` = `!min_size` に設定する)、動的なサイズにすることもできます (`!max_size` > `!min_size` に設定する)。いずれの場合でも、プールが作成されるとすぐに、バックグラウンドで `!min_size` のコネクションの獲得を試行します。

..
    If an attempt to create a connection fails, a new attempt will be made soon
    after, using an exponential backoff to increase the time between attempts,
    until a maximum of `!reconnect_timeout` is reached. When that happens, the pool
    will call the `!reconnect_failed()` function, if provided to the pool, and just
    start a new connection attempt. You can use this function either to send
    alerts or to interrupt the program and allow the rest of your infrastructure
    to restart it.

コネクション作成の試行が失敗した場合、新しい試行が直後に行われます。この時、試行の時間間隔は、指数的バックオフ (exponential backoff) を使用して、`!reconnect_timeout` の最大値に到達するまで増やされます。最大値に到達してしまった場合、もし提供されていればプールが `!reconnect_failed()` 関数を呼び出し、そのまま新しいコネクションの試行が始まります。この関数はアラートの送信やプログラムの中断のために使用することができ、これにより残りのインフラストラクチャが再起動できるようになります。

..
    If more than `!min_size` connections are requested concurrently, new ones are
    created, up to `!max_size`. Note that the connections are always created by the
    background workers, not by the thread asking for the connection: if a client
    requests a new connection, and a previous client terminates its job before the
    new connection is ready, the waiting client will be served the existing
    connection. This is especially useful in scenarios where the time to establish
    a connection dominates the time for which the connection is used (see `this
    analysis`__, for instance).

`!min_size` より大きな数のコネクションが並行してリクエストされた場合、新しいコネクションは最大 `!max_size` まで作られます。コネクションは常にバックグラウンド ワーカーによって作らるのであっれ、コネクションをリクエストしているスレッドで作られるわけではないことに注意してください。もしクライアントが新しいコネクションをリクエストしたら、1つ前のクライアントは新しいコネクションの準備ができる前にジョブを終了します。この動作は、コネクションを使用する時間に対して、コネクションを確立するための時間のほうが支配的なシナリオで特に役に立ちます (たとえば、`この分析`__ を参照してください)。

.. __: https://github.com/brettwooldridge/HikariCP/blob/dev/documents/
       Welcome-To-The-Jungle.md

..
    If a pool grows above `!min_size`, but its usage decreases afterwards, a number
    of connections are eventually closed: one every time a connection is unused
    after the `!max_idle` time specified in the pool constructor.

プールが `!min_size` を超えて大きくなっても、その後その使用量が減少した場合には、最終的には多数のコネクションが閉じられます。つまり、プール コンストラクターで指定された `!max_idle` 時間が経過した後にコネクションが未使用であれば、そのたびに1つずつコネクションが閉じられます。

..
    What's the right size for the pool?
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

プールの正しいサイズは何ですか？
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

..
    Big question. Who knows. However, probably not as large as you imagine. Please
    take a look at `this analysis`__ for some ideas.

巨大な質問です。誰にもわからないでしょう。しかし、おそらく想像するほど大きくはありません。何かアイデアを得るためには  `この分析`__ を見てください。

.. __: https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing

..
    Something useful you can do is probably to use the
    `~ConnectionPool.get_stats()` method and monitor the behaviour of your program
    to tune the configuration parameters. The size of the pool can also be changed
    at runtime using the `~ConnectionPool.resize()` method.

何か役に立つことができるとしたら、おそらく `~ConnectionPool.get_stats()` メソッドを使ってプログラムの動作をモニタリング
し、設定のパラメータをチューニングすることでしょう。プールのサイズは `~ConnectionPool.resize()` メソッドを使えばランタイム時にも変更できます。

..
    .. _null-pool:

    Null connection pools
    ---------------------

.. _null-pool:

Null コネクション プール
------------------------

.. versionadded:: 3.1

..
    Sometimes you may want leave the choice of using or not using a connection
    pool as a configuration parameter of your application. For instance, you might
    want to use a pool if you are deploying a "large instance" of your application
    and can dedicate it a handful of connections; conversely you might not want to
    use it if you deploy the application in several instances, behind a load
    balancer, and/or using an external connection pool process such as PgBouncer.

ときには、コネクションプールを使うか使わないかの選択を、アプリケーションの設定パラメータに委ねたいことがあります。たとえば、アプリケーションの「大きなインスタンス」をデプロイするときにはプールを使い、アプリケーションを複数のコネクションに割り当てられるようにしたくなるかもしれません。逆に、アプリケーションをロードバランサーの背後の複数のインスタンスにデプロイする場合や、PgBouncer のような外部のコネクション プール プロセスを使用する場合には、プールを使用しなくないかもしれません。

..
    Switching between using or not using a pool requires some code change, because
    the `ConnectionPool` API is different from the normal `~psycopg.connect()`
    function and because the pool can perform additional connection configuration
    (in the `!configure` parameter) that, if the pool is removed, should be
    performed in some different code path of your application.

`ConnectionPool` の API は通常の `~psycopg.connect()` 関数と異なるため、また、プールは追加のコネクション設定 (`!configure` パラメータ内で) を実行でき、プールが削除された場合には一部でアプリケーションの異なるコードパスを実行する必要があるため、プールの使用と未使用を切り替えるには何らかのコード変更が必要になります。

..
    The `!psycopg_pool` 3.1 package introduces the `NullConnectionPool` class.
    This class has the same interface, and largely the same behaviour, of the
    `!ConnectionPool`, but doesn't create any connection beforehand. When a
    connection is returned, unless there are other clients already waiting, it
    is closed immediately and not kept in the pool state.

`!psycopg_pool` 3.1 パッケージは新たに `NullConnectionPool` クラスを導入しています。このクラスは `!ConnectionPool` と同じインターフェイスを持ち、そしてほとんど同じ動作をしますが、事前にコネクションを1つも作成しません。コネクションが返されると、他のクライアントがすでに待機していない限り、そのコネクションは直ちにクローズされ、プールの中に入れられた状態のままにはなりません。

..
    A null pool is not only a configuration convenience, but can also be used to
    regulate the access to the server by a client program. If `!max_size` is set to
    a value greater than 0, the pool will make sure that no more than `!max_size`
    connections are created at any given time. If more clients ask for further
    connections, they will be queued and served a connection as soon as a previous
    client has finished using it, like for the basic pool. Other mechanisms to
    throttle client requests (such as `!timeout` or `!max_waiting`) are respected
    too.

null プールは、設定の利便性のためだけではなく、クライアントプログラムによるサーバーへのサクセスを制限するためにも利用できます。`!max_size` が 0 より大きい値に設定された場合、プールは最大 `!max_size` のコネクションが作成されることを常に保証します。クライアントがさらにコネクションを要求した場合には、通常のプールと同じように、クライアントはキューに入れられ、前のクライアントがコネクションを使い終わったらすぐにコネクションが与えられます。クライアントのリクエストをスロットルする他の仕組み (`!timeout` や `!max_waiting` など) も尊重されます。

..
    .. note::

        Queued clients will be handed an already established connection, as soon
        as a previous client has finished using it (and after the pool has
        returned it to idle state and called `!reset()` on it, if necessary).

.. note::

    キューに入れられたクライアントは、前のクライアントがコネクションの使用を完了したら (そして、プールがコネクションをアイドル状態に戻し、必要な場合にはコネクションで `!reset()` を呼んだら) すぐに、すでに確立されたコネクションで処理されます。

..
    Because normally (i.e. unless queued) every client will be served a new
    connection, the time to obtain the connection is paid by the waiting client;
    background workers are not normally involved in obtaining new connections.

通常 (つまり、キューに入れられていない限り)、すべてのクライアントには新しいコネクションが与えられるため、コネクションを獲得する時間はクライアントの待機によってすでに償却されており、普通はバックグラウンド ワーカーは新しいコネクションの取得には関与しません。

..
    Connection quality
    ------------------

コネクションの品質
------------------

..
    The state of the connection is verified when a connection is returned to the
    pool: if a connection is broken during its usage it will be discarded on
    return and a new connection will be created.

コネクションの状態は、コネクションがプールに返ってきたときに検証されます。コネクションが使用中に壊れた場合は、変換時に破棄されて新しいコネクションが作られます。

..
    .. warning::

        The health of the connection is not checked when the pool gives it to a
        client.

.. warning::

    プールがクライアントにコネクションを渡すときには、コネクションの状態は確認されません。

..
    Why not? Because doing so would require an extra network roundtrip: we want to
    save you from its latency. Before getting too angry about it, just think that
    the connection can be lost any moment while your program is using it. As your
    program should already be able to cope with a loss of a connection during its
    process, it should be able to tolerate to be served a broken connection:
    unpleasant but not the end of the world.

なぜ確認しないのでしょうか？ なぜなら、確認するには追加のネットワークラウンドトリップが必要になってしまうからです。そのレイテンシから救いたいのです。レイテンシに怒りが湧いてしまう前に、プログラムがコネクションを使用している間、いつでもコネクションが失われる可能性があると考えてください。プログラムはすでに処理中のコネクションの喪失に対処できるはずなので、コネクションが壊れても耐えられるはずです。喜ばしくないことですが、世界の終わりではありません。

..
    .. warning::

        The health of the connection is not checked when the connection is in the
        pool.

.. warning::

    コネクションがプール内にあるときには、コネクションの状態は確認されません。

..
    Does the pool keep a watchful eye on the quality of the connections inside it?
    No, it doesn't. Why not? Because you will do it for us! Your program is only
    a big ruse to make sure the connections are still alive...

プールは、プール内のコネクションの品質に常に目を光らせ続けるのでしょうか？ いいえ、そうではありません。なぜでしょうか？ なぜなら、あなたが代わりに確認してくれるからです！ あなたのプログラムが、コネクションがまだ生きていることを確認するための手段として利用されるのです……。(Your program is only a big ruse to make sure the connections are still alive...)

..
    Not (entirely) trolling: if you are using a connection pool, we assume that
    you are using and returning connections at a good pace. If the pool had to
    check for the quality of a broken connection before your program notices it,
    it should be polling each connection even faster than your program uses them.
    Your database server wouldn't be amused...

(完全な) 冗談ではありません。コネクションプールを使用している場合は、コネクションの使用と返却がよいペースで行われることが想定されています。仮にプログラムが気づくより前に、プールが壊れたコネクションの品質をチェックする必要があったとしたら、プログラムが使用するよりもさらに早く、各コネクションをポーリングしなければなくなってしまいます。もしそのようなことをしたら、データベース サーバーは喜ばないでしょう……。

..
    Can you do something better than that? Of course you can, there is always a
    better way than polling. You can use the same recipe of :ref:`disconnections`,
    reserving a connection and using a thread to monitor for any activity
    happening on it. If any activity is detected, you can call the pool
    `~ConnectionPool.check()` method, which will run a quick check on each
    connection in the pool, removing the ones found in broken state, and using the
    background workers to replace them with fresh ones.

何かもっとよいことはできないのでしょうか？ もちろんできます。ポーリングよりよい方法は常にあります。:ref:`disconnections` と同じレシピが使えるのです。つまり、コネクションを予約して、スレッドを使用してスレッド上のアクティビティをモニタリングするという方法です。もしアクティビティが検出されれば、プールの `~ConnectionPool.check()` メソッドが呼べます。このメソッドは、プール内の各コネクションに素早いチェックを実行し、壊れた状態であることがわかったコネクションを削除し、バックグラウンド ワーカーを使用して新しいコネクションと置換します。

..
    If you set up a similar check in your program, in case the database connection
    is temporarily lost, we cannot do anything for the threads which had taken
    already a connection from the pool, but no other thread should be served a
    broken connection, because `!check()` would empty the pool and refill it with
    working connections, as soon as they are available.

データベース コネクションが一時的に失われる場合に備えて、プログラム内で同様のチェックをセットアップした場合は、プールからすでにコネクションを取り出したスレッドに対してできることは何もありませんが、他のスレッドに壊れたコネクションが与えられることもないはずです。なぜなら、`!check()` がプールを空にして、コネクションが利用できるようになったらすぐに、機能するコネクションでプールを補填するためです。

..
    Faster than you can say poll. Or pool.

「ポール」と口で言うよりも早いでしょう。あるいは「プール」と。

.. _idle-session-timeout:

..
    Pool and ``idle_session_timeout`` setting
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

プールと ``idle_session_timeout`` 設定
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

..
    Using a connection pool is fundamentally incompatible with setting an
    `idle_session_timeout`__ on the connection: the pool is designed precisely to
    keep connections idle and readily available.

コネクションプールの使用は、コネクション上に `idle_session_timeout`__ を設定することと根本的に相容れません。プールはまさにコネクションを idle にしておき、素早く利用可能にするようにデザインされているためです。

.. __: https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-IDLE-SESSION-TIMEOUT

..
    The current implementation doesn't keep ``idle_session_timeout`` into account,
    so, if this setting is used, clients might be served broken connections and
    fail with an error such as *terminating connection due to idle-session
    timeout*.

現在の実装は ``idle_session_timeout`` を考慮していません。そのため、もしこの設定が使われたら、クライアントは壊れたコネクションを提供される可能性があり、*terminating connection due to idle-session timeout* (idle セッション タイムアウトが原因でコネクションが終了している) のようなエラーで失敗するかもしれません。

..
    In order to avoid the problem, please disable ``idle_session_timeout`` for the
    pool connections. Note that, even if your server is configured with a nonzero
    ``idle_session_timeout`` default, you can still obtain pool connections
    without timeout, by using the `!options` keyword argument, for instance::

この問題を避けるためには、プール コネクションに対して ``idle_session_timeout`` を無効化してください。たとえサーバーが ``idle_session_timeout`` のデフォルトを 0 以外に設定したとしても、たとえば次のように `!options` キーワード引数を使用することで、タイムアウトなしにプール コネクションを獲得できることに注意してください。

    p = ConnectionPool(conninfo, kwargs={"options": "-c idle_session_timeout=0"})

..
    .. warning::

        The `!max_idle` parameter is currently only used to shrink the pool if
        there are unused connections; it is not designed to fight against a server
        configured to close connections under its feet.

.. warning::

    現在 `!max_idle` パラメータは、未使用のコネクションが存在した場合にプールを縮小するためにのみ使われています。コネクションをクローズするように設定されたサーバーと戦うためには設計されていません。

..
    .. _pool-stats:

    Pool stats
    ----------

.. _pool-stats:

プールの統計
------------

プールで `~ConnectionPool.get_stats()` または `~ConnectionPool.pop_stats()` メソッドを使うと、プール自身の使用に関する情報を返せます。どちらのメソッドも同じ値を返しますが、後者は使用後にカウンターをリセットします。値は Graphite_ や Prometheus_ などのモニタリングシステムに送信できます。

.. _Graphite: https://graphiteapp.org/
.. _Prometheus: https://prometheus.io/

..
    The following values should be provided, but please don't consider them as a
    rigid interface: it is possible that they might change in the future. Keys
    whose value is 0 may not be returned.

以下の値が提供されるはずですが、厳格なインターフェイスだとは考えないでください。将来、変更される可能性があります。値が 0 のキーは返されないことがあります。

======================= =====================================================
メトリック                意味
======================= =====================================================
 ``pool_min``           `~ConnectionPool.min_size` の現在の値
 ``pool_max``           `~ConnectionPool.max_size` の現在の値
 ``pool_size``          現在プールで管理されているコネクションの数
                        (プール内の数, クライアントに与えられた数, 準備中の数)
 ``pool_available``     プール内で現在アイドル状態のコネクションの数
 ``requests_waiting``   コネクションを受け取るために現在キューの中で待機しているリクエスト数
 ``usage_ms``           プール外でコネクションの合計使用時間
 ``requests_num``       プールにリクエストされたコネクションの数
 ``requests_queued``    コネクションがプールで直ちに利用可能ではなかったためにキューに入れられたリクエスト数
 ``requests_wait_ms``   キューの中でのクライアントの合計待機時間
 ``requests_errors``    結果がエラーになったコネクションのリクエスト数
                        (タイムアウト, キューがフル...)
 ``returns_bad``        悪い状態でプールに返却されたコネクションの数
 ``connections_num``    プールからサーバーに試みられたコネクションの数
 ``connections_ms``     サーバーとコネクションを確立するために消費された合計時間
 ``connections_errors`` 失敗したコネクションの試行数
 ``connections_lost``   `~ConnectionPool.check()` によって特定された失われたコネクションの数

======================= =====================================================
