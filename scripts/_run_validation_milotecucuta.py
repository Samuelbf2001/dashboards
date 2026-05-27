"""
Ejecuta scripts/validate_attribution_milotecucuta.sql sobre la BD ghl_analytics
del VPS (via docker exec al contenedor postgres). Solo SELECT.
"""
import paramiko
import os
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

HOST = '72.60.67.214'
USER = 'root'
PWD  = 'Sixteam2026-'

SQL_FILE_LOCAL = os.path.join(os.path.dirname(__file__), 'validate_attribution_milotecucuta.sql')
SQL_FILE_VPS   = '/tmp/validate_attribution_milotecucuta.sql'


def main():
    if not os.path.exists(SQL_FILE_LOCAL):
        sys.exit(f'No existe {SQL_FILE_LOCAL}')

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(HOST, username=USER, password=PWD, timeout=20)

    def run(cmd, label='', timeout=60):
        print(f'\n=== {label or cmd[:70]} ===')
        _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
        out = stdout.read().decode('utf-8', errors='replace')
        err = stderr.read().decode('utf-8', errors='replace')
        if out:
            print(out)
        if err:
            print('[stderr]', err)
        return out, err

    # 1. Descubrir el contenedor postgres (filtrado: imagen postgres + nombre dashboard)
    out, _ = run("docker ps --format '{{.Names}}\t{{.Image}}'", "containers running")
    container = None
    for line in out.splitlines():
        parts = line.split('\t')
        if len(parts) < 2:
            continue
        name, image = parts[0].strip(), parts[1].strip()
        if 'dashboard-postgres' in name and 'postgres' in image:
            container = name
            break
    if not container:
        sys.exit('No encontre contenedor postgres_dashboard-postgres-*')
    print(f'[OK] container = {container}')

    # 2. Descubrir DB y user desde env del contenedor
    out, _ = run(f"docker exec {container} env | grep -E '^POSTGRES_(USER|DB|PASSWORD)='",
                 'env del contenedor postgres')
    env = {}
    for line in out.splitlines():
        if '=' in line:
            k, v = line.split('=', 1)
            env[k.strip()] = v.strip()
    pg_user = env.get('POSTGRES_USER', 'postgres')
    pg_db   = env.get('POSTGRES_DB', 'ghl_analytics')
    pg_pwd  = env.get('POSTGRES_PASSWORD', '')
    print(f'[OK] user={pg_user}  db={pg_db}  pwd={"<set>" if pg_pwd else "<empty>"}')

    # 3. Subir el SQL al VPS
    sftp = client.open_sftp()
    sftp.put(SQL_FILE_LOCAL, SQL_FILE_VPS)
    sftp.close()
    print(f'[OK] subido {SQL_FILE_LOCAL} -> {SQL_FILE_VPS}')

    # 4. Copiar dentro del contenedor y ejecutar
    run(f"docker cp {SQL_FILE_VPS} {container}:/tmp/v.sql", 'cp al contenedor')

    cmd = (
        f"docker exec -e PGPASSWORD='{pg_pwd}' {container} "
        f"psql -U {pg_user} -d {pg_db} -v ON_ERROR_STOP=1 -P pager=off -f /tmp/v.sql"
    )
    run(cmd, 'ejecutando validacion', timeout=120)

    client.close()


if __name__ == '__main__':
    main()
