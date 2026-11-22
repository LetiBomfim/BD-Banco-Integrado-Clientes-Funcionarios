import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _ler_env(caminho):
    valores = {}
    if os.path.exists(caminho):
        with open(caminho, encoding="utf-8") as arquivo:
            for linha in arquivo:
                linha = linha.strip()
                if linha and not linha.startswith("#") and "=" in linha:
                    chave, valor = linha.split("=", 1)
                    valores[chave.strip()] = valor.strip()
    return valores


_env = _ler_env(os.path.join(RAIZ, ".env"))


def obter(chave, padrao=None):
    return os.environ.get(chave, _env.get(chave, padrao))


DB = {
    "host": obter("DB_HOST", "localhost"),
    "port": int(obter("DB_PORT", "5432")),
    "dbname": obter("DB_NAME", "banco_integrado"),
    "user": obter("DB_USER", "postgres"),
    "password": obter("DB_PASSWORD", ""),
}