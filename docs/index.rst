.. Psycopg 3 -- PostgreSQL database adapter for Python

==============================================================
Psycopg 3 -- Python のための PostgreSQL データベースアダプター
==============================================================

..
    Psycopg 3 is a newly designed PostgreSQL_ database adapter for the Python_
    programming language.

Psycopg 3 は、プログラミング言語 Python_ のために新たにデザインされた PostgreSQL_ データベースアダプターです。

..
    Psycopg 3 presents a familiar interface for everyone who has used
    `Psycopg 2`_ or any other `DB-API 2.0`_ database adapter, but allows to use
    more modern PostgreSQL and Python features, such as:

Psycopg 3 は、`Psycopg 2`_ やその他の `DB-API 2.0`_ データベースアダプターを使ったことのあるすべての人のために、馴染みのあるインターフェイスを提供します。しかし、以下のような PostgreSQL や Python のモダンな機能も利用できるようにします。

..
    - :ref:`Asynchronous support <async>`
    - :ref:`COPY support from Python objects <copy>`
    - :ref:`A redesigned connection pool <connection-pools>`
    - :ref:`Support for static typing <static-typing>`
    - :ref:`Server-side parameters binding <server-side-binding>`
    - :ref:`Prepared statements <prepared-statements>`
    - :ref:`Statements pipeline <pipeline-mode>`
    - :ref:`Binary communication <binary-data>`
    - :ref:`Direct access to the libpq functionalities <psycopg.pq>`

- :ref:`非同期 (async) のサポート <async>`
- :ref:`Python オブジェクトからの COPY のサポート <copy>`
- :ref:`再設計されたコネクション プール <connection-pools>`
- :ref:`静的型付けのサポート <static-typing>`
- :ref:`サーバーサイド パラメータ バインディング <server-side-binding>`
- :ref:`prepare されたステートメント <prepared-statements>`
- :ref:`ステートメント パイプライン <pipeline-mode>`
- :ref:`バイナリ通信 <binary-data>`
- :ref:`libpq の機能への直接アクセス <psycopg.pq>`

.. _Python: https://www.python.org/
.. _PostgreSQL: https://www.postgresql.org/
.. _Psycopg 2: https://www.psycopg.org/docs/
.. _DB-API 2.0: https://www.python.org/dev/peps/pep-0249/


..
    Documentation
    =============

ドキュメンテーション
====================

.. toctree::
    :maxdepth: 2

    basic/index
    advanced/index
    api/index

..
    Release notes
    -------------

リリースノート
--------------

.. toctree::
    :maxdepth: 1

    news
    news_pool


..
    Indices and tables
    ------------------

索引と一覧
------------------

* :ref:`genindex`
* :ref:`modindex`
