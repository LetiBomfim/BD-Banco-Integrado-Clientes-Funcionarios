"""TabelaDAO: CRUD genérico de uma tabela, com SQL puro.
Nomes de tabelas e colunas entram com sql.Identifier e os valores com %s,
o que impede SQL injection.
"""
from psycopg import sql

import db


class TabelaDAO:
    tabela = ""
    pk = ("id",)
    colunas = ()
    sql_listar = ""
    ordem = ""
    busca = ()
    sql_opcoes = ""

    # ------------------------------------------------------------ leitura
    def listar(self, texto=None):
        """Lista os registros; se 'texto' vier preenchido, filtra pelas colunas de busca."""
        consulta = f"SELECT * FROM ({self.sql_listar}) AS t"
        params = []
        if texto and self.busca:
            filtros = " OR ".join(f"CAST(t.{c} AS TEXT) ILIKE %s" for c in self.busca)
            consulta += f" WHERE {filtros}"
            params = [f"%{texto}%"] * len(self.busca)
        if self.ordem:
            consulta += f" ORDER BY {self.ordem}"
        return db.consultar(consulta, params)

    def buscar(self, chave):
        """Devolve um registro completo pela chave primária (ou None)."""
        consulta = sql.SQL("SELECT * FROM {} WHERE {}").format(
            sql.Identifier(self.tabela), self._where_pk())
        return db.consultar_um(consulta, self._valores_pk(chave))

    def opcoes(self):
        """Lista de (id, rótulo) para caixas de seleção."""
        return [(r["id"], r["rotulo"]) for r in db.consultar(self.sql_opcoes)]

    # ------------------------------------------------------------ escrita
    def inserir(self, dados):
        """Insere e devolve a chave primária gerada (tupla)."""
        dados = self._filtrar(dados)
        consulta = sql.SQL("INSERT INTO {} ({}) VALUES ({}) RETURNING {}").format(
            sql.Identifier(self.tabela),
            sql.SQL(", ").join(map(sql.Identifier, dados)),
            sql.SQL(", ").join(sql.Placeholder() * len(dados)),
            sql.SQL(", ").join(map(sql.Identifier, self.pk)),
        )
        linha = db.executar(consulta, list(dados.values()))
        return tuple(linha[c] for c in self.pk)

    def atualizar(self, chave, dados):
        dados = self._filtrar(dados)
        if not dados:
            return
        consulta = sql.SQL("UPDATE {} SET {} WHERE {}").format(
            sql.Identifier(self.tabela),
            sql.SQL(", ").join(sql.SQL("{} = %s").format(sql.Identifier(c)) for c in dados),
            self._where_pk(),
        )
        db.executar(consulta, list(dados.values()) + self._valores_pk(chave))

    def excluir(self, chave):
        consulta = sql.SQL("DELETE FROM {} WHERE {}").format(
            sql.Identifier(self.tabela), self._where_pk())
        db.executar(consulta, self._valores_pk(chave))

    def chave_de(self, linha):
        return tuple(linha[c] for c in self.pk)

    def _filtrar(self, dados):
        return {c: v for c, v in dados.items() if c in self.colunas}

    def _where_pk(self):
        return sql.SQL(" AND ").join(
            sql.SQL("{} = %s").format(sql.Identifier(c)) for c in self.pk)

    def _valores_pk(self, chave):
        if not isinstance(chave, (tuple, list)):
            chave = (chave,)
        return list(chave)