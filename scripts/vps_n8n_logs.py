"""TAREA 1 — Diagnostico read-only de n8n restart loop.

Recolecta logs, exit code, restart count, OOM flag y nombres de env vars
del contenedor postgres_dashboard-n8n-1. NO toca el contenedor.
"""
import paramiko
import sys

HOST = "72.60.67.214"
USER = "root"
PASS = "Sixteam2026-"

DIAG = r"""
echo '===[1] DOCKER LOGS --tail 200 (stdout+stderr) ==='
docker logs postgres_dashboard-n8n-1 --tail 200 2>&1

echo
echo '===[2] STATE INSPECT (exit code / error / restart count / oom) ==='
docker inspect postgres_dashboard-n8n-1 --format '{{.State.ExitCode}} | {{.State.Error}} | restarts={{.RestartCount}} | OOM={{.State.OOMKilled}} | started={{.State.StartedAt}} | finished={{.State.FinishedAt}}'

echo
echo '===[3] STATE COMPLETO (json) ==='
docker inspect postgres_dashboard-n8n-1 --format '{{json .State}}'

echo
echo '===[4] NOMBRES DE ENV VARS (sin valores) ==='
docker inspect postgres_dashboard-n8n-1 --format '{{json .Config.Env}}' | python3 -c "import json,sys; data=json.load(sys.stdin); [print(e.split('=',1)[0]) for e in data]"

echo
echo '===[5] HEALTHCHECK / RESTART POLICY ==='
docker inspect postgres_dashboard-n8n-1 --format 'RestartPolicy={{.HostConfig.RestartPolicy.Name}} MaxRetry={{.HostConfig.RestartPolicy.MaximumRetryCount}} Healthcheck={{json .Config.Healthcheck}}'

echo
echo '===[6] EVENTS RECIENTES DE DOCKER PARA ESTE CONTENEDOR ==='
docker events --since 30m --until 0s --filter container=postgres_dashboard-n8n-1 2>/dev/null &
EVENTS_PID=$!
sleep 2
kill $EVENTS_PID 2>/dev/null
wait $EVENTS_PID 2>/dev/null

echo
echo '===[7] OTROS n8n EN LA VPS (referencia) ==='
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -i n8n
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
        _, out, err = client.exec_command(DIAG, timeout=120)
        print(out.read().decode(errors="replace"))
        e = err.read().decode(errors="replace")
        if e.strip():
            print("---[STDERR]---", file=sys.stderr)
            print(e, file=sys.stderr)
    finally:
        client.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
