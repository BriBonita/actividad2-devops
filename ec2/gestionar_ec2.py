#!/usr/bin/env python3
"""
gestionar_ec2.py - Script para gestionar instancias EC2 en AWS
Uso:
    python3 gestionar_ec2.py listar
    python3 gestionar_ec2.py iniciar <instance_id>
    python3 gestionar_ec2.py detener <instance_id>
    python3 gestionar_ec2.py terminar <instance_id>
"""

import sys
import boto3
from botocore.exceptions import ClientError, NoCredentialsError


def obtener_cliente():
    """Crea y retorna un cliente de EC2."""
    try:
        cliente = boto3.client("ec2")
        return cliente
    except NoCredentialsError:
        print("ERROR: No se encontraron credenciales AWS configuradas.")
        print("Configure sus credenciales con: aws configure")
        sys.exit(1)


def listar_instancias(ec2):
    """Lista todas las instancias EC2 con su estado."""
    try:
        respuesta = ec2.describe_instances()
        instancias = []
        for reserva in respuesta["Reservations"]:
            for instancia in reserva["Instances"]:
                instancias.append(instancia)

        if not instancias:
            print("No se encontraron instancias EC2.")
            return

        print(f"\n{'ID':<22} {'Estado':<15} {'Tipo':<15} {'IP Pública':<18} {'Nombre'}")
        print("-" * 85)
        for inst in instancias:
            inst_id = inst["InstanceId"]
            estado = inst["State"]["Name"]
            tipo = inst["InstanceType"]
            ip_publica = inst.get("PublicIpAddress", "N/A")
            nombre = "N/A"
            for tag in inst.get("Tags", []):
                if tag["Key"] == "Name":
                    nombre = tag["Value"]
                    break
            print(f"{inst_id:<22} {estado:<15} {tipo:<15} {ip_publica:<18} {nombre}")
        print()
    except ClientError as e:
        print(f"ERROR al listar instancias: {e.response['Error']['Message']}")
        sys.exit(1)


def iniciar_instancia(ec2, instance_id):
    """Inicia una instancia EC2 dado su ID."""
    try:
        print(f"Iniciando instancia {instance_id}...")
        respuesta = ec2.start_instances(InstanceIds=[instance_id])
        estado_anterior = respuesta["StartingInstances"][0]["PreviousState"]["Name"]
        estado_actual = respuesta["StartingInstances"][0]["CurrentState"]["Name"]
        print(f"Instancia {instance_id}: {estado_anterior} → {estado_actual}")
    except ClientError as e:
        print(f"ERROR al iniciar instancia {instance_id}: {e.response['Error']['Message']}")
        sys.exit(1)


def detener_instancia(ec2, instance_id):
    """Detiene una instancia EC2 dado su ID."""
    try:
        print(f"Deteniendo instancia {instance_id}...")
        respuesta = ec2.stop_instances(InstanceIds=[instance_id])
        estado_anterior = respuesta["StoppingInstances"][0]["PreviousState"]["Name"]
        estado_actual = respuesta["StoppingInstances"][0]["CurrentState"]["Name"]
        print(f"Instancia {instance_id}: {estado_anterior} → {estado_actual}")
    except ClientError as e:
        print(f"ERROR al detener instancia {instance_id}: {e.response['Error']['Message']}")
        sys.exit(1)


def terminar_instancia(ec2, instance_id):
    """Termina (elimina) una instancia EC2 dado su ID."""
    try:
        confirmacion = input(
            f"¿Está seguro que desea TERMINAR la instancia {instance_id}? "
            "Esta acción es IRREVERSIBLE. (s/n): "
        )
        if confirmacion.lower() != "s":
            print("Operación cancelada.")
            return

        print(f"Terminando instancia {instance_id}...")
        respuesta = ec2.terminate_instances(InstanceIds=[instance_id])
        estado_anterior = respuesta["TerminatingInstances"][0]["PreviousState"]["Name"]
        estado_actual = respuesta["TerminatingInstances"][0]["CurrentState"]["Name"]
        print(f"Instancia {instance_id}: {estado_anterior} → {estado_actual}")
    except ClientError as e:
        print(f"ERROR al terminar instancia {instance_id}: {e.response['Error']['Message']}")
        sys.exit(1)


def mostrar_ayuda():
    """Muestra el mensaje de uso del script."""
    print(__doc__)


def main():
    acciones_validas = ("listar", "iniciar", "detener", "terminar")

    if len(sys.argv) < 2:
        print("ERROR: Se requiere una acción.")
        mostrar_ayuda()
        sys.exit(1)

    accion = sys.argv[1].lower()

    if accion not in acciones_validas:
        print(f"ERROR: Acción '{accion}' no reconocida.")
        print(f"Acciones válidas: {', '.join(acciones_validas)}")
        mostrar_ayuda()
        sys.exit(1)

    if accion != "listar" and len(sys.argv) < 3:
        print(f"ERROR: La acción '{accion}' requiere un instance_id.")
        print(f"Uso: python3 gestionar_ec2.py {accion} <instance_id>")
        sys.exit(1)

    ec2 = obtener_cliente()

    if accion == "listar":
        listar_instancias(ec2)
    elif accion == "iniciar":
        iniciar_instancia(ec2, sys.argv[2])
    elif accion == "detener":
        detener_instancia(ec2, sys.argv[2])
    elif accion == "terminar":
        terminar_instancia(ec2, sys.argv[2])


if __name__ == "__main__":
    main()
