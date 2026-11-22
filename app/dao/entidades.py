import db
from seguranca import conferir_senha, gerar_hash

from .base import TabelaDAO


# =================================================================== GESTÃO DE PESSOAS
class CargoDAO(TabelaDAO):
    tabela = "cargo"
    pk = ("id_cargo",)
    colunas = ("nome", "nivel", "descricao")
    sql_listar = """
        SELECT c.id_cargo, c.nome, c.nivel, c.descricao,
               (SELECT string_agg(ce.nome, ', ' ORDER BY ce.nome)
                  FROM cargo_certificacao cc
                  JOIN certificacao ce ON ce.id_certificacao = cc.id_certificacao
                 WHERE cc.id_cargo = c.id_cargo)                              AS certificacoes_exigidas,
               (SELECT COUNT(*) FROM funcionario f WHERE f.id_cargo = c.id_cargo) AS qtd_funcionarios
          FROM cargo c"""
    ordem = "nivel DESC, nome"
    busca = ("nome", "descricao")
    sql_opcoes = "SELECT id_cargo AS id, nome AS rotulo FROM cargo ORDER BY nivel, nome"


class CertificacaoDAO(TabelaDAO):
    tabela = "certificacao"
    pk = ("id_certificacao",)
    colunas = ("nome", "entidade_emissora", "validade_anos", "descricao")
    sql_listar = """
        SELECT c.id_certificacao, c.nome, c.entidade_emissora, c.validade_anos, c.descricao,
               (SELECT COUNT(*) FROM funcionario_certificacao fc
                 WHERE fc.id_certificacao = c.id_certificacao
                   AND fc.data_validade >= CURRENT_DATE)                      AS qtd_validas
          FROM certificacao c"""
    ordem = "nome"
    busca = ("nome", "entidade_emissora")
    sql_opcoes = "SELECT id_certificacao AS id, nome AS rotulo FROM certificacao ORDER BY nome"


class CargoCertificacaoDAO(TabelaDAO):
    """Certificações exigidas por cargo (associativa N:N)."""
    tabela = "cargo_certificacao"
    pk = ("id_cargo", "id_certificacao")
    colunas = ("id_cargo", "id_certificacao")
    sql_listar = """
        SELECT cc.id_cargo, cc.id_certificacao, c.nome AS cargo, ce.nome AS certificacao,
               ce.entidade_emissora
          FROM cargo_certificacao cc
          JOIN cargo c         ON c.id_cargo = cc.id_cargo
          JOIN certificacao ce ON ce.id_certificacao = cc.id_certificacao"""
    ordem = "cargo, certificacao"
    busca = ("cargo", "certificacao")


class FuncionarioDAO(TabelaDAO):
    tabela = "funcionario"
    pk = ("id_funcionario",)
    # situacao_conformidade fica de fora: quem calcula é o trigger
    colunas = ("id_gerente", "id_cargo", "nome", "cpf", "email", "login", "data_admissao",
               "status_vinculo", "senha_hash")
    sql_listar = """
        SELECT f.id_funcionario, f.nome, f.cpf, f.email, f.login, f.data_admissao,
               f.situacao_conformidade, f.status_vinculo,
               c.nome AS cargo, g.nome AS gerente
          FROM funcionario f
          JOIN cargo c            ON c.id_cargo = f.id_cargo
          LEFT JOIN funcionario g ON g.id_funcionario = f.id_gerente"""
    ordem = "nome"
    busca = ("nome", "cpf", "login", "cargo")
    sql_opcoes = "SELECT id_funcionario AS id, nome AS rotulo FROM funcionario ORDER BY nome"

    def _preparar(self, dados):
        """Troca o campo 'senha' (texto digitado) pelo hash, que é o que vai para o banco."""
        dados = dict(dados)
        senha = dados.pop("senha", None)
        if senha:
            dados["senha_hash"] = gerar_hash(senha)
        return dados

    def inserir(self, dados):
        dados = self._preparar(dados)
        if not dados.get("senha_hash"):
            raise ValueError("Informe uma senha para o novo funcionário.")
        return super().inserir(dados)

    def atualizar(self, chave, dados):
        # senha em branco ao editar = mantém a senha atual
        super().atualizar(chave, self._preparar(dados))

    def autenticar(self, login, senha):
        """Devolve os dados do funcionário se login e senha estiverem corretos; senão, None."""
        linha = db.consultar_um("""
            SELECT f.id_funcionario, f.nome, f.senha_hash, f.status_vinculo,
                   f.situacao_conformidade, c.nome AS cargo, c.nivel
              FROM funcionario f
              JOIN cargo c ON c.id_cargo = f.id_cargo
             WHERE f.login = %s""", (login,))
        if not linha or not conferir_senha(senha, linha["senha_hash"]):
            return None
        if linha["status_vinculo"] != "Ativo":
            raise ValueError("Este usuário está desligado e não pode acessar o sistema.")
        linha.pop("senha_hash")
        return linha


class FuncionarioCertificacaoDAO(TabelaDAO):
    """Certificações obtidas por cada funcionário (associativa N:N, com o PDF)."""
    tabela = "funcionario_certificacao"
    pk = ("id_funcionario", "id_certificacao")
    colunas = ("id_funcionario", "id_certificacao", "data_obtencao", "data_validade",
               "pdf_certificado")
    sql_listar = """
        SELECT fc.id_funcionario, fc.id_certificacao, fc.data_obtencao, fc.data_validade,
               f.nome AS funcionario, ce.nome AS certificacao,
               CASE WHEN fc.data_validade < CURRENT_DATE      THEN 'Vencida'
                    WHEN fc.data_validade < CURRENT_DATE + 30 THEN 'Vence em breve'
                    ELSE 'Válida' END                                         AS situacao_validade,
               octet_length(fc.pdf_certificado)                                AS tamanho_pdf
          FROM funcionario_certificacao fc
          JOIN funcionario f   ON f.id_funcionario = fc.id_funcionario
          JOIN certificacao ce ON ce.id_certificacao = fc.id_certificacao"""
    ordem = "funcionario, certificacao"
    busca = ("funcionario", "certificacao", "situacao_validade")

    def validade_sugerida(self, id_certificacao, data_obtencao):
        """Data de obtenção + validade (em anos) da certificação."""
        linha = db.consultar_um("""
            SELECT (%s::date + make_interval(years => validade_anos))::date AS validade
              FROM certificacao WHERE id_certificacao = %s""", (data_obtencao, id_certificacao))
        return linha["validade"] if linha else None

    def do_funcionario(self, id_funcionario):
        return db.consultar(f"SELECT * FROM ({self.sql_listar}) AS t WHERE id_funcionario = %s "
                            f"ORDER BY {self.ordem}", (id_funcionario,))


class TreinamentoDAO(TabelaDAO):
    tabela = "treinamento"
    pk = ("id_treinamento",)
    colunas = ("nome", "descricao", "carga_horaria", "categoria", "obrigacao")
    sql_listar = """
        SELECT t.id_treinamento, t.nome, t.descricao, t.carga_horaria, t.categoria, t.obrigacao,
               (SELECT COUNT(*) FROM funcionario_treinamento ft
                 WHERE ft.id_treinamento = t.id_treinamento
                   AND ft.status = 'Concluido')                               AS qtd_concluintes
          FROM treinamento t"""
    ordem = "obrigacao DESC, nome"
    busca = ("nome", "categoria")
    sql_opcoes = "SELECT id_treinamento AS id, nome AS rotulo FROM treinamento ORDER BY nome"


class FuncionarioTreinamentoDAO(TabelaDAO):
    """Participação dos funcionários nos treinamentos (associativa N:N)."""
    tabela = "funcionario_treinamento"
    pk = ("id_funcionario", "id_treinamento")
    colunas = ("id_funcionario", "id_treinamento", "data_inscricao", "data_conclusao",
               "progresso", "status")
    sql_listar = """
        SELECT ft.id_funcionario, ft.id_treinamento, ft.data_inscricao, ft.data_conclusao,
               ft.progresso, ft.status, f.nome AS funcionario, t.nome AS treinamento, t.obrigacao
          FROM funcionario_treinamento ft
          JOIN funcionario f ON f.id_funcionario = ft.id_funcionario
          JOIN treinamento t ON t.id_treinamento = ft.id_treinamento"""
    ordem = "funcionario, treinamento"
    busca = ("funcionario", "treinamento", "status")


# =================================================================== ATENDIMENTO
class ClienteDAO(TabelaDAO):
    tabela = "cliente"
    pk = ("id_cliente",)
    colunas = ("id_funcionario", "nome", "cpf", "data_nascimento", "telefone", "email", "endereco")
    sql_listar = """
        SELECT cl.id_cliente, cl.nome, cl.cpf, cl.data_nascimento, cl.telefone, cl.email,
               cl.endereco, cl.id_funcionario, f.nome AS atendente,
               (SELECT COUNT(*) FROM conta c WHERE c.id_cliente = cl.id_cliente) AS qtd_contas
          FROM cliente cl
          JOIN funcionario f ON f.id_funcionario = cl.id_funcionario"""
    ordem = "nome"
    busca = ("nome", "cpf", "email", "atendente")
    sql_opcoes = "SELECT id_cliente AS id, nome || ' — CPF ' || cpf AS rotulo FROM cliente ORDER BY nome"


class DocumentoDAO(TabelaDAO):
    tabela = "documento"
    pk = ("id_documento",)
    colunas = ("id_cliente", "nome_arquivo", "tipo", "arquivo")
    # a listagem não traz o arquivo em si (pode ser grande), só o tamanho
    sql_listar = """
        SELECT d.id_documento, d.id_cliente, d.nome_arquivo, d.tipo, cl.nome AS cliente,
               octet_length(d.arquivo) AS tamanho_arquivo
          FROM documento d
          JOIN cliente cl ON cl.id_cliente = d.id_cliente"""
    ordem = "cliente, tipo"
    busca = ("cliente", "tipo", "nome_arquivo")


class TipoDeContaDAO(TabelaDAO):
    tabela = "tipo_de_conta"
    pk = ("id_tipo",)
    colunas = ("descricao", "taxa_manutencao")
    sql_listar = """
        SELECT t.id_tipo, t.descricao, t.taxa_manutencao,
               (SELECT COUNT(*) FROM conta c WHERE c.id_tipo = t.id_tipo) AS qtd_contas
          FROM tipo_de_conta t"""
    ordem = "descricao"
    busca = ("descricao",)
    sql_opcoes = "SELECT id_tipo AS id, descricao AS rotulo FROM tipo_de_conta ORDER BY descricao"


class ContaDAO(TabelaDAO):
    tabela = "conta"
    pk = ("id_conta",)
    # saldo fica de fora: só o trigger das transações altera
    colunas = ("id_cliente", "id_tipo", "numero", "data_abertura", "status")
    sql_listar = """
        SELECT c.id_conta, c.numero, c.saldo, c.data_abertura, c.status, c.id_cliente, c.id_tipo,
               cl.nome AS cliente, t.descricao AS tipo_conta
          FROM conta c
          JOIN cliente cl      ON cl.id_cliente = c.id_cliente
          JOIN tipo_de_conta t ON t.id_tipo = c.id_tipo"""
    ordem = "numero"
    busca = ("numero", "cliente", "tipo_conta", "status")
    sql_opcoes = """SELECT c.id_conta AS id, c.numero || ' — ' || cl.nome AS rotulo
                      FROM conta c JOIN cliente cl ON cl.id_cliente = c.id_cliente
                     ORDER BY c.numero"""

    def ativas(self):
        """Contas que podem ser movimentadas (para as telas de operação)."""
        return db.consultar("""
            SELECT c.id_conta, c.numero, c.saldo, cl.nome AS cliente
              FROM conta c JOIN cliente cl ON cl.id_cliente = c.id_cliente
             WHERE c.status = 'Ativa' ORDER BY c.numero""")

    def saldo(self, id_conta):
        linha = db.consultar_um("SELECT saldo FROM conta WHERE id_conta = %s", (id_conta,))
        return linha["saldo"] if linha else None


class TransacaoDAO(TabelaDAO):
    tabela = "transacao"
    pk = ("id_transacao",)
    colunas = ("id_conta", "id_funcionario", "tipo", "valor", "data_hora", "descricao")
    sql_listar = """
        SELECT t.id_transacao, t.data_hora, t.tipo, t.valor, t.descricao,
               t.id_conta, t.id_funcionario,
               c.numero AS numero_conta, cl.nome AS cliente, f.nome AS funcionario
          FROM transacao t
          JOIN conta c       ON c.id_conta = t.id_conta
          JOIN cliente cl    ON cl.id_cliente = c.id_cliente
          JOIN funcionario f ON f.id_funcionario = t.id_funcionario"""
    ordem = "data_hora DESC"
    busca = ("numero_conta", "cliente", "tipo", "descricao", "funcionario")


class EmprestimoDAO(TabelaDAO):
    tabela = "emprestimo"
    pk = ("id_emprestimo",)
    colunas = ("id_conta", "id_funcionario", "valor_emprestimo", "taxa_juros_mes",
               "quantidade_parcelas", "data_pedido", "status")
    sql_listar = """
        SELECT e.id_emprestimo, e.valor_emprestimo, e.taxa_juros_mes, e.quantidade_parcelas,
               e.data_pedido, e.status, e.id_conta, e.id_funcionario,
               c.numero AS numero_conta, cl.nome AS cliente, f.nome AS aprovado_por
          FROM emprestimo e
          JOIN conta c       ON c.id_conta = e.id_conta
          JOIN cliente cl    ON cl.id_cliente = c.id_cliente
          JOIN funcionario f ON f.id_funcionario = e.id_funcionario"""
    ordem = "data_pedido DESC"
    busca = ("numero_conta", "cliente", "status", "aprovado_por")