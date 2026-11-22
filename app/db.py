from contextlib import contextmanager

import psycopg
from psycopg.rows import dict_row

import config

_conexao = None


def conectar():
    global _conexao
    if _conexao is None or _conexao.closed:
        _conexao = psycopg.connect(
            **config.DB,
            row_factory=dict_row,
            connect_timeout=5,
        )
    return _conexao


def fechar():
    global _conexao
    if _conexao is not None and not _conexao.closed:
        _conexao.close()
    _conexao = None


@contextmanager
def transacao():
    """Entrega um cursor dentro de uma transação."""
    conn = conectar()
    try:
        with conn.cursor() as cur:
            yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise


def consultar(sql, params=None):
    with transacao() as cur:
        cur.execute(sql, params)
        return cur.fetchall()


def consultar_um(sql, params=None):
    with transacao() as cur:
        cur.execute(sql, params)
        return cur.fetchone()


def executar(sql, params=None):
    with transacao() as cur:
        cur.execute(sql, params)
        return cur.fetchone() if cur.description else None
