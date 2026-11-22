"""
Hash de senhas com PBKDF2 (biblioteca padrão do Python).
"""
import hashlib
import hmac
import secrets

ITERACOES = 120_000


def gerar_hash(senha: str) -> str:
    """Gera o hash de uma senha (com um sal aleatório) para guardar no banco."""
    sal = secrets.token_bytes(16)
    dk = hashlib.pbkdf2_hmac("sha256", senha.encode("utf-8"), sal, ITERACOES)
    return f"pbkdf2_sha256${ITERACOES}${sal.hex()}${dk.hex()}"


def conferir_senha(senha: str, guardado: str) -> bool:
    """Confere se a senha digitada corresponde ao hash guardado no banco."""
    try:
        algoritmo, iteracoes, sal_hex, hash_hex = guardado.split("$")
        if algoritmo != "pbkdf2_sha256":
            return False
        dk = hashlib.pbkdf2_hmac("sha256", senha.encode("utf-8"),
                                 bytes.fromhex(sal_hex), int(iteracoes))
        return hmac.compare_digest(dk.hex(), hash_hex)
    except (ValueError, AttributeError):
        return False