# project-devops

Automatización y Despliegue Controlado en AWS con Enfoque DevOps.

## Descripción del proyecto

Este proyecto implementa una solución de automatización en AWS que integra:
- Gestión de instancias EC2 mediante Python (Boto3)
- Respaldo de información en S3 mediante Bash
- Control de versiones con Git y GitHub
- Simulación de un flujo CI/CD mediante scripts

## Estructura del proyecto

```
project-devops/
│
├── ec2/
│   └── gestionar_ec2.py      # Script Python para gestionar instancias EC2
│
├── s3/
│   └── backup_s3.sh          # Script Bash para respaldo en S3
│
├── logs/                     # Directorio de logs generados automáticamente
│
├── config/
│   └── config.env            # Variables de entorno (sin credenciales)
│
├── deploy.sh                 # Script de orquestación CI/CD
└── README.md
```

## Requisitos previos

- AWS CLI configurado
- Python 3 con librería boto3 (`pip3 install boto3`)
- Git y GitHub CLI (`gh`)
- Instancia EC2 Linux en AWS Learner Lab

## Instrucciones de uso

### 1. Configurar el entorno

Editar `config/config.env` con los valores de tu entorno:

```bash
INSTANCE_ID=i-xxxxxxxxxxxxxxxxx
BUCKET_NAME=mi-bucket-devops
DIRECTORY=./data
REGION=us-east-1
```

### 2. Script EC2 (Python)

```bash
# Listar instancias EC2
python3 ec2/gestionar_ec2.py listar

# Iniciar una instancia
python3 ec2/gestionar_ec2.py iniciar i-xxxxxxxxxxxxxxxxx

# Detener una instancia
python3 ec2/gestionar_ec2.py detener i-xxxxxxxxxxxxxxxxx

# Terminar una instancia
python3 ec2/gestionar_ec2.py terminar i-xxxxxxxxxxxxxxxxx
```

### 3. Script de backup S3 (Bash)

```bash
bash s3/backup_s3.sh ./data mi-bucket-devops
```

### 4. Script de orquestación (deploy.sh)

```bash
# Sintaxis
./deploy.sh <accion_ec2> <instance_id> <directorio> <bucket>

# Ejemplo: iniciar instancia y hacer backup
./deploy.sh iniciar i-xxxxxxxxxxxxxxxxx ./data mi-bucket-devops
```

## Flujo Git

```
feature/* ──► develop ──► main
```

1. Crear rama de funcionalidad: `git checkout -b feature/nombre`
2. Desarrollar con commits progresivos
3. Push: `git push origin feature/nombre`
4. Merge a develop: `git merge feature/nombre`
5. Merge a main cuando esté estable

### Convención de commits

```
feat: descripción corta de la funcionalidad
fix: corrección de error
docs: cambios en documentación
```

## Logs

Los logs se generan automáticamente en `logs/deploy.log` y `logs/backup.log`.

---

## Reflexión

**¿Qué ventaja tienen los commits progresivos?**
Permiten rastrear el historial de cambios de forma granular, facilitan la detección y reversión de errores puntuales, y documentan el proceso de desarrollo paso a paso.

**¿Por qué evitar hardcoding?**
Los valores fijos en el código hacen los scripts no reutilizables, dificultan los cambios de entorno (dev/staging/prod) y representan un riesgo de seguridad si se incluyen datos sensibles.

**¿Qué rol cumple deploy.sh?**
Actúa como orquestador del flujo CI/CD: coordina la ejecución del script Python y Bash, valida errores en cada paso y genera logs centralizados del proceso completo.

**¿Qué ventaja tiene separar config del código?**
Permite cambiar parámetros de entorno sin modificar el código fuente, facilita la reutilización en distintos entornos y hace el repositorio seguro para compartir sin exponer configuraciones sensibles.
