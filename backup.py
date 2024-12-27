import os
import shutil
from datetime import datetime, timedelta

# ----------------------------------------------
# Configuração geral
# ----------------------------------------------
TARGET_DIR = "/home/valcann/backupsFrom"  # Diretório de origem dos arquivos
BACKUP_DIR = "/home/valcann/backupsTo"   # Diretório de destino para backup
LOG_FROM = "/home/valcann/backupsFrom.log"  # Log de origem
LOG_TO = "/home/valcann/backupsTo.log"      # Log de destino
DELETE_AFTER_DAYS = 3  # Número de dias para considerar um arquivo "antigo" e excluí-lo

# ----------------------------------------------
# Funções auxiliares
# ----------------------------------------------

def format_date(date_string):
    """Formata uma data no padrão YYYY-MM-DD HH:MM:SS"""
    return datetime.strptime(date_string, "%Y-%m-%d %H:%M:%S")

def check_directories():
    """Verifica a existência dos diretórios necessários"""
    if not os.path.isdir(TARGET_DIR) or not os.path.isdir(BACKUP_DIR):
        raise FileNotFoundError("Erro: Um ou mais diretórios não existem. Verifique as configurações.")

def log_file_info(log_file, file_name, file_size, creation_date, modification_date):
    """Registra informações de um arquivo no log"""
    log_file.write(f"{file_name:<30} {file_size:<15} {creation_date:<25} {modification_date:<25}\n")

def calculate_diff_days(modification_date):
    """Calcula a diferença de dias entre a data atual e a data de última modificação"""
    return (datetime.now() - modification_date).days

# ----------------------------------------------
# Início do processamento
# ----------------------------------------------

def main():
    check_directories()

    # Inicializar log de origem
    with open(LOG_FROM, 'w') as log_from:
        log_from.write(f"Arquivos no diretório {TARGET_DIR} em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}:\n")
        log_from.write("-------------------------------------------------\n")
        log_from.write(f"{'Nome do Arquivo':<30} {'Tamanho (bytes)':<15} {'Data de Criação':<25} {'Última Modificação':<25}\n")
        log_from.write("-------------------------------------------------\n")

    # Inicializar log de destino
    with open(LOG_TO, 'w') as log_to:
        log_to.write(f"Arquivos copiados para {BACKUP_DIR} em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}:\n")
        log_to.write("-------------------------------------------------\n")
        log_to.write(f"{'Nome do Arquivo':<30} {'Tamanho (bytes)':<15} {'Última Modificação':<25} {'Status':<30}\n")
        log_to.write("-------------------------------------------------\n")

    # Processar cada arquivo no diretório de origem
    for file in os.listdir(TARGET_DIR):
        file_path = os.path.join(TARGET_DIR, file)
        if os.path.isfile(file_path):
            file_stat = os.stat(file_path)
            file_size = file_stat.st_size
            modification_date = datetime.fromtimestamp(file_stat.st_mtime)
            creation_date = datetime.fromtimestamp(file_stat.st_ctime)

            # Registrar no log de origem
            with open(LOG_FROM, 'a') as log_from:
                log_file_info(log_from, file, file_size, creation_date.strftime('%Y-%m-%d %H:%M:%S'), modification_date.strftime('%Y-%m-%d %H:%M:%S'))

            # Calcular diferença de dias
            diff_days = calculate_diff_days(modification_date)

            # Ações baseadas na idade do arquivo
            if diff_days <= DELETE_AFTER_DAYS:
                shutil.copy(file_path, BACKUP_DIR)
                with open(LOG_TO, 'a') as log_to:
                    log_to.write(f"{file:<30} {file_size:<15} {modification_date.strftime('%Y-%m-%d %H:%M:%S'):<25} {'Arquivo copiado':<30}\n")
            else:
                os.remove(file_path)
                with open(LOG_FROM, 'a') as log_from:
                    log_from.write(f"Deletando arquivo: {file} devido à idade maior que {DELETE_AFTER_DAYS} dias\n")

    # Finalizar logs
    with open(LOG_FROM, 'a') as log_from:
        log_from.write("-------------------------------------------------\n")
        log_from.write(f"Operação concluída em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    with open(LOG_TO, 'a') as log_to:
        log_to.write("-------------------------------------------------\n")
        log_to.write(f"Cópia concluída em {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    # Mensagem final
    print("Operação concluída. Logs disponíveis em:")
    print(f" - {LOG_FROM}")
    print(f" - {LOG_TO}")

if __name__ == "__main__":
    main()
