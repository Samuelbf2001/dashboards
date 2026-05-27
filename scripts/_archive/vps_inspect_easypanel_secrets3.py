"""READ-ONLY: inspeccionar la LMDB de EasyPanel (con strings) y los logs
del up reciente para extraer la encryption key real que EasyPanel inyecto.

Tambien: buscar la key 663a1244 (la del volumen persistido) en TODO el FS
con timeout, para confirmar si esa key esta tambien en el panel.
"""
import paramiko
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

DIAG = r"""
set +e

echo '===[1] STRINGS en LMDB de EasyPanel buscando keys conocidas ==='
# Sacamos strings ASCII de data.mdb y filtramos por patrones
strings -n 12 /etc/easypanel/data/data.mdb 2>/dev/null | grep -E 'N8N_ENCRYPTION_KEY|MB_DB_PASS|DB_POSTGRESDB_PASSWORD|663a1244|postgres_dashboard' | head -n 40

echo
echo '===[2] STRINGS en data.sdb ==='
strings -n 12 /etc/easypanel/data/data.sdb 2>/dev/null | grep -E 'N8N_ENCRYPTION_KEY|MB_DB_PASS|DB_POSTGRESDB_PASSWORD|663a1244|postgres_dashboard|metabase_user' | head -n 40

echo
echo '===[3] STRINGS LARGOS (50+) en data.mdb (buscar JSON con env) ==='
strings -n 50 /etc/easypanel/data/data.mdb 2>/dev/null | grep -iE 'postgres_dashboard|N8N_ENCRYPTION' | head -n 20

echo
echo '===[4] STRINGS LARGOS (50+) en data.sdb ==='
strings -n 50 /etc/easypanel/data/data.sdb 2>/dev/null | grep -iE 'postgres_dashboard|N8N_ENCRYPTION|MB_DB|encryptionKey' | head -n 40

echo
echo '===[5] JSON COMPLETO DE POSTGRES_DASHBOARD EN LMDB (chunk de 8KB conteniendo el stack) ==='
# Sacamos strings de hasta 4000 chars conteniendo "postgres_dashboard"
strings -n 30 /etc/easypanel/data/data.mdb 2>/dev/null | grep -F 'postgres_dashboard' | head -n 5
echo '---'
strings -n 30 /etc/easypanel/data/data.sdb 2>/dev/null | grep -F 'postgres_dashboard' | head -n 5

echo
echo '===[6] JOURNALCTL: easypanel.service (NO docker.service), ultimas 100 lineas ==='
journalctl -u easypanel.service -n 120 --no-pager 2>&1 | tail -n 120

echo
echo '===[7] LISTAR todos los systemd services con "easypanel" o "panel" en el nombre ==='
systemctl list-units --type=service --all 2>&1 | grep -iE 'panel' | head -n 20

echo
echo '===[8] Contenedor de EasyPanel (env, donde guarda credenciales) ==='
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' | grep -iE 'easypanel'

echo
echo '===[9] Logs del contenedor easypanel (ultimas 50 lineas, si existe) ==='
EPC=$(docker ps -a --format '{{.Names}}' | grep -iE 'easypanel' | head -n1)
if [ -n "$EPC" ]; then
  echo "--- contenedor: $EPC ---"
  docker logs --tail 50 "$EPC" 2>&1
fi

echo
echo '===[10] Buscar "663a1244" en LMDB ==='
strings -n 10 /etc/easypanel/data/data.mdb /etc/easypanel/data/data.sdb 2>/dev/null | grep -F '663a1244' | head -n 5

echo
echo '===[11] DOCKER PS -A todos los stacks (resumido) ==='
docker ps -a --format 'table {{.Names}}\t{{.Status}}' 2>&1 | head -n 50
"""


def main() -> int:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(HOST, username=USER, password=PASS, timeout=20)
    except Exception as e:
        print(f"[ERROR] conexion SSH fallo: {e}", file=sys.stderr)
        return 1

    try:
        _, out, err = client.exec_command(DIAG, timeout=90)
        stdout = out.read().decode(errors="replace")
        stderr = err.read().decode(errors="replace")
        print(stdout)
        if stderr.strip():
            print("---[STDERR]---", file=sys.stderr)
            print(stderr, file=sys.stderr)
    finally:
        client.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
