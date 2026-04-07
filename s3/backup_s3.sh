#!/bin/bash
# backup_s3.sh - Script de respaldo de archivos hacia S3
# Uso: bash s3/backup_s3.sh <directorio> <bucket>
# Ejemplo: bash s3/backup_s3.sh ./data mi-bucket-devops

set -euo pipefail

# ─── Configuración ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/backup.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ─── Funciones ────────────────────────────────────────────────────────────────
log() {
    local nivel="$1"
    local mensaje="$2"
    local entrada="[$(date '+%Y-%m-%d %H:%M:%S')] [$nivel] $mensaje"
    echo "$entrada"
    echo "$entrada" >> "$LOG_FILE"
}

mostrar_ayuda() {
    echo "Uso: bash backup_s3.sh <directorio> <bucket>"
    echo ""
    echo "  directorio  Ruta local del directorio a respaldar"
    echo "  bucket      Nombre del bucket S3 de destino"
    echo ""
    echo "Ejemplo: bash s3/backup_s3.sh ./data mi-bucket-devops"
}

validar_parametros() {
    if [[ $# -lt 2 ]]; then
        echo "ERROR: Se requieren 2 parámetros."
        mostrar_ayuda
        exit 1
    fi
}

validar_directorio() {
    local directorio="$1"
    if [[ ! -d "$directorio" ]]; then
        log "ERROR" "El directorio '$directorio' no existe."
        exit 1
    fi
    if [[ -z "$(ls -A "$directorio")" ]]; then
        log "WARN" "El directorio '$directorio' está vacío. No hay nada que respaldar."
        exit 0
    fi
}

comprimir_archivos() {
    local directorio="$1"
    local nombre_archivo="backup_${TIMESTAMP}.tar.gz"
    local ruta_archivo="/tmp/$nombre_archivo"

    log "INFO" "Comprimiendo directorio '$directorio' → $ruta_archivo"
    tar -czf "$ruta_archivo" -C "$(dirname "$directorio")" "$(basename "$directorio")"

    if [[ $? -ne 0 ]]; then
        log "ERROR" "Fallo al comprimir el directorio."
        exit 1
    fi

    log "INFO" "Compresión exitosa: $ruta_archivo"
    echo "$ruta_archivo"
}

subir_a_s3() {
    local archivo="$1"
    local bucket="$2"
    local nombre_objeto="backups/$(basename "$archivo")"

    log "INFO" "Subiendo $archivo → s3://$bucket/$nombre_objeto"
    aws s3 cp "$archivo" "s3://$bucket/$nombre_objeto"

    if [[ $? -ne 0 ]]; then
        log "ERROR" "Fallo al subir el archivo a S3."
        rm -f "$archivo"
        exit 1
    fi

    log "INFO" "Subida exitosa: s3://$bucket/$nombre_objeto"
}

limpiar_temporal() {
    local archivo="$1"
    log "INFO" "Eliminando archivo temporal: $archivo"
    rm -f "$archivo"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    validar_parametros "$@"

    local directorio="$1"
    local bucket="$2"

    # Crear directorio de logs si no existe
    mkdir -p "$LOG_DIR"

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Inicio del proceso de backup"
    log "INFO" "Directorio: $directorio | Bucket: $bucket"

    validar_directorio "$directorio"

    local archivo_comprimido
    archivo_comprimido=$(comprimir_archivos "$directorio")

    subir_a_s3 "$archivo_comprimido" "$bucket"

    limpiar_temporal "$archivo_comprimido"

    log "INFO" "Proceso de backup completado exitosamente."
    log "INFO" "════════════════════════════════════════"
}

main "$@"
