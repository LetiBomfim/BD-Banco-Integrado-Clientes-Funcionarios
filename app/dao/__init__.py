"""Camada de persistência: todo o acesso ao banco passa por aqui."""
from .entidades import (CargoCertificacaoDAO, CargoDAO, CertificacaoDAO, ClienteDAO, ContaDAO,
                        DocumentoDAO, EmprestimoDAO, FuncionarioCertificacaoDAO, FuncionarioDAO,
                        FuncionarioTreinamentoDAO, TipoDeContaDAO, TransacaoDAO, TreinamentoDAO)
from .erros import traduzir

DAOS = [
    CargoDAO, CertificacaoDAO, CargoCertificacaoDAO, FuncionarioDAO,
    FuncionarioCertificacaoDAO, TreinamentoDAO, FuncionarioTreinamentoDAO,
    ClienteDAO, DocumentoDAO, TipoDeContaDAO, ContaDAO, TransacaoDAO, EmprestimoDAO,
]

__all__ = [classe.__name__ for classe in DAOS] + ["DAOS", "traduzir"]