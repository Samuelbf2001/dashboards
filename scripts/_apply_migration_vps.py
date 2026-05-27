"""
Aplica un archivo .sql al contenedor postgres del VPS.
Uso:
  python _apply_migration_vps.py <ruta_local_al_sql>
"""
import paramiko
import os
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

HOST = '72.60.67.214'
USER = 'root'
PWD  = 'Sixteam2026-'


def main():
    if len(sys.argv) < 2:
        sys.exit('Uso: python _apply_migration_vps.py <ruta_local_al_sql>')
    sql_local = sys.argv[1]
    if not os.path.exists(sql_local):
        sys.exit(f'No existe {sql_local}')

    sql_basename = os.path.basename(sql_local)
    sql_vps      = f'/tmp/{sql_basename}'

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(HOST, username=USER, password=PWD, timeout=20)

    def run(cmd, label='', timeout=120):
        print(f'\n=== {label or cmd[:70]} ===')
        _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
        out = stdout.read().decode('utf-8', errors='replace')
        err = stderr.read().decode('utf-8', errors='replace')
        if out: print(out)
        if err: print('[stderr]', err)
        return out, err

    # 1. Container postgres
    out, _ = run("docker ps --format '{{.Names}}\t{{.Image}}'", 'containers')
    container = None
    for line in out.splitlines():
        parts = line.split('\t')
        if len(parts) >= 2 and 'dashboard-postgres' in parts[0] and 'postgres' in parts[1]:
            container = parts[0].strip()
            break
    if not container:
        sys.exit('No encontre contenedor postgres_dashboard-postgres-*')
    print(f'[OK] container = {container}')

    # 2. Env del contenedor
    out, _ = run(f"docker exec {container} env | grep -E '^POSTGRES_'", 'env')
    env = {}
    for line in out.splitlines():
        if '=' in line:
            k, v = line.split('=', 1)
            env[k.strip()] = v.strip()
    pg_user = env.get('POSTGRES_USER', 'postgres')
    pg_db   = env.get('POSTGRES_DB', 'ghl_analytics')
    pg_pwd  = env.get('POSTGRES_PASSWORD', '')

    # 3. Subir SQL
    sftp = client.open_sftp()
    sftp.put(sql_local, sql_vps)
    sftp.close()
    print(f'[OK] subido {sql_local} -> {sql_vps}')

    # 4. Copiar al contenedor y ejecutar
    run(f"docker cp {sql_vps} {container}:/tmp/m.sql", 'cp al contenedor')

    cmd = (
        f"docker exec -e PGPASSWORD='{pg_pwd}' {container} "
        f"psql -U {pg_user} -d {pg_db} -v ON_ERROR_STOP=1 -P pager=off "
        f"--single-transaction -f /tmp/m.sql"
    )
    out, err = run(cmd, 'aplicando migracion', timeout=180)

    # Reportar éxito
    ok = ('[stderr]' not in (err or '') or err.strip() == '') and ('ERROR' not in out.upper())
    print(f"\n{'[OK] migracion aplicada' if ok else '[FAIL] revisar errores'}")

    client.close()


if __name__ == '__main__':
    main()
