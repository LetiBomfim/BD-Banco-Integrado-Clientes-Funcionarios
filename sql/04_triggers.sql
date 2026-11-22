CREATE OR REPLACE FUNCTION fun_atualiza_saldo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tipo = 'Deposito' THEN
        UPDATE Conta
        SET saldo = saldo + NEW.valor
        WHERE Conta.id_conta = NEW.id_conta;
    ELSE 
        UPDATE Conta
        SET saldo = saldo - NEW.valor
        WHERE Conta.id_conta = NEW.id_conta;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER atualiza_saldo
AFTER INSERT ON Transacao
FOR EACH ROW
EXECUTE FUNCTION fun_atualiza_saldo();

----------------------------------------------------------------

CREATE OR REPLACE FUNCTION fun_bloquea_saque_sem_saldo()
RETURNS TRIGGER AS $$
DECLARE
    variavel_saldo  NUMERIC;
    variavel_status VARCHAR;
BEGIN
    SELECT saldo, status INTO variavel_saldo, variavel_status
    FROM Conta
    WHERE id_conta = NEW.id_conta;

    IF variavel_status <> 'Ativa' THEN
        RAISE EXCEPTION 'Operacao nao permitida: conta %', lower(variavel_status);
    END IF;

    IF NEW.tipo = 'Saque' AND variavel_saldo < NEW.valor THEN
        RAISE EXCEPTION 'Saldo insuficiente para realizar o saque';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER bloquea_saque_sem_saldo
BEFORE INSERT ON Transacao
FOR EACH ROW
EXECUTE FUNCTION fun_bloquea_saque_sem_saldo();

--------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fun_desaprova_emprestimo()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Funcionario f
        JOIN Cargo_Certificacao cc
            ON f.id_cargo = cc.id_cargo
        LEFT JOIN Funcionario_Certificacao fc
            ON f.id_funcionario = fc.id_funcionario
            AND cc.id_certificacao = fc.id_certificacao
        WHERE f.id_funcionario = NEW.id_funcionario
          AND (
              fc.id_certificacao IS NULL
              OR fc.data_validade < CURRENT_DATE
          )
    ) THEN
        RAISE EXCEPTION
            'Emprestimo nao aprovado: funcionario sem todas as certificacoes obrigatorias validas';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER desaprova_emprestimo
BEFORE INSERT ON Emprestimo
FOR EACH ROW
EXECUTE FUNCTION fun_desaprova_emprestimo();


--------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fun_calcula_conformidade(p_id_funcionario INT)
RETURNS VARCHAR AS $$
BEGIN
    -- 1) Irregular: cargo exige certificacao que ele nao tem ou que esta vencida
    IF EXISTS (
        SELECT 1
        FROM Funcionario f
        JOIN Cargo_Certificacao cc
            ON cc.id_cargo = f.id_cargo
        LEFT JOIN Funcionario_Certificacao fc
            ON fc.id_funcionario = f.id_funcionario
           AND fc.id_certificacao = cc.id_certificacao
        WHERE f.id_funcionario = p_id_funcionario
          AND (fc.id_certificacao IS NULL
               OR fc.data_validade < CURRENT_DATE)
    ) THEN
        RETURN 'Irregular';
    END IF;

    -- 2) Pendente: certificacao exigida vence em ate 30 dias
    IF EXISTS (
        SELECT 1
        FROM Funcionario f
        JOIN Cargo_Certificacao cc
            ON cc.id_cargo = f.id_cargo
        JOIN Funcionario_Certificacao fc
            ON fc.id_funcionario = f.id_funcionario
           AND fc.id_certificacao = cc.id_certificacao
        WHERE f.id_funcionario = p_id_funcionario
          AND fc.data_validade BETWEEN CURRENT_DATE AND CURRENT_DATE + 30
    ) THEN
        RETURN 'Pendente';
    END IF;

    --    Pendente: algum treinamento obrigatorio ainda nao Concluido
    IF EXISTS (
        SELECT 1
        FROM Treinamento t
        WHERE t.obrigacao = TRUE
          AND NOT EXISTS (
              SELECT 1
              FROM Funcionario_Treinamento ft
              WHERE ft.id_funcionario = p_id_funcionario
                AND ft.id_treinamento = t.id_treinamento
                AND ft.status = 'Concluido'
          )
    ) THEN
        RETURN 'Pendente';
    END IF;

    -- 3) Regular
    RETURN 'Regular';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fun_trigger_conformidade()
RETURNS TRIGGER AS $$
DECLARE
    v_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_id := OLD.id_funcionario;
    ELSE
        v_id := NEW.id_funcionario;
    END IF;

    UPDATE Funcionario
    SET situacao_conformidade = fun_calcula_conformidade(v_id)
    WHERE id_funcionario = v_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER recalcula_conformidade_certificacao
AFTER INSERT OR UPDATE OR DELETE ON Funcionario_Certificacao
FOR EACH ROW EXECUTE FUNCTION fun_trigger_conformidade();

CREATE TRIGGER recalcula_conformidade_treinamento
AFTER INSERT OR UPDATE OR DELETE ON Funcionario_Treinamento
FOR EACH ROW EXECUTE FUNCTION fun_trigger_conformidade();