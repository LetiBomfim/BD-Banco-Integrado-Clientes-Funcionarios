CREATE OR REPLACE FUNCTION fun_atualiza_saldo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tipo = 'Deposito' THEN
        UPDATE Conta
        SET saldo = saldo + NEW.valor
        WHERE NEW.id_conta = id_conta;
    ELSE 
        UPDATE Conta
        SET saldo = saldo - NEW.valor
        WHERE NEW.id_conta = id_conta;
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
    variavel_saldo NUMERIC;

BEGIN
    SELECT saldo INTO variavel_saldo
    FROM Conta
    WHERE id_conta = NEW.id_conta;

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


CREATE OR REPLACE FUNCTION fun_recalcula_situacao_certificacao()
RETURNS TRIGGER AS $$
DECLARE
    variavel_id_funcionario INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        variavel_id_funcionario := OLD.id_funcionario;
    ELSE
        variavel_id_funcionario := NEW.id_funcionario;
    END IF;

    UPDATE Funcionario f
    SET situacao_certificacao =
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM Cargo_Certificacao cc
                WHERE cc.id_cargo = f.id_cargo
            )
            AND NOT EXISTS (
                SELECT 1
                FROM Cargo_Certificacao cc
                LEFT JOIN Funcionario_Certificacao fc
                    ON cc.id_certificacao = fc.id_certificacao
                    AND fc.id_funcionario = f.id_funcionario
                WHERE cc.id_cargo = f.id_cargo
                  AND (
                      fc.id_certificacao IS NULL
                      OR fc.data_validade IS NULL
                      OR fc.data_validade < CURRENT_DATE
                  )
            )
            THEN 'Regular'
            ELSE 'Irregular'
        END
    WHERE f.id_funcionario = variavel_id_funcionario;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER recalcula_situacao_certificacao
AFTER INSERT OR UPDATE OR DELETE
ON Funcionario_Certificacao
FOR EACH ROW
EXECUTE FUNCTION fun_recalcula_situacao_certificacao();
