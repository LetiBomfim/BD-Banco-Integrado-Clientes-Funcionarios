"""Traduz erros do PostgreSQL em mensagens claras para o usuário."""
import psycopg
from psycopg import errors

# nome da restrição CHECK -> mensagem (nomes automáticos do PostgreSQL: tabela_coluna_check)
MENSAGENS_CHECK = {
    "conta_saldo_check": "O saldo da conta não pode ficar negativo.",
    "conta_status_check": "Status da conta inválido.",
    "transacao_valor_check": "O valor da transação deve ser maior que zero.",
    "transacao_tipo_check": "O tipo da transação deve ser Depósito ou Saque.",
    "emprestimo_valor_emprestimo_check": "O valor do empréstimo deve ser maior que zero.",
    "emprestimo_status_check": "Status do empréstimo inválido.",
    "cargo_nivel_check": "O nível do cargo deve ficar entre 1 e 5.",
    "funcionario_treinamento_progresso_check": "O progresso deve ficar entre 0 e 100.",
    "ck_conclusao_obrigatoria": "Uma participação concluída precisa ter data de conclusão.",
    "ck_conclusao_apos_inscricao": "A data de conclusão não pode ser anterior à inscrição.",
    "funcionario_certificacao_check": "A data de validade precisa ser posterior à data de obtenção.",
    "documento_tipo_check": "Tipo de documento inválido.",
}

# nome da tabela -> como aparece na mensagem
NOMES_TABELAS = {
    "cliente": "clientes", "conta": "contas", "transacao": "transações",
    "emprestimo": "empréstimos", "documento": "documentos", "funcionario": "funcionários",
    "cargo": "cargos", "certificacao": "certificações", "treinamento": "treinamentos",
    "cargo_certificacao": "certificações exigidas por cargo",
    "funcionario_certificacao": "certificações de funcionários",
    "funcionario_treinamento": "participações em treinamentos",
    "tipo_de_conta": "tipos de conta",
}


def traduzir(exc: Exception) -> str:
    """Recebe um erro (do banco ou de validação) e devolve um texto para mostrar na tela."""
    if isinstance(exc, errors.RaiseException):
        # mensagens escritas nos triggers e procedures com RAISE EXCEPTION
        return exc.diag.message_primary or str(exc)

    if isinstance(exc, errors.UniqueViolation):
        detalhe = exc.diag.message_detail or ""
        campo = detalhe.split("(")[1].split(")")[0] if "(" in detalhe else "informado"
        return f"Já existe um registro com esse {campo.replace('_', ' ')}."

    if isinstance(exc, errors.ForeignKeyViolation):
        detalhe = exc.diag.message_detail or ""
        if "is still referenced" in detalhe or "ainda é referenciad" in detalhe:
            tabela = NOMES_TABELAS.get(exc.diag.table_name, exc.diag.table_name)
            return ("Este registro não pode ser excluído porque ainda está ligado a "
                    f"{tabela}. Exclua ou altere esses registros antes.")
        return "O registro escolhido em um dos campos de ligação não existe."

    if isinstance(exc, errors.CheckViolation):
        return MENSAGENS_CHECK.get(exc.diag.constraint_name,
                                   "Algum valor informado não é permitido para este campo.")

    if isinstance(exc, errors.NotNullViolation):
        return f"O campo {exc.diag.column_name.replace('_', ' ')} é obrigatório."

    if isinstance(exc, errors.StringDataRightTruncation):
        return "Um dos textos informados é maior do que o permitido."

    if isinstance(exc, (errors.InvalidTextRepresentation, errors.InvalidDatetimeFormat,
                        errors.NumericValueOutOfRange, errors.DatetimeFieldOverflow)):
        return "Um dos valores informados está em formato inválido."

    if isinstance(exc, psycopg.OperationalError):
        return ("Não foi possível conectar ao banco de dados. Confira se o PostgreSQL "
                "está rodando e se os dados do arquivo .env estão corretos.")

    if isinstance(exc, ValueError):
        # erros de validação que o próprio código levanta (ex.: "Informe uma senha")
        return str(exc)

    return f"Erro inesperado: {exc}"