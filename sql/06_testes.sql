-- ROTEIRO DE TESTES 
-- Pre-requisito: Ter rodado os blocos NA ORDEM.
-- Hoje de referencia: 2026-11-22
-------------------------------------------------------------------


-- 1) BASELINE: situacoes desatualizadas vindas do seed
SELECT id_funcionario AS id, nome, situacao_conformidade FROM Funcionario ORDER BY 1;
-- esperado: 1 Regular | 2 Regular | 3 Irregular | 4 Regular | 5 Pendente
--           6 Pendente | 7 Irregular | 8 Regular | 9 Regular | 10 Regular
--           (2, 5, 7 e 9 estao errados de proposito)


-- 2) PROCEDURE atualizar_situacoes
-- 2a) com um funcionario: so o Matheus (2) muda
CALL atualizar_situacoes(2);
SELECT id_funcionario AS id, situacao_conformidade FROM Funcionario
WHERE id_funcionario IN (2, 5, 7, 9) ORDER BY 1;
-- esperado: 2 Pendente | 5 Pendente | 7 Irregular | 9 Regular  (5, 7 e 9 seguem errados)

-- 2b) geral: corrige todo mundo
CALL atualizar_situacoes();
SELECT id_funcionario AS id, nome, situacao_conformidade FROM Funcionario ORDER BY 1;
-- esperado: 1 Regular | 2 Pendente | 3 Irregular | 4 Regular | 5 Irregular
--           6 Pendente | 7 Pendente | 8 Regular | 9 Pendente | 10 Regular


-- 3) TRIGGER DE CERTIFICACAO: Clara (3) recebe a CPA-10 que faltava
INSERT INTO Funcionario_Certificacao (id_funcionario, id_certificacao, data_obtencao, data_validade)
VALUES (3, 1, '2025-01-01', '2030-01-01');
SELECT situacao_conformidade FROM Funcionario WHERE id_funcionario = 3;
-- esperado: Pendente (saiu de Irregular, mas falta treinamento obrigatorio)


-- 4) TRIGGER DE TREINAMENTO: Henrique (8) deixa de ter um treinamento concluido
UPDATE Funcionario_Treinamento
SET status = 'Em andamento', data_conclusao = NULL, progresso = 80
WHERE id_funcionario = 8 AND id_treinamento = 4;
SELECT situacao_conformidade FROM Funcionario WHERE id_funcionario = 8;
-- esperado: Pendente (era Regular)


-- 5) TRIGGERS DE SALDO (conta 5 = numero 10005, saldo inicial 500.00)
INSERT INTO Transacao (id_conta, id_funcionario, tipo, valor, data_hora, descricao)
VALUES (5, 2, 'Deposito', 200.00, NOW(), 'Teste deposito');
INSERT INTO Transacao (id_conta, id_funcionario, tipo, valor, data_hora, descricao)
VALUES (5, 2, 'Saque', 150.00, NOW(), 'Teste saque');
SELECT saldo FROM Conta WHERE id_conta = 5;
-- esperado: 550.00

-- saque maior que o saldo deve ser bloqueado
DO $$
BEGIN
    INSERT INTO Transacao (id_conta, id_funcionario, tipo, valor, data_hora, descricao)
    VALUES (5, 2, 'Saque', 99999.00, NOW(), 'Saque sem saldo');
    RAISE NOTICE 'FALHOU: o saque deveria ter sido bloqueado';
EXCEPTION WHEN raise_exception THEN
    RAISE NOTICE 'OK, bloqueado: %', SQLERRM;
END $$;
SELECT saldo FROM Conta WHERE id_conta = 5;
-- esperado: 550.00 (inalterado)



-- 6) TRIGGER DE BLOQUEIO DE SAQUE (conta 7 esta Bloqueada: deve negar o emprestimo e nao deixar rastro)
DO $$
BEGIN
    CALL conceder_emprestimo(7, 4, 500.00, 1.50, 5);
    RAISE NOTICE 'FALHOU: conta bloqueada deveria negar';
EXCEPTION WHEN raise_exception THEN
    RAISE NOTICE 'OK, negado: %', SQLERRM;
END $$;
SELECT COUNT(*) FROM Emprestimo;
-- esperado: 4 (nada foi criado)


-- 7) EMPRESTIMO (conta 4, saldo inicial 1500.00)
-- 7a) aprovado: Gustavo (4) tem CPA-20 e CEA validas
CALL conceder_emprestimo(4, 4, 1000.00, 1.50, 10);
SELECT saldo FROM Conta WHERE id_conta = 4;
-- esperado: 2500.00
SELECT COUNT(*) FROM Emprestimo;
-- esperado: 5

-- 7b) negado: Isabela (5) tem a CPA-10 vencida
DO $$
BEGIN
    CALL conceder_emprestimo(4, 5, 1000.00, 1.50, 10);
    RAISE NOTICE 'FALHOU: o emprestimo deveria ter sido negado';
EXCEPTION WHEN raise_exception THEN
    RAISE NOTICE 'OK, negado: %', SQLERRM;
END $$;
SELECT COUNT(*) FROM Emprestimo;
-- esperado: 5 (nada foi criado)
SELECT saldo FROM Conta WHERE id_conta = 4;
-- esperado: 2500.00 (sem credito)


-- 8) VIEWS
SELECT * FROM view_extrato_conta WHERE numero_conta = 10005 ORDER BY data_hora;
-- esperado: 4 linhas (2 do seed + deposito 200 + saque 150) | Samuel Castilho | saldo_atual 550.00

SELECT * FROM view_conformidade_equipe WHERE funcionario = 'Isabela Monteiro';
-- esperado: Atendente | gerente Helena Vasconcelos | CPA-10 | validade 2026-10-01


-- 9) CHECAGEM FINAL (as duas devem voltar 0 linhas)
SELECT c.numero, c.saldo
FROM Conta c
LEFT JOIN Transacao t ON t.id_conta = c.id_conta
GROUP BY c.id_conta, c.numero, c.saldo
HAVING c.saldo <> COALESCE(SUM(CASE WHEN t.tipo = 'Deposito' THEN t.valor ELSE -t.valor END), 0);

SELECT id_funcionario, situacao_conformidade
FROM Funcionario
WHERE situacao_conformidade <> fun_calcula_conformidade(id_funcionario);

-- 10) NOVAS REGRAS 
-- 10a) conta nova sem informar saldo comeca com 0 e soma depositos
INSERT INTO Conta (id_cliente, id_tipo, numero, data_abertura, status)
VALUES (1, 1, 20001, CURRENT_DATE, 'Ativa');
INSERT INTO Transacao (id_conta, id_funcionario, tipo, valor, descricao)
VALUES ((SELECT id_conta FROM Conta WHERE numero = 20001), 2, 'Deposito', 100.00, 'Teste conta nova');
SELECT numero, saldo FROM Conta WHERE numero = 20001;
-- esperado: 20001 | 100.00

-- 10b) valor negativo, numero de conta repetido, alterar/excluir transacao: todos recusados
DO $$
BEGIN
    BEGIN
        INSERT INTO Transacao (id_conta, id_funcionario, tipo, valor) VALUES (1, 2, 'Saque', -1000);
        RAISE NOTICE 'FALHOU: valor negativo aceito';
    EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK, valor negativo recusado';
    END;
    BEGIN
        INSERT INTO Conta (id_cliente, id_tipo, numero, status) VALUES (1, 1, 10001, 'Ativa');
        RAISE NOTICE 'FALHOU: numero repetido aceito';
    EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'OK, numero repetido recusado';
    END;
    BEGIN
        DELETE FROM Transacao WHERE id_transacao = 1;
        RAISE NOTICE 'FALHOU: exclusao de transacao aceita';
    EXCEPTION WHEN raise_exception THEN RAISE NOTICE 'OK, exclusao bloqueada: %', SQLERRM;
    END;
    BEGIN
        UPDATE Transacao SET valor = 1 WHERE id_transacao = 1;
        RAISE NOTICE 'FALHOU: alteracao de transacao aceita';
    EXCEPTION WHEN raise_exception THEN RAISE NOTICE 'OK, alteracao bloqueada';
    END;
END $$;

-- 10c) troca de cargo recalcula a situacao: Matheus (2, Atendente) vira Analista Credito,
--      que exige CPA-20 e CEA, que ele nao tem
UPDATE Funcionario SET id_cargo = 3 WHERE id_funcionario = 2;
SELECT situacao_conformidade FROM Funcionario WHERE id_funcionario = 2;
-- esperado: Irregular
UPDATE Funcionario SET id_cargo = 2 WHERE id_funcionario = 2;
SELECT situacao_conformidade FROM Funcionario WHERE id_funcionario = 2;
-- esperado: Pendente (volta ao que era)

-- 10d) funcionario desligado nao aprova emprestimo
UPDATE Funcionario SET status_vinculo = 'Desligado' WHERE id_funcionario = 4;
DO $$
BEGIN
    CALL conceder_emprestimo(4, 4, 100.00, 1.50, 2);
    RAISE NOTICE 'FALHOU: desligado aprovou emprestimo';
EXCEPTION WHEN raise_exception THEN
    RAISE NOTICE 'OK, negado: %', SQLERRM;
END $$;
UPDATE Funcionario SET status_vinculo = 'Ativo' WHERE id_funcionario = 4;
