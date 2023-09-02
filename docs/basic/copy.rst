.. currentmodule:: psycopg

.. index::
    pair: COPY; SQL command

.. _copy:

..
    Using COPY TO and COPY FROM
    ===========================

COPY TO と COPY FROM を使用する
===============================

..
    Psycopg allows to operate with `PostgreSQL COPY protocol`__. :sql:`COPY` is
    one of the most efficient ways to load data into the database (and to modify
    it, with some SQL creativity).

psycopg を使うと、`PostgreSQL の COPY プロトコル`__ を使用した操作ができるようになります。:sql:`COPY` は、データベースにデータを読み込むための (そして SQL の創造性をいくらか発揮すれば、データを変更するための)、最も効率のよい方法の1つです。

.. __: https://www.postgresql.org/docs/current/sql-copy.html

..
    Copy is supported using the `Cursor.copy()` method, passing it a query of the
    form :sql:`COPY ... FROM STDIN` or :sql:`COPY ... TO STDOUT`, and managing the
    resulting `Copy` object in a `!with` block:

Copy は、`Cursor.copy()` メソッドに :sql:`COPY ... FROM STDIN` または :sql:`COPY ... TO STDOUT` という形式のクエリを渡して、`!with` ブロック内で `Copy` オブジェクトを使用することでサポートされます。

..
    .. code:: python

        with cursor.copy("COPY table_name (col1, col2) FROM STDIN") as copy:
            # pass data to the 'copy' object using write()/write_row()

.. code:: python

    with cursor.copy("COPY table_name (col1, col2) FROM STDIN") as copy:
        # 'copy' オブジェクトに write()/write_row() を使用してデータを渡す

..
    You can compose a COPY statement dynamically by using objects from the
    `psycopg.sql` module:

COPY ステートメントは、次のように `psycopg.sql` モジュールのオブジェクトを使用して動的に作れます。

..
    .. code:: python

        with cursor.copy(
            sql.SQL("COPY {} TO STDOUT").format(sql.Identifier("table_name"))
        ) as copy:
            # read data from the 'copy' object using read()/read_row()

.. code:: python

    with cursor.copy(
        sql.SQL("COPY {} TO STDOUT").format(sql.Identifier("table_name"))
    ) as copy:
        # 'copy' オブジェクトから read()/read_row() を使用してデータを読み込む

..
    .. versionchanged:: 3.1

        You can also pass parameters to `!copy()`, like in `~Cursor.execute()`:

        .. code:: python

            with cur.copy("COPY (SELECT * FROM table_name LIMIT %s) TO STDOUT", (3,)) as copy:
                # expect no more than three records

.. versionchanged:: 3.1

    `~Cursor.execute()` のように `!copy()` に引数を渡すこともできます。

    .. code:: python

        with cur.copy("COPY (SELECT * FROM table_name LIMIT %s) TO STDOUT", (3,)) as copy:
            # たかだか3レコードまでが期待される

..
    The connection is subject to the usual transaction behaviour, so, unless the
    connection is in autocommit, at the end of the COPY operation you will still
    have to commit the pending changes and you can still roll them back. See
    :ref:`transactions` for details.

コネクションは通常のトランザクション動作の影響を受けるため、コネクションが autocommit になっていない限り、COPY 操作の最後でも、保留中の変更をまだコミットする必要があり、その変更をロールバックすることもできます。詳細については、:ref:`transactions` を参照してください。

.. _copy-in-row:

..
    Writing data row-by-row
    -----------------------

行ごとにデータを書き込む
-----------------------

..
    Using a copy operation you can load data into the database from any Python
    iterable (a list of tuples, or any iterable of sequences): the Python values
    are adapted as they would be in normal querying. To perform such operation use
    a :sql:`COPY ... FROM STDIN` with `Cursor.copy()` and use `~Copy.write_row()`
    on the resulting object in a `!with` block. On exiting the block the
    operation will be concluded:

copy 操作を使用すると、Python のイテラブル (タプルのリスト、またはシーケンスの任意のイテラブル) からデータをデータベースに読み込めます。Python の値は通常のクエリの場合と同じように適応されます。このような操作を実行するには、`Cursor.copy()` で :sql:`COPY ... FROM STDIN` を使用し、`!with` ブロック内で結果として得たオブジェクトに `~Copy.write_row()` を使います。操作はブロックを出るときに完了します。

.. code:: python

    records = [(10, 20, "hello"), (40, None, "world")]

    with cursor.copy("COPY sample (col1, col2, col3) FROM STDIN") as copy:
        for record in records:
            copy.write_row(record)

..
    If an exception is raised inside the block, the operation is interrupted and
    the records inserted so far are discarded.

もしブロック内で例外が発生した場合は、操作は中断され、それまでに挿入されたレコードは破棄されます。

..
    In order to read or write from `!Copy` row-by-row you must not specify
    :sql:`COPY` options such as :sql:`FORMAT CSV`, :sql:`DELIMITER`, :sql:`NULL`:
    please leave these details alone, thank you :)

`!Copy` から行ごとに読み書きを行うためには、:sql:`FORMAT CSV`、:sql:`DELIMITER`、:sql:`NULL` などの :sql:`COPY` のオプションを指定してはいけません。これらの詳細については今は置いておきます。ありがとう :)

.. _copy-out-row:

..
    Reading data row-by-row
    -----------------------

行ごとにデータを読み込む
------------------------

..
    You can also do the opposite, reading rows out of a :sql:`COPY ... TO STDOUT`
    operation, by iterating on `~Copy.rows()`. However this is not something you
    may want to do normally: usually the normal query process will be easier to
    use.

逆の操作、つまり `~Copy.rows()` を繰り返すことで :sql:`COPY ... TO STDOUT` 操作から行を読み込むことも可能です。ただし、これは通常は実行したいことではありません。普通のクエリ処理のほうが使いやすいでしょう。

現在、PostgreSQL は :sql:`COPY TO` に完全な型情報を与えてくれないため、返された行には、フォーマットに従った未パースのデータが文字列かバイトとして得られるだけです。

..
    .. code:: python

        with cur.copy("COPY (VALUES (10::int, current_date)) TO STDOUT") as copy:
            for row in copy.rows():
                print(row)  # return unparsed data: ('10', '2046-12-24')

.. code:: python

    with cur.copy("COPY (VALUES (10::int, current_date)) TO STDOUT") as copy:
        for row in copy.rows():
            print(row)  # 未パースのデータが返る: ('10', '2046-12-24')

..
    You can improve the results by using `~Copy.set_types()` before reading, but
    you have to specify them yourself.

読み込み前に `~Copy.set_types()` を使うことで結果を改善できますが、自分自身で指定する必要があります。

.. code:: python

    with cur.copy("COPY (VALUES (10::int, current_date)) TO STDOUT") as copy:
        copy.set_types(["int4", "date"])
        for row in copy.rows():
            print(row)  # (10, datetime.date(2046, 12, 24))


..
    .. _copy-block:

    Copying block-by-block
    ----------------------

.. _copy-block:

ブロックごとにコピーする
------------------------

..
    If data is already formatted in a way suitable for copy (for instance because
    it is coming from a file resulting from a previous `COPY TO` operation) it can
    be loaded into the database using `Copy.write()` instead.

もしデータが copy に適した方法ですでにフォーマットされている場合には (たとえば、前回の `COPY TO` 操作の結果として得られたファイルに由来する場合など)、代わりに `Copy.write()` を使用してデータベースにロードできます。

.. code:: python

    with open("data", "r") as f:
        with cursor.copy("COPY data FROM STDIN") as copy:
            while data := f.read(BLOCK_SIZE):
                copy.write(data)

..
    In this case you can use any :sql:`COPY` option and format, as long as the
    input data is compatible with what the operation in `!copy()` expects. Data
    can be passed as `!str`, if the copy is in :sql:`FORMAT TEXT`, or as `!bytes`,
    which works with both :sql:`FORMAT TEXT` and :sql:`FORMAT BINARY`.

この場合には、入力データが `!copy()` 内の操作が期待するものと互換性がある限り、:sql:`COPY` の任意のオプションとフォーマットが使えます。データを `!str` として渡せるのは、copy が :sql:`FORMAT TEXT` の場合で、データを `!bytes` として渡せるのは、:sql:`FORMAT TEXT` と :sql:`FORMAT BINARY` の場合です。

..
    In order to produce data in :sql:`COPY` format you can use a :sql:`COPY ... TO
    STDOUT` statement and iterate over the resulting `Copy` object, which will
    produce a stream of `!bytes` objects:

:sql:`COPY` フォーマット内でデータを生成するためには、:sql:`COPY ... TO
STDOUT` ステートメントを使い、結果として得られた `!bytes` オブジェクトのストリームを生成する `Copy` オブジェクトをイテレートできます。

.. code:: python

    with open("data.out", "wb") as f:
        with cursor.copy("COPY table_name TO STDOUT") as copy:
            for data in copy:
                f.write(data)


..
    .. _copy-binary:

    Binary copy
    -----------

.. _copy-binary:

バイナリ コピー
---------------

..
    Binary copy is supported by specifying :sql:`FORMAT BINARY` in the :sql:`COPY`
    statement. In order to import binary data using `~Copy.write_row()`, all the
    types passed to the database must have a binary dumper registered; this is not
    necessary if the data is copied :ref:`block-by-block <copy-block>` using
    `~Copy.write()`.

バイナリ コピーは、:sql:`COPY` ステートメント内で :sql:`FORMAT BINARY` を指定することでサポートされます。`~Copy.write_row()` でバイナリデータをインポートするためには、データベースに渡されたすべての型に、バイバリ ダンバー (binary dumper) が登録されている必要があります。データが `~Copy.write()` を使用して :ref:`ブロックごとに<copy-block>` コピーされた場合、これは必要ありません。

..
    .. warning::

        PostgreSQL is particularly finicky when loading data in binary mode and
        will apply **no cast rules**. This means, for example, that passing the
        value 100 to an `integer` column **will fail**, because Psycopg will pass
        it as a `smallint` value, and the server will reject it because its size
        doesn't match what expected.

        You can work around the problem using the `~Copy.set_types()` method of
        the `!Copy` object and specifying carefully the types to load.

.. warning::

    PostgreSQLはバイナリ モードで データを読み込むときには特に注意が必要で、**cast のルールが適用されません**。つまり、たとえば100という値を `integer` カラムに渡そうとしても **失敗する** ということです。psycopg はこれを `smallint` の値として渡すため、サーバーは期待したサイズと一致しないという理由でリジェクトするためです。

    `!Copy` の `~Copy.set_types()` メソッドを使用して読み込む型を注意深く指定すれば、この問題は回避できます。

..
    .. seealso:: See :ref:`binary-data` for further info about binary querying.

.. seealso:: バイナリ クエリに関する詳しい情報については、:ref:`binary-data` を参照してください。

..
    .. _copy-async:

    Asynchronous copy support
    -------------------------

.. _copy-async:

非同期コピーのサポート
-------------------------

..
    Asynchronous operations are supported using the same patterns as above, using
    the objects obtained by an `AsyncConnection`. For instance, if `!f` is an
    object supporting an asynchronous `!read()` method returning :sql:`COPY` data,
    a fully-async copy operation could be:

非同期の操作は、`AsyncConnection` によって取得されたオブジェクトを使用して、上記と同じパターンを使用してサポートされます。たとえば、`!f` が :sql:`COPY` のデータを返す非同期の `!read()` メソッドをサポートするオブジェクトである場合、完全に非同期なコピー操作は次のようになるでしょう。

.. code:: python

    async with cursor.copy("COPY data FROM STDIN") as copy:
        while data := await f.read():
            await copy.write(data)

..
    The `AsyncCopy` object documentation describes the signature of the
    asynchronous methods and the differences from its sync `Copy` counterpart.

`AsyncCopy` オブジェクトのドキュメンテーションでは、非同期メソッドと、それに対応する同期の `Copy` との違いが説明されています。

..
    .. seealso:: See :ref:`async` for further info about using async objects.

.. seealso:: 非同期オブジェクトの使用に関する詳しい情報は、:ref:`async` を参照してください。


..
    Example: copying a table across servers
    ---------------------------------------

例: サーバーを横断するテーブルのコピー
---------------------------------------

..
    In order to copy a table, or a portion of a table, across servers, you can use
    two COPY operations on two different connections, reading from the first and
    writing to the second.

サーバーを横断してテーブルまたはテーブルの一部をコピーするためには、2つの異なるコネクションの上の COPY 操作を使用できます。1つ目のコネクションから読み込み、2つ目のコネクションに書き込みます。

.. code:: python

    with psycopg.connect(dsn_src) as conn1, psycopg.connect(dsn_tgt) as conn2:
        with conn1.cursor().copy("COPY src TO STDOUT (FORMAT BINARY)") as copy1:
            with conn2.cursor().copy("COPY tgt FROM STDIN (FORMAT BINARY)") as copy2:
                for data in copy1:
                    copy2.write(data)

..
    Using :sql:`FORMAT BINARY` usually gives a performance boost, but it only
    works if the source and target schema are *perfectly identical*. If the tables
    are only *compatible* (for example, if you are copying an :sql:`integer` field
    into a :sql:`bigint` destination field) you should omit the `BINARY` option and
    perform a text-based copy. See :ref:`copy-binary` for details.

通常、:sql:`FORMAT BINARY` を使用するとパフォーマンスが向上しますが、コピー元とコピー先のスキーマが *完全に同一である* 場合にのみ機能します。もしテーブルが *互換性がある* だけなら (たとえば、:sql:`integer` フィールドを 送り先の :sql:`bigint` フィールドにコピーしようとしている場合)、`BINARY` オプションを削除し、テキストベースのコピーを実行する必要があります。詳細は :ref:`copy-binary` を参照してください。

..
    The same pattern can be adapted to use :ref:`async objects <async>` in order
    to perform an :ref:`async copy <copy-async>`.

同様のパターンは、:ref:`async copy <copy-async>` を実行するために、:ref:`async objects <async>` を使うように書き換えられます。
