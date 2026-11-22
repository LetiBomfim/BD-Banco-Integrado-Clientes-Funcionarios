CREATE OR REPLACE PROCEDURE conceder_emprestimo(
    p_id_conta INT,
    p_id_funcionario INT,
    p_valor NUMERIC,
    p_taxa_juros NUMERIC,
    p_parcelas INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    variavel_id_emprestimo INT;
BEGIN
    INSERT INTO Emprestimo (
        id_conta,
        id_funcionario,
        valor_emprestimo,
        taxa_juros_mes,
        quantidade_parcelas,
        data_pedido,
        status
    )
    VALUES (
        p_id_conta,
        p_id_funcionario,
        p_valor,
        p_taxa_juros,
        p_parcelas,
        CURRENT_DATE,
        'Ativo'
    )
    RETURNING id_emprestimo INTO variavel_id_emprestimo;

    INSERT INTO Transacao (
        id_conta,
        id_funcionario,
        tipo,
        valor,
        data_hora,
        descricao
    )
    VALUES (
        p_id_conta,
        p_id_funcionario,
        'Deposito',
        p_valor,
        CURRENT_TIMESTAMP,
        'Credito referente ao emprestimo ' || variavel_id_emprestimo
    );

END;
$$;

--------------------------------------------------------


CREATE OR REPLACE PROCEDURE atualizar_situacoes(p_id_funcionario INT DEFAULT NULL)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Funcionario f
    SET situacao_conformidade = fun_calcula_conformidade(f.id_funcionario)
    WHERE p_id_funcionario IS NULL
       OR f.id_funcionario = p_id_funcionario;
END;
$$;