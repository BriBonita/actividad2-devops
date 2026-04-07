#!/bin/bash
# deploy.sh - Script de orquestación CI/CD (DevOps)
# Uso: ./deploy.sh <accion_ec2> <instance_id> <directorio> <bucket>
# Ejemplo: ./deploy.sh iniciar i-xxxxxxxxxxxxxxxxx ./data mi-bucket-devops

set -euo pipefail

# ─── Configuración ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/deploy.log"
CONFIG_FILE="$SCRIPT_DIR/config/config.env"

# ─── Funciones ────────────────────────────────────────────────────────────────
log() {
    local nivel="$1"
    local mensaje="$2"
    local entrada="[$(date '+%Y-%m-%d %H:%M:%S')] [$nivel] $mensaje"
    echo "$entrada"
    echo "$entrada" >> "$LOG_FILE"
}

mostrar_ayuda() {
    echo ""
    echo "Uso: ./deploy.sh <accion_ec2> <instance_id> <directorio> <bucket>"
    echo ""
    echo "  accion_ec2   Acción sobre EC2: listar | iniciar | detener | terminar"
    echo "  instance_id  ID de la instancia EC2 (ej: i-xxxxxxxxxxxxxxxxx)"
    echo "  directorio   Directorio local a respaldar en S3"
    echo "  bucket       Nombre del bucket S3 de destino"
    echo ""
    echo "Ejemplos:"
    echo "  ./deploy.sh iniciar i-xxxxxxxxxxxxxxxxx ./data mi-bucket-devops"
    echo "  ./deploy.sh detener i-xxxxxxxxxxxxxxxxx ./data mi-bucket-devops"
    echo ""
}

validar_parametros() {
    if [[ $# -lt 4 ]]; then
        echo "ERROR: Se requieren 4 parámetros."
        mostrar_ayuda
        exit 1
    fi
}

cargar_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "INFO" "Cargando configuración desde $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    else
        log "WARN" "Archivo de configuración no encontrado: $CONFIG_FILE"
        log "WARN" "Se usarán los parámetros pasados por línea de comandos."
    fi
}

validar_dependencias() {
    log "INFO" "Validando dependencias del sistema..."

    if ! command -v python3 &>/dev/null; then
        log "ERROR" "python3 no está instalado o no está en el PATH."
        exit 1
    fi

    if ! python3 -c "import boto3" &>/dev/null; then
        log "ERROR" "La librería boto3 no está instalada. Ejecute: pip3 install boto3"
        exit 1
    fi

    if ! command -v aws &>/dev/null; then
        log "ERROR" "AWS CLI no está instalado o no está en el PATH."
        exit 1
    fi

    log "INFO" "Dependencias validadas correctamente."
}

ejecutar_ec2() {
    local accion="$1"
    local instance_id="$2"

    log "INFO" "────────────────────────────────────────"
    log "INFO" "Ejecutando acción EC2: $accion $instance_id"

    if [[ "$accion" == "listar" ]]; then
        python3 "$SCRIPT_DIR/ec2/gestionar_ec2.py" listar
    else
        python3 "$SCRIPT_DIR/ec2/gestionar_ec2.py" "$accion" "$instance_id"
    fi

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log "ERROR" "Falló la operación EC2 ($accion). Código de salida: $exit_code"
        exit $exit_code
    fi

    log "INFO" "Operación EC2 completada exitosamente."
}

ejecutar_backup() {
    local directorio="$1"
    local bucket="$2"

    log "INFO" "────────────────────────────────────────"
    log "INFO" "Ejecutando backup S3: $directorio → $bucket"

    bash "$SCRIPT_DIR/s3/backup_s3.sh" "$directorio" "$bucket"

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log "ERROR" "Falló el backup S3. Código de salida: $exit_code"
        exit $exit_code
    fi

    log "INFO" "Backup S3 completado exitosamente."
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    validar_parametros "$@"

    local accion_ec2="$1"
    local instance_id="$2"
    local directorio="$3"
    local bucket="$4"

    # Crear directorio de logs si no existe
    mkdir -p "$LOG_DIR"

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Iniciando flujo de despliegue DevOps"
    log "INFO" "Acción EC2: $accion_ec2 | Instancia: $instance_id"
    log "INFO" "Directorio: $directorio  | Bucket: $bucket"

    cargar_config
    validar_dependencias
    ejecutar_ec2 "$accion_ec2" "$instance_id"
    ejecutar_backup "$directorio" "$bucket"

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Flujo de despliegue completado exitosamente."
    log "INFO" "Revise los logs en: $LOG_FILE"
}

main "$@"
