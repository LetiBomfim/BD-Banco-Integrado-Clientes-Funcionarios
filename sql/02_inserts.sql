
INSERT INTO Cargo (nome, nivel, descricao) VALUES
    ('Gerente', 5, 'Gestao de agencia, equipes e operacoes'),
    ('Atendente', 2, 'Atendimento ao cliente, documentos e contas'),
    ('Analista Credito', 3, 'Analise e concessao de emprestimos'),
    ('Coordenador', 4, 'Gestao de certificacoes, treinamentos e conformidade');


INSERT INTO Funcionario (
    id_gerente, id_cargo, nome, cpf, email, login,
    data_admissao, situacao_conformidade, status_vinculo, senha_hash
) VALUES
    (NULL, 1, 'Helena Vasconcelos', '10120230301', 'helena.v@banco.local', 'helena.vasconcelos', '2022-02-10', 'Regular', 'Ativo', 'hash_helena_123'),
    (1, 2, 'Matheus Nogueira', '10120230302', 'matheus.n@banco.local', 'matheus.nogueira', '2023-03-15', 'Regular', 'Ativo', 'hash_matheus_123'),
    (1, 2, 'Clara Cavalcanti', '10120230303', 'clara.c@banco.local', 'clara.cavalcanti', '2023-05-01', 'Irregular', 'Ativo', 'hash_clara_123'),
    (1, 3, 'Gustavo Tavares', '10120230304', 'gustavo.t@banco.local', 'gustavo.tavares', '2022-08-20', 'Regular', 'Ativo', 'hash_gustavo_123'),
    (1, 2, 'Isabela Monteiro', '10120230305', 'isabela.m@banco.local', 'isabela.monteiro', '2024-01-12', 'Pendente', 'Ativo', 'hash_isabela_123'),
    (NULL, 1, 'Diego Azevedo', '10120230306', 'diego.a@banco.local', 'diego.azevedo', '2021-11-05', 'Pendente', 'Ativo', 'hash_diego_123'),
    (6, 3, 'Sofia Medeiros', '10120230307', 'sofia.m@banco.local', 'sofia.medeiros', '2023-09-18', 'Irregular', 'Ativo', 'hash_sofia_123'),
    (6, 2, 'Henrique Peixoto', '10120230308', 'henrique.p@banco.local', 'henrique.peixoto', '2024-03-04', 'Regular', 'Ativo', 'hash_henrique_123'),
    (6, 2, 'Laura Silveira', '10120230309', 'laura.s@banco.local', 'laura.silveira', '2024-06-22', 'Regular', 'Ativo', 'hash_laura_123'),
    (6, 4, 'Vinicius Bittencourt', '10120230310', 'vinicius.b@banco.local', 'vinicius.bittencourt', '2022-04-11', 'Regular', 'Ativo', 'hash_vinicius_123');


INSERT INTO Cliente (
    id_funcionario, nome, cpf, data_nascimento,
    telefone, email, endereco
) VALUES
    (2, 'Arthur Menezes', '20230340401', '1995-04-12', '61992000001', 'arthur.menezes@exemplo.com', 'SQN 205 Bloco A, Brasilia - DF'),
    (2, 'Valentina Prado', '20230340402', '1998-07-25', '61992000002', 'valentina.prado@exemplo.com', 'SHIS QI 11 Conjunto 4, Brasilia - DF'),
    (3, 'Bernardo Sampaio', '20230340403', '1990-11-03', '61992000003', 'bernardo.sampaio@exemplo.com', 'SCLN 308 Bloco C, Brasilia - DF'),
    (4, 'Manuela Fontes', '20230340404', '2000-01-19', '61992000004', 'manuela.fontes@exemplo.com', 'Guara II QE 28, Brasilia - DF'),
    (5, 'Samuel Castilho', '20230340405', '1988-09-14', '61992000005', 'samuel.castilho@exemplo.com', 'Taguatinga Norte QNM 12, DF'),
    (5, 'Alice Drummond', '20230340406', '1993-12-30', '61992000006', 'alice.drummond@exemplo.com', 'Aguas Claras Rua 10, DF'),
    (8, 'Theo Lacerda', '20230340407', '1997-06-08', '61992000007', 'theo.lacerda@exemplo.com', 'Sobradinho Quadra 06, DF'),
    (8, 'Lorena Queiroz', '20230340408', '1992-02-27', '61992000008', 'lorena.queiroz@exemplo.com', 'Ceilandia QNM 04, DF'),
    (9, 'Enzo Magalhaes', '20230340409', '2001-10-16', '61992000009', 'enzo.magalhaes@exemplo.com', 'Sudoeste SQSW 302, Brasilia - DF'),
    (9, 'Cecilia Vasconcellos', '20230340410', '1986-05-21', '61992000010', 'cecilia.vasc@exemplo.com', 'Lago Norte SHIN CA 05, Brasilia - DF');


-- DOCUMENTO:
-- Os arquivos binarios serao inseridos posteriormente por Python.


INSERT INTO Tipo_De_Conta (descricao, taxa_manutencao) VALUES
    ('Conta Corrente', 15.00),
    ('Conta Poupanca', 0.00);


INSERT INTO Conta (
    id_cliente, id_tipo, numero, saldo, data_abertura, status
) VALUES
    (1, 1, 10001, 2500.00, '2024-01-10', 'Ativa'),
    (2, 1, 10002, 4200.00, '2024-01-15', 'Ativa'),
    (3, 2, 10003, 8100.50, '2024-02-01', 'Ativa'),
    (4, 1, 10004, 1500.00, '2024-02-20', 'Ativa'),
    (5, 1, 10005, 500.00, '2024-03-05', 'Ativa'),
    (6, 2, 10006, 12500.00, '2024-03-18', 'Ativa'),
    (7, 1, 10007, 320.00, '2024-04-02', 'Bloqueada'),
    (8, 1, 10008, 5400.75, '2024-04-19', 'Ativa'),
    (9, 2, 10009, 0.00, '2024-05-10', 'Encerrada'),
    (10, 1, 10010, 0.00, '2024-06-01', 'Ativa');


INSERT INTO Transacao (
    id_conta, id_funcionario, tipo, valor, data_hora, descricao
) VALUES
    (1, 2, 'Deposito', 2500.00, '2024-01-10 10:15:00', 'Abertura de conta'),
    (2, 2, 'Deposito', 4500.00, '2024-01-15 11:00:00', 'Credito inicial'),
    (2, 2, 'Saque', 300.00, '2024-01-20 14:30:00', 'Saque em caixa'),
    (3, 3, 'Deposito', 8100.50, '2024-02-01 09:45:00', 'Deposito poupanca'),
    (4, 4, 'Deposito', 1500.00, '2024-02-20 16:10:00', 'Deposito inicial'),
    (5, 5, 'Deposito', 600.00, '2024-03-05 08:50:00', 'Deposito inicial'),
    (5, 5, 'Saque', 100.00, '2024-03-10 09:00:00', 'Saque em caixa'),
    (6, 5, 'Deposito', 12500.00, '2024-03-18 13:20:00', 'Reserva financeira'),
    (7, 8, 'Deposito', 320.00, '2024-04-02 15:05:00', 'Deposito inicial'),
    (8, 8, 'Deposito', 5400.75, '2024-04-19 10:40:00', 'Transferencia'),
    (9, 9, 'Deposito', 950.00, '2024-05-10 17:00:00', 'Deposito inicial'),
    (9, 9, 'Saque', 950.00, '2024-06-10 11:00:00', 'Encerramento de conta');


INSERT INTO Certificacao (nome, entidade_emissora, validade_anos, descricao) VALUES
    ('CPA-10', 'ANBIMA', 5, 'Certificacao basica para atendimento e produtos'),
    ('CPA-20', 'ANBIMA', 3, 'Certificacao para segmento varejo alta renda e credito'),
    ('CEA', 'ANBIMA', 3, 'Especialista em investimentos e credito'),
    ('LGPD Bancaria', 'FEBRABAN', 2, 'Privacidade e seguranca de dados bancarios');


INSERT INTO Treinamento (nome, descricao, carga_horaria, categoria, obrigacao) VALUES
    ('Prevencao a Lavagem de Dinheiro', 'Compliance e deteccao de operacoes atipicas', 8.0, 'Compliance', TRUE),
    ('Atendimento Acessivel', 'Boas praticas no atendimento ao cliente', 6.0, 'Atendimento', TRUE),
    ('Analise de Risco de Credito', 'Avaliacao de capacidade de pagamento', 12.0, 'Credito', TRUE),
    ('Seguranca da Informacao', 'Cuidados com senhas, acessos e arquivos', 4.0, 'Seguranca', TRUE);


INSERT INTO Cargo_Certificacao (id_cargo, id_certificacao) VALUES
    (1, 1),
    (1, 4),
    (2, 1),
    (3, 2),
    (3, 3),
    (4, 4);


INSERT INTO Funcionario_Certificacao (
    id_funcionario, id_certificacao, data_obtencao,
    data_validade, pdf_certificado
) VALUES
    (1, 1, '2023-01-10', '2028-01-10', NULL),
    (1, 4, '2025-02-01', '2027-02-01', NULL),
    (2, 1, '2024-03-10', '2029-03-10', NULL),
    (4, 2, '2024-05-15', '2027-05-15', NULL),
    (4, 3, '2024-06-01', '2027-06-01', NULL),
    (5, 1, '2021-10-01', '2026-10-01', NULL),
    (6, 1, '2021-12-10', '2026-12-10', NULL),
    (6, 4, '2025-01-20', '2027-01-20', NULL),
    (7, 2, '2023-12-05', '2026-12-05', NULL),
    (7, 3, '2024-07-10', '2027-07-10', NULL),
    (8, 1, '2024-09-01', '2029-09-01', NULL),
    (9, 1, '2025-06-01', '2030-06-01', NULL),
    (10, 4, '2025-01-10', '2027-01-10', NULL);


INSERT INTO Emprestimo (
    id_conta, id_funcionario, valor_emprestimo, taxa_juros_mes,
    quantidade_parcelas, data_pedido, status
) VALUES
    (1, 4, 5000.00, 1.45, 12, '2024-06-10', 'Ativo'),
    (2, 7, 8000.00, 1.30, 24, '2024-07-02', 'Ativo'),
    (4, 4, 3000.00, 1.60, 6, '2024-08-15', 'Quitado'),
    (5, 7, 1500.00, 1.80, 3, '2025-01-10', 'Cancelado');


INSERT INTO Funcionario_Treinamento (
    id_funcionario, id_treinamento, data_inscricao,
    data_conclusao, progresso, status
) VALUES
    (1, 1, '2025-01-10', '2025-01-15', 100, 'Concluido'),
    (1, 2, '2025-01-10', '2025-01-16', 100, 'Concluido'),
    (1, 3, '2025-01-10', '2025-01-17', 100, 'Concluido'),
    (1, 4, '2025-01-10', '2025-01-18', 100, 'Concluido'),
    (2, 2, '2025-02-01', '2025-02-05', 100, 'Concluido'),
    (3, 2, '2025-02-10', NULL, 50, 'Em andamento'),
    (4, 1, '2025-03-01', '2025-03-05', 100, 'Concluido'),
    (4, 2, '2025-03-01', '2025-03-06', 100, 'Concluido'),
    (4, 3, '2025-03-01', '2025-03-12', 100, 'Concluido'),
    (4, 4, '2025-03-01', '2025-03-08', 100, 'Concluido'),
    (5, 1, '2025-03-15', NULL, 0, 'Inscrito'),
    (6, 1, '2025-04-01', '2025-04-02', 100, 'Concluido'),
    (6, 2, '2025-04-01', '2025-04-02', 100, 'Concluido'),
    (6, 3, '2025-04-01', '2025-04-04', 100, 'Concluido'),
    (6, 4, '2025-04-01', '2025-04-03', 100, 'Concluido'),
    (7, 1, '2025-04-10', '2025-04-12', 100, 'Concluido'),
    (7, 2, '2025-04-10', '2025-04-13', 100, 'Concluido'),
    (7, 3, '2025-04-10', '2025-04-20', 100, 'Concluido'),
    (7, 4, '2025-04-10', '2025-04-14', 100, 'Concluido'),
    (8, 1, '2025-05-01', '2025-05-02', 100, 'Concluido'),
    (8, 2, '2025-05-01', '2025-05-04', 100, 'Concluido'),
    (8, 3, '2025-05-01', '2025-05-10', 100, 'Concluido'),
    (8, 4, '2025-05-01', '2025-05-03', 100, 'Concluido'),
    (9, 2, '2025-05-10', NULL, 25, 'Em andamento'),
    (9, 4, '2025-05-12', NULL, 0, 'Cancelado'),
    (10, 1, '2025-05-15', '2025-05-18', 100, 'Concluido'),
    (10, 2, '2025-05-15', '2025-05-19', 100, 'Concluido'),
    (10, 3, '2025-05-15', '2025-05-25', 100, 'Concluido'),
    (10, 4, '2025-05-15', '2025-05-17', 100, 'Concluido');
