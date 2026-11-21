CREATE VIEW view_conformidade_equipe AS
SELECT
    f.nome AS funcionario,
    c.nome AS cargo,
    g.nome AS gerente,
    cert.nome AS certificacao_exigida,
    fc.data_validade
FROM Funcionario f

JOIN Cargo c
    ON f.id_cargo = c.id_cargo

LEFT JOIN Funcionario g
    ON f.id_gerente = g.id_funcionario

LEFT JOIN Cargo_Certificacao cc
    ON c.id_cargo = cc.id_cargo

LEFT JOIN Certificacao cert
    ON cc.id_certificacao = cert.id_certificacao

LEFT JOIN Funcionario_Certificacao fc
    ON f.id_funcionario = fc.id_funcionario
    AND cert.id_certificacao = fc.id_certificacao;


CREATE VIEW view_extrato_conta AS
SELECT
    t.id_transacao,
    co.numero AS numero_conta,
    cl.nome AS cliente,
    t.data_hora,
    t.tipo,
    t.valor,
    t.descricao,
    f.nome AS funcionario_responsavel,
    co.saldo AS saldo_atual
FROM Transacao t

JOIN Conta co
    ON t.id_conta = co.id_conta

JOIN Cliente cl
    ON co.id_cliente = cl.id_cliente

LEFT JOIN Funcionario f
    ON t.id_funcionario = f.id_funcionario;