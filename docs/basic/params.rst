.. currentmodule:: psycopg

.. index::
    pair: Query; Parameters

..
    .. _query-parameters:

    Passing parameters to SQL queries
    =================================

.. _query-parameters:

SQL クエリにパラメータを渡す
============================

..
    Most of the times, writing a program you will have to mix bits of SQL
    statements with values provided by the rest of the program:

ほとんどの場合、プログラムを書くときには、次のように他の場所から提供された値を SQL ステートメントと少し混ぜる必要があるでしょう。

.. code::

    SELECT some, fields FROM some_table WHERE id = ...

..
    :sql:`id` equals what? Probably you will have a Python value you are looking
    for.

:sql:`id` は何と等しいのでしょうか？ おそらく見つけようとしている Python の値があるはずです。

..
    `!execute()` arguments
    ----------------------

`!execute()` の引数
----------------------

..
    Passing parameters to a SQL statement happens in functions such as
    `Cursor.execute()` by using ``%s`` placeholders in the SQL statement, and
    passing a sequence of values as the second argument of the function. For
    example the Python function call:

SQL ステートメントへのパラメータの受け渡しは、`Cursor.execute()` などの関数内で SQL ステートメント内の ``%s`` プレースホルダーを使用して、値のシーケンスを関数の第2引数として渡すことで行われます。たとえば、Python の関数呼び出しは次のようになります。

.. code:: python

    cur.execute("""
        INSERT INTO some_table (id, created_at, last_name)
        VALUES (%s, %s, %s);
        """,
        (10, datetime.date(2020, 11, 18), "O'Reilly"))

..
    is *roughly* equivalent to the SQL command:

これは、*おおよそ* 次の SQL コマンドと同等です。

.. code-block:: sql

    INSERT INTO some_table (id, created_at, last_name)
    VALUES (10, '2020-11-18', 'O''Reilly');

..
    Note that the parameters will not be really merged to the query: query and the
    parameters are sent to the server separately: see :ref:`server-side-binding`
    for details.

パラメータは本当にはクエリにマージされないことに注意してください。クエリとパラメータはサーバーに別々に送られるためです。詳細については、:ref:`server-side-binding` を参照してください。

..
    Named arguments are supported too using :samp:`%({name})s` placeholders in the
    query and specifying the values into a mapping.  Using named arguments allows
    to specify the values in any order and to repeat the same value in several
    places in the query::

名前付き引数もサポートされており、クエリ内で :samp:`%({name})s` プレースホルダーを使用して、値をマッピングとして指定します。名前付き引数を使用すると、次のように値を自由な順序で指定したり、同じ値をクエリ内の複数の場所で繰り返したりできます。

.. code:: python

    cur.execute("""
        INSERT INTO some_table (id, created_at, updated_at, last_name)
        VALUES (%(id)s, %(created)s, %(created)s, %(name)s);
        """,
        {'id': 10, 'name': "O'Reilly", 'created': datetime.date(2020, 11, 18)})

..
    Using characters ``%``, ``(``, ``)`` in the argument names is not supported.

引数名内での文字 ``%``、``(``、``)`` の使用はサポートされていません。

..
    When parameters are used, in order to include a literal ``%`` in the query you
    can use the ``%%`` string::

パラメータが使用されたとき、クエリ内にリテラル ``%`` を含めるためには、``%%`` 文字列が使えます。

..
    .. code:: python

        cur.execute("SELECT (%s % 2) = 0 AS even", (10,))       # WRONG
        cur.execute("SELECT (%s %% 2) = 0 AS even", (10,))      # correct

.. code:: python

    cur.execute("SELECT (%s % 2) = 0 AS even", (10,))       # 間違い！
    cur.execute("SELECT (%s %% 2) = 0 AS even", (10,))      # 正しい

..
    While the mechanism resembles regular Python strings manipulation, there are a
    few subtle differences you should care about when passing parameters to a
    query.

仕組みは通常の Python 文字列の操作に似ていますが、クエリにパラメータを渡すときに注意が必要な微妙な違いがいくつかあります。

..
    - The Python string operator ``%`` *must not be used*: the `~cursor.execute()`
      method accepts a tuple or dictionary of values as second parameter.
      |sql-warn|__:

- Python 文字列演算子 ``%`` は *絶対に使ってはなりません*。`~cursor.execute()` メソッドは、タプルまたはディクショナリの値を第2引数として受け付けます。|sql-warn|__

  .. |sql-warn| replace:: 値をクエリにマージするために ``%`` または ``+`` は **決して使ってはいけません**

  ..
      .. code:: python

        cur.execute("INSERT INTO numbers VALUES (%s, %s)" % (10, 20)) # WRONG
        cur.execute("INSERT INTO numbers VALUES (%s, %s)", (10, 20))  # correct

  .. code:: python

    cur.execute("INSERT INTO numbers VALUES (%s, %s)" % (10, 20)) # 間違い！
    cur.execute("INSERT INTO numbers VALUES (%s, %s)", (10, 20))  # 正しい

  .. __: sql-injection_

..
    - For positional variables binding, *the second argument must always be a
      sequence*, even if it contains a single variable (remember that Python
      requires a comma to create a single element tuple)::

- 位置での変数バインディングでは、たとえ1つの変数しか含まれていなかったとしても、*第2引数は常にシーケンスでなければなりません* (Python では1要素のタプルを作るためにカンマが必要であることを思い出してください)。

  ..
      .. code:: python

        cur.execute("INSERT INTO foo VALUES (%s)", "bar")    # WRONG
        cur.execute("INSERT INTO foo VALUES (%s)", ("bar"))  # WRONG
        cur.execute("INSERT INTO foo VALUES (%s)", ("bar",)) # correct
        cur.execute("INSERT INTO foo VALUES (%s)", ["bar"])  # correct

  .. code:: python

    cur.execute("INSERT INTO foo VALUES (%s)", "bar")    # 間違い！
    cur.execute("INSERT INTO foo VALUES (%s)", ("bar"))  # 間違い！
    cur.execute("INSERT INTO foo VALUES (%s)", ("bar",)) # 正しい
    cur.execute("INSERT INTO foo VALUES (%s)", ["bar"])  # 正しい

..
    - The placeholder *must not be quoted*::

- プレースホルダーは、次のように *クォートで囲んではいけません*。

  ..
    cur.execute("INSERT INTO numbers VALUES ('%s')", ("Hello",)) # WRONG
    cur.execute("INSERT INTO numbers VALUES (%s)", ("Hello",))   # correct

  .. code:: python

    cur.execute("INSERT INTO numbers VALUES ('%s')", ("Hello",)) # 間違い！
    cur.execute("INSERT INTO numbers VALUES (%s)", ("Hello",))   # 正しい

..
    - The variables placeholder *must always be a* ``%s``, even if a different
      placeholder (such as a ``%d`` for integers or ``%f`` for floats) may look
      more appropriate for the type. You may find other placeholders used in
      Psycopg queries (``%b`` and ``%t``) but they are not related to the
      type of the argument: see :ref:`binary-data` if you want to read more::

- 変数のプレースホルダーは、たとえその型に対して他のプレースホルダー (整数に対して ``%d`` や浮動小数点数に対して ``%f`` など) がより適切だと思えたとしても、*常に* ``%s`` *でなければなりません*。psycopg のクエリで他のプレースホルダー (``%b`` と ``%t``) が使われているのを見かけるかもしれませんが、それらは引数の型とは無関係です。詳細について知りたい場合は、:ref:`binary-data` を参照してください。

  ..
    cur.execute("INSERT INTO numbers VALUES (%d)", (10,))   # WRONG
    cur.execute("INSERT INTO numbers VALUES (%s)", (10,))   # correct

  .. code:: python

    cur.execute("INSERT INTO numbers VALUES (%d)", (10,))   # 間違い！
    cur.execute("INSERT INTO numbers VALUES (%s)", (10,))   # 正しい

..
    - Only query values should be bound via this method: it shouldn't be used to
      merge table or field names to the query. If you need to generate SQL queries
      dynamically (for instance choosing a table name at runtime) you can use the
      functionalities provided in the `psycopg.sql` module::

- このメソッドを介してバインドされるのは、クエリの値だけであるべきです。テーブルやフィールドの名前をクエリにマージするのに使われるべきではありません。SQL クエリを動的に生成する必要がある場合 (たとえば、テーブル名をランタイムに選択するなど)、次のように `psycopg.sql` モジュールが提供する機能が使えます。

  ..
    cur.execute("INSERT INTO %s VALUES (%s)", ('numbers', 10))  # WRONG
    cur.execute(                                                # correct
        SQL("INSERT INTO {} VALUES (%s)").format(Identifier('numbers')),
        (10,))

  .. code:: python

    cur.execute("INSERT INTO %s VALUES (%s)", ('numbers', 10))  # 間違い！
    cur.execute(                                                # 正しい
        SQL("INSERT INTO {} VALUES (%s)").format(Identifier('numbers')),
        (10,))

.. index:: Security, SQL injection

..
    .. _sql-injection:

    Danger: SQL injection
    ---------------------

.. _sql-injection:

危険: SQL インジェクション
--------------------------

..
    The SQL representation of many data types is often different from their Python
    string representation. The typical example is with single quotes in strings:
    in SQL single quotes are used as string literal delimiters, so the ones
    appearing inside the string itself must be escaped, whereas in Python single
    quotes can be left unescaped if the string is delimited by double quotes.

多くのデータ型の SQL 表現は、多くの場合に Python の文字列表現とは異なります。典型的な例は、文字列がシングルクォートで囲まれることです。SQL では、シングルクォートは文字列リテラルの区切り文字として使われるため、文字列自体の内部に現れるシングルクォートはエスケープする必要があります。一方で、文字列がダブルクォート区切りの場合、Python のシングルクォートは、エスケープせずに残しておけます。

..
    Because of the difference, sometimes subtle, between the data types
    representations, a naïve approach to query strings composition, such as using
    Python strings concatenation, is a recipe for *terrible* problems::

データ型の表現の (ときには微妙な) 違いが原因で、たとえば Python 文字列の結合を使用するなど、クエリ文字列を構成するときにナイーブなアプローチを取ってしまうことが原因で、*恐ろしい* 問題のレシピとなってしまうことがあります。

..
    SQL = "INSERT INTO authors (name) VALUES ('%s')" # NEVER DO THIS
    data = ("O'Reilly", )
    cur.execute(SQL % data) # THIS WILL FAIL MISERABLY
    # SyntaxError: syntax error at or near "Reilly"

.. code:: python

    SQL = "INSERT INTO authors (name) VALUES ('%s')" # これは絶対にしてはいけない！
    data = ("O'Reilly", )
    cur.execute(SQL % data) # これは大失敗に終わる！
    # SyntaxError: syntax error at or near "Reilly"

..
    If the variables containing the data to send to the database come from an
    untrusted source (such as data coming from a form on a web site) an attacker
    could easily craft a malformed string, either gaining access to unauthorized
    data or performing destructive operations on the database. This form of attack
    is called `SQL injection`_ and is known to be one of the most widespread forms
    of attack on database systems. Before continuing, please print `this page`__
    as a memo and hang it onto your desk.

データベースに送信するデータを含む変数が信頼できない情報源 (ウェブサイト上のフォームから送られたデータなど) に由来する場合、攻撃者は不正な形式の文字列を簡単に作成できるため、許可されていないデータへのアクセスを獲得したり、データベース上で破壊的な操作を実行できてしまいます。この形式の攻撃は `SQL injection`_ と呼ばれ、データベース システムに対して、最も広く発生している形式の攻撃の1つとして知られています。読み進める前に、忘れないように `このページ`__ を印刷して机の上に貼ってください。

.. _SQL injection: https://en.wikipedia.org/wiki/SQL_injection
.. __: https://xkcd.com/327/

..
    Psycopg can :ref:`automatically convert Python objects to SQL
    values<types-adaptation>`: using this feature your code will be more robust
    and reliable. We must stress this point:

psycopg は :ref:`Python オブジェクトを自動的に SQL の値に変換します <types-adaptation>`。この機能を使用することで、コードはより頑強で信頼できるものになります。以下の点は強調しておかなければなりません。

..
    .. warning::

        - Don't manually merge values to a query: hackers from a foreign country
          will break into your computer and steal not only your disks, but also
          your cds, leaving you only with the three most embarrassing records you
          ever bought. On cassette tapes.

        - If you use the ``%`` operator to merge values to a query, con artists
          will seduce your cat, who will run away taking your credit card
          and your sunglasses with them.

        - If you use ``+`` to merge a textual value to a string, bad guys in
          balaclava will find their way to your fridge, drink all your beer, and
          leave your toilet seat up and your toilet paper in the wrong orientation.

        - You don't want to manually merge values to a query: :ref:`use the
          provided methods <query-parameters>` instead.

.. warning::

    - クエリに値を手動でマージしないでください。そんなことをしたら、外国からのハッカーがあなたのコンピュータに侵入し、ディスクだけでなく CD も盗み、あなたがこれまでに買った中で最も恥ずかしいレコード 3 枚だけを残すでしょう。カセットテープで。

    - もし ``%`` 演算子を使用して値をクエリにマージしたら、詐欺師はあなたの猫を誘惑し、猫はあなたのクレジットカードとサングラスを取って詐欺師と一緒に逃げ去るでしょう。

    - もし ``+`` を使ってテキストの値を文字列にマージしたら、バラクラバをかぶった悪い人たちが冷蔵庫にたどり着き、すべてのビールを飲み干し、トイレの便座を上げたままにし、トイレットペーパーの向きを間違ったままにしてしまうでしょう。

    - もう値をクエリに手動でマージしたいとは思わないはずです。その代わりに :ref:`提供されたメソッド <query-parameters>` を使ってください。

..
    The correct way to pass variables in a SQL command is using the second
    argument of the `Cursor.execute()` method::

SQL コマンド内で変数を渡すための正しい方法は、次のように `Cursor.execute()` メソッドの第2引数を使うことです。

..
    SQL = "INSERT INTO authors (name) VALUES (%s)"  # Note: no quotes
    data = ("O'Reilly", )
    cur.execute(SQL, data)  # Note: no % operator

.. code:: python

    SQL = "INSERT INTO authors (name) VALUES (%s)"  # Note: no quotes
    data = ("O'Reilly", )
    cur.execute(SQL, data)  # メモ: % 演算子はなし

..
    .. note::

        Python static code checkers are not quite there yet, but, in the future,
        it will be possible to check your code for improper use of string
        expressions in queries. See :ref:`literal-string` for details.

.. note::

    Python の静的コードチェッカーはまだそこまでは進んでいません。しかし、将来はクエリ内の文字列式の不適切な使用をチェック可能になるでしょう。詳細は :ref:`literal-string` を参照してください。

..
    .. seealso::

        Now that you know how to pass parameters to queries, you can take a look
        at :ref:`how Psycopg converts data types <types-adaptation>`.

.. seealso::

    これでパラメータをクエリに渡す方法が理解できたはずなので、:ref:`psycopg がデータ型を変換する方法 <types-adaptation>` を読むことができます。

.. index::
    pair: Binary; Parameters

..
    .. _binary-data:

    Binary parameters and results
    -----------------------------

.. _binary-data:

バイナリ パラメータと結果
-----------------------------

..
    PostgreSQL has two different ways to transmit data between client and server:
    `~psycopg.pq.Format.TEXT`, always available, and `~psycopg.pq.Format.BINARY`,
    available most of the times but not always. Usually the binary format is more
    efficient to use.

PostgreSQL には、データをクライアントとサーバー間で転送する2種類の異なる方法があります。`~psycopg.pq.Format.TEXT` は常に利用可能な方法で、`~psycopg.pq.Format.BINARY` はほとんどの場合に利用可能ですが常にではありません。通常は、バイナリ フォーマットを使うのがより効率的です。

..
    Psycopg can support both formats for each data type. Whenever a value
    is passed to a query using the normal ``%s`` placeholder, the best format
    available is chosen (often, but not always, the binary format is picked as the
    best choice).

psycopg はデータ型ごとに両方のフォーマットをサポートできます。普通の ``%s`` プレースホルダーを使用してクエリに値が渡されるたびに、利用可能な最適なフォーマットが選ばれます (常にではありませんが、多くの場合にバイナリ フォーマットが最善の選択として選ばれます)。

..
    If you have a reason to select explicitly the binary format or the text format
    for a value you can use respectively a ``%b`` placeholder or a ``%t``
    placeholder instead of the normal ``%s``. `~Cursor.execute()` will fail if a
    `~psycopg.adapt.Dumper` for the right data type and format is not available.

値に対して明示的にバイナリ フォーマットまたはテキスト フォーマットを選択する理由がある場合は、それぞれ ``%b`` プレースホルダーまたは ``%t`` プレースホルダーを通常の ``%s`` の代わりに使用できます。正しいデータ型に対する `~psycopg.adapt.Dumper` とフォーマットが利用できない場合、`~Cursor.execute()` は失敗します。

..
    The same two formats, text or binary, are used by PostgreSQL to return data
    from a query to the client. Unlike with parameters, where you can choose the
    format value-by-value, all the columns returned by a query will have the same
    format. Every type returned by the query should have a `~psycopg.adapt.Loader`
    configured, otherwise the data will be returned as unparsed `!str` (for text
    results) or buffer (for binary results).

同じ2つのフォーマット (テキストまたはバイナリ) は、PostgreSQL がクエリからデータをクライアントに返すためにも使用されます。値ごとにフォーマットを選択できるパラメータの場合とは違い、クエリから返されるすべての列は同じフォーマットを持ちます。クエリから返されたすべての型は設定された `~psycopg.adapt.Loader` を持つ必要があり、もし存在しない場合にはデータは未パースの `!str` (テキストの結果の場合) または buffer (バイナリの結果の場合) として返されます。

..
    .. note::
        The `pg_type`_ table defines which format is supported for each PostgreSQL
        data type. Text input/output is managed by the functions declared in the
        ``typinput`` and ``typoutput`` fields (always present), binary
        input/output is managed by the ``typsend`` and ``typreceive`` (which are
        optional).

        .. _pg_type: https://www.postgresql.org/docs/current/catalog-pg-type.html

.. note::
    `pg_type`_ テーブルには、PostgreSQL のそれぞれのデータ型に対してどのフォーマットがサポートされているかが定義されています。テキストの入出力は ``typinput`` and ``typoutput`` (常に存在) フィールドで宣言された関数により管理されており、バイナリの入出力は ``typsend`` と ``typreceive`` (オプション) によって宣言されています。

    .. _pg_type: https://www.postgresql.org/docs/current/catalog-pg-type.html

..
    Because not every PostgreSQL type supports binary output, by default, the data
    will be returned in text format. In order to return data in binary format you
    can create the cursor using `Connection.cursor`\ `!(binary=True)` or execute
    the query using `Cursor.execute`\ `!(binary=True)`. A case in which
    requesting binary results is a clear winner is when you have large binary data
    in the database, such as images::

デフォルトでは、すべての PostgreSQL の型がバイナリのアウトプットをサポートしているわけではないので、データはテキスト フォーマットで返されます。データをバイナリ フォーマットで返すためには、`Connection.cursor`\ `!(binary=True)` を使用してカーソルを作成するか、クエリを `Cursor.execute`\ `!(binary=True)` を使用して実行します。バイナリの結果をリクエストするのが明らかに優れているのは、次のように、画像などの大きなバイナリデータがデータベースにある場合です。

.. code:: python

    cur.execute(
        "SELECT image_data FROM images WHERE id = %s", [image_id], binary=True)
    data = cur.fetchone()[0]
