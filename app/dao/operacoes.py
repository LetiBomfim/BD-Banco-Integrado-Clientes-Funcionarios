import db


# =================================================================== MOVIMENTAÇÃO DE CONTA
def _movimentar(id_conta, id_funcionario, tipo, valor, descricao):
    with db.transacao() as cur:
        cur.execute("""
            INSERT INTO transacao (id_conta, id_funcionario, tipo, valor, descricao)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id_transacao""",
                    (id_conta, id_funcionario, tipo, valor, descricao))
        id_transacao = cur.fetchone()["id_transacao"]
        cur.execute("SELECT saldo FROM conta WHERE id_conta = %s", (id_conta,))
        saldo = cur.fetchone()["saldo"]
    return {"id_transacao": id_transacao, "saldo": saldo}


def depositar(id_conta, id_funcionario, valor, descricao=None):
    return _movimentar(id_conta, id_funcionario, "Deposito", valor, descricao)


def sacar(id_conta, id_funcionario, valor, descricao=None):
    return _movimentar(id_conta, id_funcionario, "Saque", valor, descricao)


def abrir_conta(id_cliente, id_tipo, numero, id_funcionario, deposito_inicial=0):
    if deposito_inicial and deposito_inicial < 0:
        raise ValueError("O depósito inicial não pode ser negativo.")
    with db.transacao() as cur:
        cur.execute("""
            INSERT INTO conta (id_cliente, id_tipo, numero, data_abertura, status)
            VALUES (%s, %s, %s, CURRENT_DATE, 'Ativa')
            RETURNING id_conta""", (id_cliente, id_tipo, numero))
        id_conta = cur.fetchone()["id_conta"]
        if deposito_inicial:
            cur.execute("""
                INSERT INTO transacao (id_conta, id_funcionario, tipo, valor, descricao)
                VALUES (%s, %s, 'Deposito', %s, 'Depósito inicial')""",
                        (id_conta, id_funcionario, deposito_inicial))
    return id_conta


def extrato(numero_conta):
    return db.consultar("""
        SELECT * FROM view_extrato_conta
         WHERE numero_conta = %s
         ORDER BY data_hora DESC, id_transacao DESC""", (numero_conta,))


# =================================================================== EMPRÉSTIMO
def conceder_emprestimo(id_conta, id_funcionario, valor, taxa_juros_mes, parcelas):
    with db.transacao() as cur:
        cur.execute("CALL conceder_emprestimo(%s::int, %s::int, %s::numeric, %s::numeric, %s::int)",
                    (id_conta, id_funcionario, valor, taxa_juros_mes, parcelas))
        cur.execute("""
            SELECT e.id_emprestimo, c.saldo
              FROM emprestimo e JOIN conta c ON c.id_conta = e.id_conta
             WHERE e.id_conta = %s
             ORDER BY e.id_emprestimo DESC LIMIT 1""", (id_conta,))
        return cur.fetchone()


# =================================================================== CONFORMIDADE DA EQUIPE
def atualizar_situacoes(id_funcionario=None):
    db.executar("CALL atualizar_situacoes(%s::int)", (id_funcionario,))


def conformidade_equipe(id_gerente=None):
    sql = "SELECT * FROM view_conformidade_equipe"
    params = None
    if id_gerente is not None:
        sql += " WHERE id_funcionario IN (SELECT id_funcionario FROM funcionario WHERE id_gerente = %s)"
        params = (id_gerente,)
    return db.consultar(sql + " ORDER BY funcionario, certificacao_exigida", params)


def resumo_situacoes():
    linhas = db.consultar("""
        SELECT situacao_conformidade, COUNT(*) AS quantidade
          FROM funcionario
         WHERE status_vinculo = 'Ativo'
         GROUP BY situacao_conformidade""")
    resumo = {"Regular": 0, "Pendente": 0, "Irregular": 0}
    for linha in linhas:
        resumo[linha["situacao_conformidade"]] = linha["quantidade"]
    return resumo