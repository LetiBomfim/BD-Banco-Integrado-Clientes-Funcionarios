CREATE TABLE Cargo (
    id_cargo INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(30),
    nivel INT
        CHECK (nivel BETWEEN 1 AND 5),
    descricao VARCHAR(200)
);


CREATE TABLE Funcionario (
    id_funcionario INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_gerente INT,
    id_cargo INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    email VARCHAR(50),
    login VARCHAR(30) NOT NULL UNIQUE,
    data_admissao DATE,
    -- derivada: mantida por trigger
    situacao_conformidade VARCHAR(10) DEFAULT 'Regular'
        CHECK (situacao_conformidade IN ('Regular', 'Pendente', 'Irregular')),
    status_vinculo VARCHAR(20) DEFAULT 'Ativo'
        CHECK (status_vinculo IN ('Ativo', 'Desligado')),
    senha_hash VARCHAR(250) NOT NULL,


    FOREIGN KEY (id_gerente)
        REFERENCES Funcionario(id_funcionario),


    FOREIGN KEY (id_cargo)
        REFERENCES Cargo(id_cargo)
);


CREATE TABLE Cliente (
    id_cliente INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_funcionario INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    data_nascimento DATE,
    telefone VARCHAR(20),
    email VARCHAR(50),
    endereco VARCHAR(200),


    FOREIGN KEY (id_funcionario)
        REFERENCES Funcionario(id_funcionario)
);


CREATE TABLE Documento (
    id_documento INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente INT NOT NULL,
    nome_arquivo VARCHAR(100),
    tipo VARCHAR(40)
        CHECK (tipo IN ('RG', 'CNH', 'Comprovante de residência', 'Comprovante de renda', 'Outro')),
    arquivo BYTEA NOT NULL,


    FOREIGN KEY (id_cliente)
        REFERENCES Cliente(id_cliente)
);


CREATE TABLE Tipo_De_Conta (
    id_tipo INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descricao VARCHAR(40),
    taxa_manutencao DECIMAL(8,2)
);


CREATE TABLE Conta (
    id_conta INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_tipo INT NOT NULL,
    numero INT NOT NULL UNIQUE,
    saldo DECIMAL(15,2) NOT NULL DEFAULT 0
        CHECK (saldo >= 0),
    data_abertura DATE,
    status VARCHAR(20)
        CHECK (status IN ('Ativa', 'Bloqueada', 'Encerrada')),


    FOREIGN KEY (id_cliente)
        REFERENCES Cliente(id_cliente),


    FOREIGN KEY (id_tipo)
        REFERENCES Tipo_De_Conta(id_tipo)
);


CREATE TABLE Emprestimo (
    id_emprestimo INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_conta INT NOT NULL,
    id_funcionario INT NOT NULL,
    valor_emprestimo DECIMAL(15,2) NOT NULL
        CHECK (valor_emprestimo > 0),
    taxa_juros_mes DECIMAL(8,2),
    quantidade_parcelas INT,
    data_pedido DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'Ativo'
        CHECK (status IN ('Ativo', 'Quitado', 'Cancelado')),


    FOREIGN KEY (id_conta)
        REFERENCES Conta(id_conta),


    FOREIGN KEY (id_funcionario)
        REFERENCES Funcionario(id_funcionario)
);


CREATE TABLE Transacao (
    id_transacao INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_conta INT NOT NULL,
    id_funcionario INT NOT NULL,
    tipo VARCHAR(20) NOT NULL
        CHECK (tipo IN ('Deposito', 'Saque')),
    valor DECIMAL(15,2) NOT NULL
        CHECK (valor > 0),
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    descricao VARCHAR(50),


    FOREIGN KEY (id_conta)
        REFERENCES Conta(id_conta),


    FOREIGN KEY (id_funcionario)
        REFERENCES Funcionario(id_funcionario)
);


CREATE TABLE Certificacao (
    id_certificacao INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(50),
    entidade_emissora VARCHAR(50),
    validade_anos INT,
    descricao VARCHAR(200)
);


CREATE TABLE Treinamento (
    id_treinamento INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(50),
    descricao VARCHAR(200),
    carga_horaria FLOAT,
    categoria VARCHAR(30),
    obrigacao BOOLEAN DEFAULT false
);


CREATE TABLE Cargo_Certificacao (
    id_cargo INT NOT NULL,
    id_certificacao INT NOT NULL,


    PRIMARY KEY (id_cargo, id_certificacao),


    FOREIGN KEY (id_cargo)
        REFERENCES Cargo(id_cargo),


    FOREIGN KEY (id_certificacao)
        REFERENCES Certificacao(id_certificacao)
);


CREATE TABLE Funcionario_Certificacao (
    id_funcionario INT NOT NULL,
    id_certificacao INT NOT NULL,
    data_obtencao DATE,
    data_validade DATE,
    pdf_certificado BYTEA,


    PRIMARY KEY (id_funcionario, id_certificacao),


    CHECK (data_validade IS NULL OR data_validade >= data_obtencao),


    FOREIGN KEY (id_funcionario)
        REFERENCES Funcionario(id_funcionario),


    FOREIGN KEY (id_certificacao)
        REFERENCES Certificacao(id_certificacao)
);


CREATE TABLE Funcionario_Treinamento (
    id_funcionario INT NOT NULL,
    id_treinamento INT NOT NULL,
    data_inscricao DATE,
    data_conclusao DATE,
    progresso INT DEFAULT 0
        CHECK (progresso BETWEEN 0 AND 100),
    status VARCHAR(15) DEFAULT 'Inscrito'
        CHECK (status IN ('Inscrito', 'Em andamento', 'Concluido', 'Cancelado')),


    PRIMARY KEY (id_funcionario, id_treinamento),


    -- se Concluido, data_conclusao é obrigatória
    CONSTRAINT ck_conclusao_obrigatoria
        CHECK (status <> 'Concluido' OR data_conclusao IS NOT NULL),


    -- conclusão não pode ser antes da inscrição
    CONSTRAINT ck_conclusao_apos_inscricao
        CHECK (data_conclusao IS NULL OR data_conclusao >= data_inscricao),


    FOREIGN KEY (id_funcionario)
        REFERENCES Funcionario(id_funcionario),


    FOREIGN KEY (id_treinamento)
        REFERENCES Treinamento(id_treinamento)
);