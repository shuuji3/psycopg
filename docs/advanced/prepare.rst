.. currentmodule:: psycopg

.. index::
    single: Prepared statements

..
    .. _prepared-statements:

    Prepared statements
    ===================

.. _prepared-statements:

prepare されたステートメント
============================

..
    Psycopg uses an automatic system to manage *prepared statements*. When a
    query is prepared, its parsing and planning is stored in the server session,
    so that further executions of the same query on the same connection (even with
    different parameters) are optimised.

psycopg は自動的なシステムを使用して *prepare されたステートメント* を管理します。クエリが prepare されると、クエリのパースと計画はサーバーのセッションに保存されます。これにより、以降の同じコネクション上の同じクエリ実行が (異なるパラメータでも) 最適化されます。

..
    A query is prepared automatically after it is executed more than
    `~Connection.prepare_threshold` times on a connection. `!psycopg` will make
    sure that no more than `~Connection.prepared_max` statements are planned: if
    further queries are executed, the least recently used ones are deallocated and
    the associated resources freed.

コネクション上で `~Connection.prepare_threshold` より長い時間実行された場合、クエリは自動的に prepare されます。`!psycopg` は `~Connection.prepared_max` より多くののステートメントが計画されないことを保証します。追加のクエリが実行された場合、最も最近使われなかった (LRU) ものが割り当てから外され、関連するリソースが開放されます。

..
    Statement preparation can be controlled in several ways:

ステートメントの prepare は、以下のような複数の方法でコントロールされます。

..
    - You can decide to prepare a query immediately by passing `!prepare=True` to
      `Connection.execute()` or `Cursor.execute()`. The query is prepared, if it
      wasn't already, and executed as prepared from its first use.

- クエリを prepare することは、`!prepare=True` を `Connection.execute()` または `Cursor.execute()` に渡すことで直ちに決定できます。すでに prepare されていなければ、そのクエリは prepare され、1回目の使用から prepare されたものとして実行されます。

..
    - Conversely, passing `!prepare=False` to `!execute()` will avoid to prepare
      the query, regardless of the number of times it is executed. The default for
      the parameter is `!None`, meaning that the query is prepared if the
      conditions described above are met.

- 逆に、`!prepare=False` を `!execute()` に渡すと、実行時間の長さに関わらず、クエリが prepare されるのを回避できます。パラメータのデフォルトは `!None` です。その場合、上記の条件が満たされると prepare されます。

..
    - You can disable the use of prepared statements on a connection by setting
      its `~Connection.prepare_threshold` attribute to `!None`.

- コネクションの `~Connection.prepare_threshold` 属性を `!None` に設定すると、そのコネクション上の prepare されたステートメントの使用を無効化できます。

..
    .. versionchanged:: 3.1
        You can set `!prepare_threshold` as a `~Connection.connect()` keyword
        parameter too.

.. versionchanged:: 3.1
    `!prepare_threshold` は `~Connection.connect()` のキーワード引数としても設定できます。

..
    .. seealso::

        The `PREPARE`__ PostgreSQL documentation contains plenty of details about
        prepared statements in PostgreSQL.

        Note however that Psycopg doesn't use SQL statements such as
        :sql:`PREPARE` and :sql:`EXECUTE`, but protocol level commands such as the
        ones exposed by :pq:`PQsendPrepare`, :pq:`PQsendQueryPrepared`.

        .. __: https://www.postgresql.org/docs/current/sql-prepare.html

.. seealso::

    PostgreSQL ドキュメンテーションの `PREPARE`__ には、PostgreSQL 内での prepare されたステートメントに関するさまざまな詳細が説明されています。

    ただし、psycopg は :sql:`PREPARE` と :sql:`EXECUTE` などの SQL ステートメントではなく、:pq:`PQsendPrepare` によって公開された :pq:`PQsendQueryPrepared` などのプロトコルレベルのコマンドを使用することに注意してください。

    .. __: https://www.postgresql.org/docs/current/sql-prepare.html

..
    .. warning::

        Using external connection poolers, such as PgBouncer, is not compatible
        with prepared statements, because the same client connection may change
        the server session it refers to. If such middleware is used you should
        disable prepared statements, by setting the `Connection.prepare_threshold`
        attribute to `!None`.

.. warning::

    PgBouncer などの外部のコネクション プールの使用は、prepare されたステートメントとは互換性がありません。同一のクライアント コネクションが、参照しているサーバー セッションを変更する可能性があるためです。そのようなミドルウェアが使用されている場合、prepare されたステートメントは `Connection.prepare_threshold` 属性を `!None` に設定することで無効化する必要があります。
