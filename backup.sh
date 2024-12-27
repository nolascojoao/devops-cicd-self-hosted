#!/bin/bash

# ----------------------------------------------
# Configuração geral
# ----------------------------------------------
TARGET_DIR="/home/valcann/backupsFrom"  # Diretório de origem dos arquivos
BACKUP_DIR="/home/valcann/backupsTo"   # Diretório de destino para backup
LOG_FROM="/home/valcann/backupsFrom.log"  # Log de origem
LOG_TO="/home/valcann/backupsTo.log"      # Log de destino
DELETE_AFTER_DAYS=3  # Número de dias para considerar um arquivo "antigo" e excluí-lo
export TZ="America/Sao_Paulo"  # Configura o fuso horário para "America/Sao_Paulo" (GMT-3)

# ----------------------------------------------
# Funções auxiliares
# ----------------------------------------------

# Formata data
format_date() {
    date -d "$1" "+%Y-%m-%d %H:%M:%S"
}

# Verifica a existência dos diretórios necessários
check_directories() {
    if [ ! -d "$TARGET_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
        echo "Erro: Um ou mais diretórios não existem. Verifique as configurações."
        exit 1
    fi
}

# Registra informações de um arquivo no log de origem
log_file_info() {
    local file_name=$1
    local file_size=$2
    local creation_date=$3
    local modification_date=$4

    printf "%-30s %-15s %-25s %-25s\n" "$file_name" "$file_size" "$creation_date" "$modification_date" >> "$LOG_FROM"
}

# Registra informações detalhadas no log de destino
log_file_copied() {
    local file_name=$1
    local file_size=$2
    local modification_date=$3

    printf "%-30s %-15s %-25s %-30s\n" "$file_name" "$file_size" "$modification_date" "Arquivo copiado" >> "$LOG_TO"
}

# Calcula a diferença de dias entre a data atual e a data de última modificação
calculate_diff_days() {
    local modification_date=$1
    local current_date=$2
    local modification_timestamp=$(date -d "$modification_date" +%s)
    local current_timestamp=$(date -d "$current_date" +%s)
    echo $(( (current_timestamp - modification_timestamp) / 86400 ))
}

# ----------------------------------------------
# Início do processamento
# ----------------------------------------------

# Verificar os diretórios
check_directories

# Inicializar log de origem
{
    echo "Arquivos no diretório $TARGET_DIR em $(date "+%Y-%m-%d %H:%M:%S"):"
    echo "-------------------------------------------------"
    printf "%-30s %-15s %-25s %-25s\n" "Nome do Arquivo" "Tamanho (bytes)" "Data de Criação" "Última Modificação"
    echo "-------------------------------------------------"
} > "$LOG_FROM"

# Inicializar log de destino
{
    echo "Arquivos copiados para $BACKUP_DIR em $(date "+%Y-%m-%d %H:%M:%S"):"
    echo "-------------------------------------------------"
    printf "%-30s %-15s %-25s %-30s\n" "Nome do Arquivo" "Tamanho (bytes)" "Última Modificação" "Status"
    echo "-------------------------------------------------"
} > "$LOG_TO"

# Processar cada arquivo no diretório de origem
for file in "$TARGET_DIR"/*; do
    if [ -f "$file" ]; then
        FILE_NAME=$(basename "$file")
        FILE_SIZE=$(stat --format="%s" "$file")
        MODIFICATION_DATE=$(stat --format="%y" "$file")  
        CREATION_DATE=$(stat --format="%w" "$file")  

        # Formatar datas no padrão YYYY/MM/DD
        CREATION_DATE=$(format_date "$CREATION_DATE")
        MODIFICATION_DATE=$(format_date "$MODIFICATION_DATE")
		
		# Registrar no log de origem
        log_file_info "$FILE_NAME" "$FILE_SIZE" "$CREATION_DATE" "$MODIFICATION_DATE"

        # Calcular diferença de dias
        CURRENT_DATE=$(date "+%Y-%m-%d")
        DIFF_DAYS=$(calculate_diff_days "$MODIFICATION_DATE" "$CURRENT_DATE")

        # Ações baseadas na idade do arquivo
        if [ "$DIFF_DAYS" -le "$DELETE_AFTER_DAYS" ]; then
            cp "$file" "$BACKUP_DIR/"
            log_file_copied "$FILE_NAME" "$FILE_SIZE" "$MODIFICATION_DATE"
        else
            rm -f "$file"
            echo "Deletando arquivo: $FILE_NAME devido à idade maior que $DELETE_AFTER_DAYS dias" >> "$LOG_FROM"
        fi
    fi
done

# Finalizar logs
{
    echo "-------------------------------------------------"
    echo "Operação concluída em $(date "+%Y-%m-%d %H:%M:%S")"
} >> "$LOG_FROM"

{
    echo "-------------------------------------------------"
    echo "Cópia concluída em $(date "+%Y-%m-%d %H:%M:%S")"
} >> "$LOG_TO"

# Mensagem final
echo "Operação concluída. Logs disponíveis em:"
echo " - $LOG_FROM"
echo " - $LOG_TO"
