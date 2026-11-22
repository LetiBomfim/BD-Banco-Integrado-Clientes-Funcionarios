# Sistema de Gestão Interna

Projeto final da disciplina de Banco de Dados.

Este é um sistema desktop usado pelos funcionários de uma instituição bancária e possui dois módulos:

- **Atendimento:** clientes, documentos, contas, depósitos e saques, empréstimos e extrato.
- **Gestão de Equipe:** cargos, certificações exigidas por cargo, certificações dos funcionários, treinamentos e o painel de conformidade da equipe.

O diferencial do projeto é controlar se cada funcionário tem as certificações exigidas pelo cargo. Só quem tem todas as certificações válidas pode aprovar empréstimos, e essa regra é garantida pelo próprio banco de dados, com triggers.

**Tecnologias:** Python 3.10+ · Tkinter (interface) · psycopg 3 (integração) · PostgreSQL 13+ (banco). Nenhum framework é usado.

## Como rodar

### 1. Banco de dados

1. No pgAdmin, crie um banco.
2. Abra o **Query Tool** nesse banco e execute, **nesta ordem**:
   `01_criacao_tabelas.sql` → `02_inserts.sql` → `03_views.sql` → `04_triggers.sql` → `05_procedures.sql`
3. (Opcional) Execute o `06_testes.sql` e confira, na aba **Messages**, que só aparecem linhas com `OK`.

> O `02_inserts.sql` precisa rodar **antes** do `04_triggers.sql`, porque os dados de exemplo já trazem os saldos calculados.

### 2. Ambiente Python

```bash
python3 -m venv .venv
source .venv/bin/activate        # no Windows (PowerShell): .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 3. Configuração

Copie o `.env.example` para `.env` e preencha com os dados do **seu** PostgreSQL:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=banco_integrado
DB_USER=postgres
DB_PASSWORD=sua_senha
```

### 4. Dados binários

```bash
python scripts/popular_binarios.py
```

Grava um RG e um comprovante de residência em PDF para cada cliente e o PDF do certificado de cada funcionário. Pode ser executado mais de uma vez sem duplicar nada.

### 5. Aplicação

> As telas estão em desenvolvimento.

Todos os funcionários de exemplo usam a senha **`senha123`**. Exemplo de login de gerente: `helena.vasconcelos`.

## Camada de persistência

As telas nunca escrevem SQL: elas chamam os DAOs (CRUD de uma tabela) e o módulo `operacoes` (operações que envolvem várias tabelas, procedures e views).

```python
from dao import ClienteDAO, traduzir
from dao import operacoes

try:
    clientes = ClienteDAO().listar("texto da busca")
    operacoes.depositar(id_conta, id_funcionario, 100)
except Exception as e:
    messagebox.showerror("Erro", traduzir(e))
```

- Toda operação roda dentro de uma transação: **COMMIT** se tudo der certo, **ROLLBACK** se houver qualquer erro.
- Nomes de tabelas e colunas entram com `psycopg.sql.Identifier` e os valores como parâmetros `%s`, o que evita SQL injection.
- Os erros do PostgreSQL, inclusive as mensagens dos triggers, são convertidos por `traduzir(e)` em texto em português.
- Para depósitos, saques e empréstimos, use o `operacoes`, e não o `TransacaoDAO`/`EmprestimoDAO` direto.

O diagrama da camada para a tabela `conta` está em [`docs/diagrama_persistencia.png`](docs/diagrama_persistencia.png).
