"""
Popula os dados binários de exemplo (BYTEA) usando a camada de persistência.

- documento.arquivo: 2 documentos em PDF para cada cliente (RG e comprovante de residência)
- funcionario_certificacao.pdf_certificado: o certificado em PDF de cada certificação
"""
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "app"))

import db  # noqa: E402
from dao import DocumentoDAO, FuncionarioCertificacaoDAO  # noqa: E402


def gerar_pdf(titulo, linhas):
    """Monta um PDF simples de uma página, com título e linhas de texto."""
    def texto(s):
        s = s.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
        return s.encode("cp1252")

    conteudo = b"BT /F1 20 Tf 60 770 Td (" + texto(titulo) + b") Tj ET\n"
    conteudo += b"0.6 0.6 0.6 RG 60 755 m 535 755 l S\n"
    y = 720
    for linha in linhas:
        conteudo += b"BT /F1 12 Tf 60 %d Td (" % y + texto(linha) + b") Tj ET\n"
        y -= 22
    conteudo += (b"BT /F1 10 Tf 0.7 0 0 rg 60 60 Td (" + texto(
        "DOCUMENTO FICTÍCIO, gerado para testes do projeto de Banco de Dados.") + b") Tj ET\n")

    objetos = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] "
        b"/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>",
        b"<< /Length %d >>\nstream\n" % len(conteudo) + conteudo + b"endstream",
    ]
    pdf = b"%PDF-1.4\n"
    posicoes = []
    for i, obj in enumerate(objetos, start=1):
        posicoes.append(len(pdf))
        pdf += b"%d 0 obj\n" % i + obj + b"\nendobj\n"
    inicio_xref = len(pdf)
    pdf += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objetos) + 1)
    for p in posicoes:
        pdf += b"%010d 00000 n \n" % p
    pdf += (b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n"
            % (len(objetos) + 1, inicio_xref))
    return pdf


def popular_documentos():
    dao = DocumentoDAO()
    clientes = db.consultar("SELECT id_cliente, nome, cpf, endereco FROM cliente ORDER BY id_cliente")
    inseridos = 0
    for c in clientes:
        primeiro_nome = c["nome"].split()[0].lower()
        documentos = [
            ("RG", f"rg_{primeiro_nome}.pdf", "Registro Geral (RG)",
             [f"Nome: {c['nome']}", f"CPF: {c['cpf']}", "Órgão emissor: SSP/DF"]),
            ("Comprovante de residência", f"comprovante_residencia_{primeiro_nome}.pdf",
             "Comprovante de residência",
             [f"Titular: {c['nome']}", f"Endereço: {c['endereco'] or 'não informado'}",
              "Conta de energia elétrica, referência 10/2026"]),
        ]
        for tipo, nome_arquivo, titulo, linhas in documentos:
            ja_existe = db.consultar_um(
                "SELECT 1 FROM documento WHERE id_cliente = %s AND nome_arquivo = %s",
                (c["id_cliente"], nome_arquivo))
            if ja_existe:
                continue
            dao.inserir({"id_cliente": c["id_cliente"], "nome_arquivo": nome_arquivo,
                         "tipo": tipo, "arquivo": gerar_pdf(titulo, linhas)})
            inseridos += 1
    print(f"Documentos de clientes inseridos: {inseridos}")


def popular_certificados():
    dao = FuncionarioCertificacaoDAO()
    pendentes = db.consultar("""
        SELECT fc.id_funcionario, fc.id_certificacao, fc.data_obtencao, fc.data_validade,
               f.nome AS funcionario, c.nome AS certificacao, c.entidade_emissora
          FROM funcionario_certificacao fc
          JOIN funcionario f  ON f.id_funcionario = fc.id_funcionario
          JOIN certificacao c ON c.id_certificacao = fc.id_certificacao
         WHERE fc.pdf_certificado IS NULL""")
    for p in pendentes:
        pdf = gerar_pdf(f"Certificado {p['certificacao']}", [
            f"Certificamos que {p['funcionario']}",
            f"foi aprovado(a) no exame {p['certificacao']}.",
            f"Entidade emissora: {p['entidade_emissora'] or 'não informada'}",
            f"Data de obtenção: {p['data_obtencao']:%d/%m/%Y}",
            f"Válido até: {p['data_validade']:%d/%m/%Y}",
        ])
        dao.atualizar((p["id_funcionario"], p["id_certificacao"]), {"pdf_certificado": pdf})
    print(f"Certificados em PDF gravados: {len(pendentes)}")


if __name__ == "__main__":
    popular_documentos()
    popular_certificados()
    total = db.consultar_um("""
        SELECT (SELECT COUNT(*) FROM documento) AS documentos,
               (SELECT COUNT(*) FROM funcionario_certificacao
                 WHERE pdf_certificado IS NOT NULL) AS certificados""")
    print(f"No banco agora: {total['documentos']} documentos e "
          f"{total['certificados']} certificados com PDF.")
    db.fechar()