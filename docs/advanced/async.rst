.. currentmodule:: psycopg

.. index:: asyncio

.. _async:

..
    Asynchronous operations
    =======================

非同期操作
==========

..
    Psycopg `~Connection` and `~Cursor` have counterparts `~AsyncConnection` and
    `~AsyncCursor` supporting an `asyncio` interface.

Psycopg の `~Connection` と `~Cursor` には、対応する `~AsyncConnection` と
`~AsyncCursor` があり、`asyncio` インターフェイスをサポートしています。

..
    The design of the asynchronous objects is pretty much the same of the sync
    ones: in order to use them you will only have to scatter the `!await` keyword
    here and there.

非同期オブジェクトのデザインは、同期オブジェクトとほぼ同じです。つまり、非同期オブジェクトを使用するために必要なのは、あちこちに `!await` キーワードを散りばめることだけです。

.. code:: python

    async with await psycopg.AsyncConnection.connect(
            "dbname=test user=postgres") as aconn:
        async with aconn.cursor() as acur:
            await acur.execute(
                "INSERT INTO test (num, data) VALUES (%s, %s)",
                (100, "abc'def"))
            await acur.execute("SELECT * FROM test")
            await acur.fetchone()
            # (1, 100, "abc'def") を返します
            async for record in acur:
                print(record)

..
    .. versionchanged:: 3.1

        `AsyncConnection.connect()` performs DNS name resolution in a non-blocking
        way.

        .. warning::

            Before version 3.1, `AsyncConnection.connect()` may still block on DNS
            name resolution. To avoid that you should `set the hostaddr connection
            parameter`__, or use the `~psycopg._dns.resolve_hostaddr_async()` to
            do it automatically.

            .. __: https://www.postgresql.org/docs/current/libpq-connect.html
                   #LIBPQ-PARAMKEYWORDS

.. versionchanged:: 3.1

    `AsyncConnection.connect()` は DNS の名前解決をノンブロッキングな方法で行います。

    .. warning::

        バージョン 3.1 より前では、`AsyncConnection.connect()` は DNS の名前解決でブロックされる可能性があります。それを避けるには、`hostaddr 接続パラメータを設定`__ するか、これを自動化するために `~psycopg._dns.resolve_hostaddr_async()` を使用する必要があります。

        .. __: https://www.postgresql.org/docs/current/libpq-connect.html
               #LIBPQ-PARAMKEYWORDS

..
    .. warning::

        On Windows, Psycopg is not compatible with the default
        `~asyncio.ProactorEventLoop`. Please use a different loop, for instance
        the `~asyncio.SelectorEventLoop`.

        For instance, you can use, early in your program:

        .. parsed-literal::

            `asyncio.set_event_loop_policy`\ (
                `asyncio.WindowsSelectorEventLoopPolicy`\ ()
            )

.. warning::

    Windows では、Psycopg はデフォルトの `~asyncio.ProactorEventLoop` と互換性がありません。たとえば、
    `~asyncio.SelectorEventLoop` などの別のループを使ってください。

    たとえば、プログラムの初期で次のように使用できます。

    .. parsed-literal::

        `asyncio.set_event_loop_policy`\ (
            `asyncio.WindowsSelectorEventLoopPolicy`\ ()
        )

.. index:: with

.. _async-with:

..
    `!with` async connections
    -------------------------

`!with` async コネクション
--------------------------

..
    As seen in :ref:`the basic usage <usage>`, connections and cursors can act as
    context managers, so you can run:

:ref:`基本的な使い方 <usage>` で見たように、コネクションとカーソルはコンテクストマネージャとして振る舞えるため、次のように実行できます。

..
    .. code:: python

        with psycopg.connect("dbname=test user=postgres") as conn:
            with conn.cursor() as cur:
                cur.execute(...)
            # the cursor is closed upon leaving the context
        # the transaction is committed, the connection closed

.. code:: python

    with psycopg.connect("dbname=test user=postgres") as conn:
        with conn.cursor() as cur:
            cur.execute(...)
        # コンテクストを離れるとすぐカーソルがクローズされる
    # トランザクションがコミットされて、コネクションが閉じる

..
    For asynchronous connections it's *almost* what you'd expect, but
    not quite. Please note that `~Connection.connect()` and `~Connection.cursor()`
    *don't return a context*: they are both factory methods which return *an
    object which can be used as a context*. That's because there are several use
    cases where it's useful to handle the objects manually and only `!close()` them
    when required.

非同期のコネクションは *ほとんど* 期待通りのものですが、完全ではありません。`~Connection.connect()` と `~Connection.cursor()` は *コンテクストを返さない* ということに注意してください。どちらも *コンテクストとして使用できるオブジェクト* を返すファクトリーメソッドです。なぜなら、主導でオブジェクトを処理して必要なときにだけ `！close()` した便利なユースケースがいくつかあるためです。

..
    As a consequence you cannot use `!async with connect()`: you have to do it in
    two steps instead, as in

結果として、 `!async with connect()` を使うことはできず、代わりに次のように2段階で使う必要があります。
two steps instead, as in

？？

.. code:: python

    aconn = await psycopg.AsyncConnection.connect()
    async with aconn:
        async with aconn.cursor() as cur:
            await cur.execute(...)

..
    which can be condensed into `!async with await`:

これはさらに、次のように `!async with await` に短縮できます。

.. code:: python

    async with await psycopg.AsyncConnection.connect() as aconn:
        async with aconn.cursor() as cur:
            await cur.execute(...)

..
    ...but no less than that: you still need to do the double async thing.

しかし、これ以上は短くできません。2重の async をする必要があります。

..
    Note that the `AsyncConnection.cursor()` function is not an `!async` function
    (it never performs I/O), so you don't need an `!await` on it; as a consequence
    you can use the normal `async with` context manager.

`AsyncConnection.cursor()` 関数は `!async` 関数ではないため (決して I/O を実行しません)、そこに `!await` が必要ないことに注意してください。結果として、普通の `async with` コンテクストマネージャが使用できます。

.. index:: Ctrl-C

.. _async-ctrl-c:

..
    Interrupting async operations
    -----------------------------

非同期操作の中断
----------------

..
    If a long running operation is interrupted by a Ctrl-C on a normal connection
    running in the main thread, the operation will be cancelled and the connection
    will be put in error state, from which can be recovered with a normal
    `~Connection.rollback()`.

メインスレッドで実行されている普通のコネクション上の Ctrl-C によって、長時間実行中の操作が中断された場合、操作はキャンセルされ、コネクションはエラー状態になります。エラー状態からは、通常の `~Connection.rollback()` で回復できます。

..
    An async connection provides similar behavior in that if the async task is
    cancelled, any operation on the connection will similarly be cancelled.  This
    can happen either indirectly via Ctrl-C or similar signal, or directly by
    cancelling the Python Task via the normal way.  Psycopg will ask the
    PostgreSQL postmaster to cancel the operation when it encounters the standard
    Python `CancelledError`__.

非同期コネクションは同様の動作を提供します。非同期タスクがキャンセルされた場合
そのコネクション上のすべての操作が同様にキャンセルされることに注意してください。
？？
非同期コネクションは、非同期タスクがキャンセルされると、接続上のすべての操作も同様にキャンセルされるという点で同様の動作を提供します。(Google翻訳)
async connection provides similar behavior in that if the async task is
cancelled, any operation on the connection will similarly be cancelled.
キャンセルは、Ctrl-C や同様のシグナルにより間接的に起こることも、通常の方法で Python Task をキャンセルすることで直接的に起こることもあります。psycopg が Python 標準の `CancelledError`__ に遭遇したときは、PostgreSQL の postmaster に操作をキャンセルするように依頼します。

..
    Remember that cancelling the Python Task does not guarantee that the operation
    will not complete, even if the task ultimately exits prematurely due to
    CancelledError.  If you need to know the ultimate outcome of the statement,
    then consider calling `Connection.cancel()` as an alternative to cancelling
    the task.

たとえタスクが最終的に CancelledError により途中で終了した場合でも、Python Task のキャンセルによって操作が完了しないことが保証されないことに注意してください。ステートメントの最終的な結果を知りたい場合は、タスクのキャンセルの代替手段として `Connection.cancel()` を呼び出すことを検討してください。

..
    Previous versions of Psycopg recommended setting up signal handlers to
    manually cancel connections.  This should no longer be necessary.

以前のバージョンの psycopg では、コネクションを手動でキャンセルするためにシグナル ハンドラを設定することが推奨していました。これはもう必要ありません。

.. __: https://docs.python.org/3/library/asyncio-task.html#task-cancellation

.. index::
    pair: Asynchronous; Notifications
    pair: LISTEN; SQL command
    pair: NOTIFY; SQL command

.. _async-messages:

..
    Server messages
    ---------------

サーバー メッセージ
-------------------

..
    PostgreSQL can send, together with the query results, `informative messages`__
    about the operation just performed, such as warnings or debug information.
    Notices may be raised even if the operations are successful and don't indicate
    an error. You are probably familiar with some of them, because they are
    reported by :program:`psql`::

PostgreSQL は、ちょうど実行された操作に関する警告やデバッグ情報などの `参考になるメッセージ`__ を、クエリの結果とともに送ることができます。操作が成功したときでも通知が現れることがありますが、エラーを表しているわけではありません。その一部は次のように :program:`psql` によって報告されるため、おそらく馴染みがあるでしょう。

.. code::

    $ psql
    =# ROLLBACK;
    WARNING:  there is no transaction in progress
    ROLLBACK

.. __: https://www.postgresql.org/docs/current/runtime-config-logging.html
    #RUNTIME-CONFIG-SEVERITY-LEVELS

..
    Messages can be also sent by the `PL/pgSQL 'RAISE' statement`__ (at a level
    lower than EXCEPTION, otherwise the appropriate `DatabaseError` will be
    raised). The level of the messages received can be controlled using the
    client_min_messages__ setting.

メッセージは、`PL/pgSQL の 'RAISE' ステートメント`__ によって送られることもあります(EXCEPTION より低いレベルの場合。それ以外の場合は適切な `DatabaseError` が発生します)。受け取ったメッセージのレベルは client_min_messages__ 設定でコントロールできます。

.. __: https://www.postgresql.org/docs/current/plpgsql-errors-and-messages.html
.. __: https://www.postgresql.org/docs/current/runtime-config-client.html
    #GUC-CLIENT-MIN-MESSAGES

..
    By default, the messages received are ignored. If you want to process them on
    the client you can use the `Connection.add_notice_handler()` function to
    register a function that will be invoked whenever a message is received. The
    message is passed to the callback as a `~errors.Diagnostic` instance,
    containing all the information passed by the server, such as the message text
    and the severity. The object is the same found on the `~psycopg.Error.diag`
    attribute of the errors raised by the server:

デフォルトでは、メッセージは受信後に無視されます。クライアントでメッセージを処理したい場合は、`Connection.add_notice_handler()` 関数を使って、どんなメッセージが送られてきた場合にも呼び出される関数を登録できます。メッセージは、メッセージテキストや severity などのサーバーから渡されたすべての情報を含む `~errors.Diagnostic` のインスタンスとして、そのコールバック関数に渡されます。このオブジェクトは、サーバーによって起こされたエラーの `~psycopg.Error.diag` 属性で見つかるものと同じです。

.. code:: python

    >>> import psycopg

    >>> def log_notice(diag):
    ...     print(f"The server says: {diag.severity} - {diag.message_primary}")

    >>> conn = psycopg.connect(autocommit=True)
    >>> conn.add_notice_handler(log_notice)

    >>> cur = conn.execute("ROLLBACK")
    The server says: WARNING - there is no transaction in progress
    >>> print(cur.statusmessage)
    ROLLBACK

..
    .. warning::

        The `!Diagnostic` object received by the callback should not be used after
        the callback function terminates, because its data is deallocated after
        the callbacks have been processed. If you need to use the information
        later please extract the attributes requested and forward them instead of
        forwarding the whole `!Diagnostic` object.

.. warning::

    コールバック関数が受け取った `!Diagnostic` オブジェクトは、コールバックの処理が完了した後にデータの割り当て解除されるため、コールバック関数の終了後に使用してはいけません。後で情報を使う必要がある場合は、`!Diagnostic` オブジェクト全体を使い回す代わりに、要求された属性を取り出してそれを使ってください。

.. index::
    pair: Asynchronous; Notifications
    pair: LISTEN; SQL command
    pair: NOTIFY; SQL command

.. _async-notify:

Asynchronous notifications
--------------------------

Psycopg allows asynchronous interaction with other database sessions using the
facilities offered by PostgreSQL commands |LISTEN|_ and |NOTIFY|_. Please
refer to the PostgreSQL documentation for examples about how to use this form
of communication.

.. |LISTEN| replace:: :sql:`LISTEN`
.. _LISTEN: https://www.postgresql.org/docs/current/sql-listen.html
.. |NOTIFY| replace:: :sql:`NOTIFY`
.. _NOTIFY: https://www.postgresql.org/docs/current/sql-notify.html

Because of the way sessions interact with notifications (see |NOTIFY|_
documentation), you should keep the connection in `~Connection.autocommit`
mode if you wish to receive or send notifications in a timely manner.

Notifications are received as instances of `Notify`. If you are reserving a
connection only to receive notifications, the simplest way is to consume the
`Connection.notifies` generator. The generator can be stopped using
`!close()`.

.. note::

    You don't need an `AsyncConnection` to handle notifications: a normal
    blocking `Connection` is perfectly valid.

The following example will print notifications and stop when one containing
the ``"stop"`` message is received.

.. code:: python

    import psycopg
    conn = psycopg.connect("", autocommit=True)
    conn.execute("LISTEN mychan")
    gen = conn.notifies()
    for notify in gen:
        print(notify)
        if notify.payload == "stop":
            gen.close()
    print("there, I stopped")

If you run some :sql:`NOTIFY` in a :program:`psql` session:

.. code:: psql

    =# NOTIFY mychan, 'hello';
    NOTIFY
    =# NOTIFY mychan, 'hey';
    NOTIFY
    =# NOTIFY mychan, 'stop';
    NOTIFY

You may get output from the Python process such as::

    Notify(channel='mychan', payload='hello', pid=961823)
    Notify(channel='mychan', payload='hey', pid=961823)
    Notify(channel='mychan', payload='stop', pid=961823)
    there, I stopped

Alternatively, you can use `~Connection.add_notify_handler()` to register a
callback function, which will be invoked whenever a notification is received,
during the normal query processing; you will be then able to use the
connection normally. Please note that in this case notifications will not be
received immediately, but only during a connection operation, such as a query.

.. code:: python

    conn.add_notify_handler(lambda n: print(f"got this: {n}"))

    # meanwhile in psql...
    # =# NOTIFY mychan, 'hey';
    # NOTIFY

    print(conn.execute("SELECT 1").fetchone())
    # got this: Notify(channel='mychan', payload='hey', pid=961823)
    # (1,)


.. index:: disconnections

.. _disconnections:

Detecting disconnections
------------------------

Sometimes it is useful to detect immediately when the connection with the
database is lost. One brutal way to do so is to poll a connection in a loop
running an endless stream of :sql:`SELECT 1`... *Don't* do so: polling is *so*
out of fashion. Besides, it is inefficient (unless what you really want is a
client-server generator of ones), it generates useless traffic and will only
detect a disconnection with an average delay of half the polling time.

A more efficient and timely way to detect a server disconnection is to create
an additional connection and wait for a notification from the OS that this
connection has something to say: only then you can run some checks. You
can dedicate a thread (or an asyncio task) to wait on this connection: such
thread will perform no activity until awaken by the OS.

In a normal (non asyncio) program you can use the `selectors` module. Because
the `!Connection` implements a `~Connection.fileno()` method you can just
register it as a file-like object. You can run such code in a dedicated thread
(and using a dedicated connection) if the rest of the program happens to have
something else to do too.

.. code:: python

    import selectors

    sel = selectors.DefaultSelector()
    sel.register(conn, selectors.EVENT_READ)
    while True:
        if not sel.select(timeout=60.0):
            continue  # No FD activity detected in one minute

        # Activity detected. Is the connection still ok?
        try:
            conn.execute("SELECT 1")
        except psycopg.OperationalError:
            # You were disconnected: do something useful such as panicking
            logger.error("we lost our database!")
            sys.exit(1)

In an `asyncio` program you can dedicate a `~asyncio.Task` instead and do
something similar using `~asyncio.loop.add_reader`:

.. code:: python

    import asyncio

    ev = asyncio.Event()
    loop = asyncio.get_event_loop()
    loop.add_reader(conn.fileno(), ev.set)

    while True:
        try:
            await asyncio.wait_for(ev.wait(), 60.0)
        except asyncio.TimeoutError:
            continue  # No FD activity detected in one minute

        # Activity detected. Is the connection still ok?
        try:
            await conn.execute("SELECT 1")
        except psycopg.OperationalError:
            # Guess what happened
            ...
