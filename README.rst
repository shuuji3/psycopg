Psycopg 3 ― PostgreSQL database adapter for Python documentation Japanese translation
===================================================

.. image:: https://readthedocs.org/projects/psycopg3-ja/badge/?version=latest
    :target: https://psycopg3-ja.readthedocs.io/ja/latest/?badge=latest
    :alt: Documentation Status

Psycopg 3 is a modern implementation of a PostgreSQL adapter for Python.

This repository manages the Japanese translation of Psycopg 3 documentation, served by Read the Docs at https://psycopg3-ja.readthedocs.io.

You can read the original English documentation at https://www.psycopg.org/psycopg3/docs/, and can see the source git repository for the source code.

Local preview
-------------

**Prerequisites:**

- Docker/OCI container engine

.. code::

    git clone https://github.com/shuuji3/psycopg3-docs-ja
    cd psycopg3-docs-ja/docs/

    # build a container named `psycopg-docs`
    make container-build

    # run the container to allow previewing at http://0.0.0.0:8000
    make container-serve

Deployment
----------

Just commit and push to the ``i18n/ja`` branch on GitHub. The Read the Docs build CI will be triggered and automatically build the documentation within about 90 sec. and refresh the page.
