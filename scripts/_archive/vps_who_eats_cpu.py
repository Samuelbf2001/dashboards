"""Quien come CPU AHORA con load 11 — version rapida sin docker stats."""
import paramiko, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("72.60.67.214", username="root", password="Sixteam2026-", timeout=30)

CMD = r"""
echo '===[A] LOAD ahora ==='
uptime

echo
echo '===[B] TOP 20 procesos por CPU (snapshot) ==='
ps -eo pid,user,pcpu,pmem,etime,comm,args --sort=-pcpu | head -21

echo
echo '===[C] vmstat 1 3 ==='
vmstat 1 3

echo
echo '===[D] D-state / Zombies ==='
ps -eo pid,state,comm,args | awk '$2 ~ /^[ZD]/' | head -20

echo
echo '===[E] CONTENEDORES TOP CPU (sin docker stats, usando cgroup) ==='
for c in $(docker ps -q --no-trunc); do
  name=$(docker inspect --format '{{.Name}}' $c 2>/dev/null | sed 's:^/::')
  cpu_file="/sys/fs/cgroup/system.slice/docker-$c.scope/cpu.stat"
  if [ -f "$cpu_file" ]; then
    usage=$(grep '^usage_usec' "$cpu_file" | awk '{print $2}')
    echo "$usage $name"
  fi
done | sort -rn | head -10
"""

_, out, err = c.exec_command(CMD, timeout=90)
print(out.read().decode(errors='replace'))
e = err.read().decode(errors='replace')
if e.strip(): print('---STDERR---\n'+e, file=sys.stderr)
c.close()
