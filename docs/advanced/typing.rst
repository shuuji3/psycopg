.. currentmodule:: psycopg

..
    .. _static-typing:

    Static Typing
    =============

.. _static-typing:

静的型付け
==========

..
    Psycopg source code is annotated according to :pep:`0484` type hints and is
    checked using the current version of Mypy_ in ``--strict`` mode.

psycopg のソースコードは、:pep:`0484` の型ヒントに従ってアノテーションされていて、Mypy_ の現在のバージョンで ``--strict`` モードを使用して型チェックされています。

..
    If your application is checked using Mypy too you can make use of Psycopg
    types to validate the correct use of Psycopg objects and of the data returned
    by the database.

アプリケーションが Mypy を使用して型チェックされている場合、psycopg の型を活用して psycopg オブジェクトとデータベースから返されたデータが正しく使用されているかを検証できます。

.. _Mypy: http://mypy-lang.org/

..
    Generic types
    -------------

ジェネリック型
--------------

..
    Psycopg `Connection` and `Cursor` objects are `~typing.Generic` objects and
    support a `!Row` parameter which is the type of the records returned.

psycopg の `Connection` と `Cursor` オブジェクトは `~typing.Generic` オブジェクトであり、返されたレコードの型である `!Row` パラメータをサポートしています。

..
    By default methods such as `Cursor.fetchall()` return normal tuples of unknown
    size and content. As such, the `connect()` function returns an object of type
    `!psycopg.Connection[Tuple[Any, ...]]` and `Connection.cursor()` returns an
    object of type `!psycopg.Cursor[Tuple[Any, ...]]`. If you are writing generic
    plumbing code it might be practical to use annotations such as
    `!Connection[Any]` and `!Cursor[Any]`.

デフォルトでは、`Cursor.fetchall()` などのメソッドは、サイズとコンテンツが未知の通常のタプルを返します。したがって、`connect()` 関数は型 `!psycopg.Connection[Tuple[Any, ...]]` のオブジェクトを返し、`Connection.cursor()` は型 `!psycopg.Cursor[Tuple[Any, ...]]` のオブジェクトを返します。ジェネリックな配管コード (訳注: データベースに接続するコード) を書いている場合は、`!Connection[Any]` や `!Cursor[Any]` などのアノテーションを使うのが実用的かもしれません。

..
    .. code:: python

       conn = psycopg.connect() # type is psycopg.Connection[Tuple[Any, ...]]

       cur = conn.cursor()      # type is psycopg.Cursor[Tuple[Any, ...]]

       rec = cur.fetchone()     # type is Optional[Tuple[Any, ...]]

       recs = cur.fetchall()    # type is List[Tuple[Any, ...]]

.. code:: python

   conn = psycopg.connect() # 型は psycopg.Connection[Tuple[Any, ...]] です

   cur = conn.cursor()      # 型は psycopg.Cursor[Tuple[Any, ...]] です

   rec = cur.fetchone()     # 型は Optional[Tuple[Any, ...]] です

   recs = cur.fetchall()    # 型は List[Tuple[Any, ...]] です

..
    .. _row-factory-static:

    Type of rows returned
    ---------------------

.. _row-factory-static:

返された行の型
--------------

..
    If you want to use connections and cursors returning your data as different
    types, for instance as dictionaries, you can use the `!row_factory` argument
    of the `~Connection.connect()` and the `~Connection.cursor()` method, which
    will control what type of record is returned by the fetch methods of the
    cursors and annotate the returned objects accordingly. See
    :ref:`row-factories` for more details.

データを異なる型、たとえばディクショナリとして返すコネクションとカーソルを使用したい場合、`~Connection.connect()` と `~Connection.cursor()` メソッドの `!row_factory` 引数が使えます。この引数は、カーソルの fetch メソッドから返されるレコードの型をコントロールして、返されたオブジェクトを適切にアノテートします。詳細については :ref:`row-factories` を参照してください。

..
    .. code:: python

       dconn = psycopg.connect(row_factory=dict_row)
       # dconn type is psycopg.Connection[Dict[str, Any]]

       dcur = conn.cursor(row_factory=dict_row)
       dcur = dconn.cursor()
       # dcur type is psycopg.Cursor[Dict[str, Any]] in both cases

       drec = dcur.fetchone()
       # drec type is Optional[Dict[str, Any]]

.. code:: python

   dconn = psycopg.connect(row_factory=dict_row)
   # dconn の型は psycopg.Connection[Dict[str, Any]] です

   dcur = conn.cursor(row_factory=dict_row)
   dcur = dconn.cursor()
   # dcur の型はいずれの場合も psycopg.Cursor[Dict[str, Any]] です

   drec = dcur.fetchone()
   # drec の型は Optional[Dict[str, Any]] です

..
    .. _example-pydantic:

    Example: returning records as Pydantic models
    ---------------------------------------------

.. _example-pydantic:

例: レコードを Pydantic モデルとして返す
---------------------------------------------

..
    Using Pydantic_ it is possible to enforce static typing at runtime. Using a
    Pydantic model factory the code can be checked statically using Mypy and
    querying the database will raise an exception if the rows returned is not
    compatible with the model.

Pydantic_ を使用すると、ランタイム時の静的型付けの矯正が可能になります。Pydantic モデル ファクトリ を使用すると、Mypy を使用してコードの静的な型チェックができ、返された行がモデルと互換性がない場合にデータベースのクエリが例外を起こすようになります。

.. _Pydantic: https://pydantic-docs.helpmanual.io/

..
    The following example can be checked with ``mypy --strict`` without reporting
    any issue. Pydantic will also raise a runtime error in case the
    `!Person` is used with a query that returns incompatible data.

次の例では、``mypy --strict`` を使用して問題のレポートなしで型チェックができています。Pydantic は、互換性のないデータを返すクエリで `!Person` が使用された場合に、ランタイム時のエラーも起こします。

..
    .. code:: python

        from datetime import date
        from typing import Optional

        import psycopg
        from psycopg.rows import class_row
        from pydantic import BaseModel

        class Person(BaseModel):
            id: int
            first_name: str
            last_name: str
            dob: Optional[date]

        def fetch_person(id: int) -> Person:
            with psycopg.connect() as conn:
                with conn.cursor(row_factory=class_row(Person)) as cur:
                    cur.execute(
                        """
                        SELECT id, first_name, last_name, dob
                        FROM (VALUES
                            (1, 'John', 'Doe', '2000-01-01'::date),
                            (2, 'Jane', 'White', NULL)
                        ) AS data (id, first_name, last_name, dob)
                        WHERE id = %(id)s;
                        """,
                        {"id": id},
                    )
                    obj = cur.fetchone()

                    # reveal_type(obj) would return 'Optional[Person]' here

                    if not obj:
                        raise KeyError(f"person {id} not found")

                    # reveal_type(obj) would return 'Person' here

                    return obj

        for id in [1, 2]:
            p = fetch_person(id)
            if p.dob:
                print(f"{p.first_name} was born in {p.dob.year}")
            else:
                print(f"Who knows when {p.first_name} was born")

.. code:: python

    from datetime import date
    from typing import Optional

    import psycopg
    from psycopg.rows import class_row
    from pydantic import BaseModel

    class Person(BaseModel):
        id: int
        first_name: str
        last_name: str
        dob: Optional[date]

    def fetch_person(id: int) -> Person:
        with psycopg.connect() as conn:
            with conn.cursor(row_factory=class_row(Person)) as cur:
                cur.execute(
                    """
                    SELECT id, first_name, last_name, dob
                    FROM (VALUES
                        (1, 'John', 'Doe', '2000-01-01'::date),
                        (2, 'Jane', 'White', NULL)
                    ) AS data (id, first_name, last_name, dob)
                    WHERE id = %(id)s;
                    """,
                    {"id": id},
                )
                obj = cur.fetchone()

                # ここで reveal_type(obj) は 'Optional[Person]' を返すはずです

                if not obj:
                    raise KeyError(f"person {id} not found")

                # ここで reveal_type(obj) は 'Person' を返すはずです

                return obj

    for id in [1, 2]:
        p = fetch_person(id)
        if p.dob:
                print(f"{p.first_name} さんは {p.dob.year} に生まれました")
            else:
                print(f"誰も {p.first_name} さんがいつ生まれたのかを知りません")

..
    .. _literal-string:

    Checking literal strings in queries
    -----------------------------------

.. _literal-string:

クエリ内のリテラル文字列の型チェック
------------------------------------

..
    The `~Cursor.execute()` method and similar should only receive a literal
    string as input, according to :pep:`675`. This means that the query should
    come from a literal string in your code, not from an arbitrary string
    expression.

`~Cursor.execute()` や類似のメソッドのようなメソッドは、:pep:`675` によれば、リテラル文字列のみを入力として受け取る必要があります。つまり、クエリは任意の文字列式ではなく、コード中のリテラル文字列から来る必要があるということです。

..
    For instance, passing an argument to the query should be done via the second
    argument to `!execute()`, not by string composition:

たとえば、クエリへの引数の引き渡しは `!execute()` の2つ目の引数を経由で行なわれる必要があり、文字列の構築によって行われてはいけません。

..
    .. code:: python

        def get_record(conn: psycopg.Connection[Any], id: int) -> Any:
            cur = conn.execute("SELECT * FROM my_table WHERE id = %s" % id)  # BAD!
            return cur.fetchone()

        # the function should be implemented as:

        def get_record(conn: psycopg.Connection[Any], id: int) -> Any:
            cur = conn.execute("select * FROM my_table WHERE id = %s", (id,))
            return cur.fetchone()

.. code:: python

    def get_record(conn: psycopg.Connection[Any], id: int) -> Any:
        cur = conn.execute("SELECT * FROM my_table WHERE id = %s" % id)  # BAD!
        return cur.fetchone()

    # この関数は、以下のように実装する必要があります

    def get_record(conn: psycopg.Connection[Any], id: int) -> Any:
        cur = conn.execute("select * FROM my_table WHERE id = %s", (id,))
        return cur.fetchone()

..
    If you are composing a query dynamically you should use the `sql.SQL` object
    and similar to escape safely table and field names. The parameter of the
    `!SQL()` object should be a literal string:

クエリを動的に構築する場合、`sql.SQL` と同様のオブジェクトを使用して、テーブルとフィールドの名前を安全にエスケープする必要があります。`!SQL()` オブジェクトのパラメータはリテラル文字列である必要があります。

..
    .. code:: python

        def count_records(conn: psycopg.Connection[Any], table: str) -> int:
            query = "SELECT count(*) FROM %s" % table  # BAD!
            return conn.execute(query).fetchone()[0]

        # the function should be implemented as:

        def count_records(conn: psycopg.Connection[Any], table: str) -> int:
            query = sql.SQL("SELECT count(*) FROM {}").format(sql.Identifier(table))
            return conn.execute(query).fetchone()[0]

.. code:: python

    def count_records(conn: psycopg.Connection[Any], table: str) -> int:
        query = "SELECT count(*) FROM %s" % table  # BAD!
        return conn.execute(query).fetchone()[0]

    # この関数は、以下のように実装する必要があります

    def count_records(conn: psycopg.Connection[Any], table: str) -> int:
        query = sql.SQL("SELECT count(*) FROM {}").format(sql.Identifier(table))
        return conn.execute(query).fetchone()[0]

..
    At the time of writing, no Python static analyzer implements this check (`mypy
    doesn't implement it`__, Pyre_ does, but `doesn't work with psycopg yet`__).
    Once the type checkers support will be complete, the above bad statements
    should be reported as errors.

これを書いている時点では、この型チェックを実装している Python の静的型チェッカーは存在しません (`mypy はこれを実装していません`__。Pyre_ は実装していますが、`psycopg ではまだ機能しません`__)。型チェッカーのサポートが完了したら、上記の悪いステートメントはエラーとして報告されるようになるはずです。

.. __: https://github.com/python/mypy/issues/12554
.. __: https://github.com/facebook/pyre-check/issues/636

.. _Pyre: https://pyre-check.org/
