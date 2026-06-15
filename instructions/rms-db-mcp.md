# rms-db MCP — Setup, Topology & Troubleshooting

## What it is

HTTP MCP server (`localhost:8056`) giving AI assistants direct MySQL access to AG1 and US2 RMS databases. Source: `/Users/toale/Developer/rms-db-mcp/`. Runs as a Docker container.

## Architecture

```
Claude Code → HTTP :8056 → rms-db-mcp (Docker)
                               └─ SSH tunnel → NOC jump host
                                                └─ ProxySQL → MySQL shards
```

- **AG1 jump host:** `qag1ge1lnoc300.va.main.ag1.axon.us:22`
- **US2 jump host:** `sus2uw1lnoc300.ca.main.us2.axon.io:22`
- SSH auth: password-only (FIPS mode — no key auth)
- Shards auto-discovered at startup by SSHing NOC and parsing `ps -aux | grep socat`

## Shard → ProxySQL port map (maintained by Tom Phan)

| Port | Shard |
|------|-------|
| 9307 | lmya  |
| 9308 | lmyi  |
| 9309 | lmyj  |
| 9310 | lmyn  |
| 9311 | lmyf  |
| 9312 | lmyo  |

`lmyi` uses integrations MySQL credentials, not the standard zeke user.

## Shards with 0 databases (expected, not broken)

These shards have working tunnels but no agencies assigned yet — ProxySQL drops arbitrary queries (e.g. `SELECT 1 on information_schema`) when no default schema exists. `list_databases` returns `dbs=0`, which is the correct health check:

- **AG1:** lmyo
- **US2:** lmyj, lmyn

## Credentials (`.env` file)

`/Users/toale/Developer/rms-db-mcp/.env`

| Variable | Source |
|----------|--------|
| `SSH_USER` | your Axon username |
| `SSH_PASSWORD_AG1` | AG1 VPN/AD password (IdentityNow) |
| `SSH_PASSWORD_US2` | US2 VPN/AD password (IdentityNow) |
| `RMS_MYSQL_PASSWORD_AG1` | from k8s: `kubectl get secret -n rms tools -o jsonpath='{.data.mysql\.password}' --context=az.ag1.main.va.rms \| base64 --decode` |
| `RMS_MYSQL_PASSWORD_US2` | same command with `--context=az.us2.main.ca.rms` |
| `INTEGRATIONS_MYSQL_PASSWORD_AG1` | `kubectl get secret -n rms tools -o jsonpath='{.data.mysql\.integrations\.password}' --context=az.ag1.main.va.rms \| base64 --decode` |
| `INTEGRATIONS_MYSQL_PASSWORD_US2` | same with `--context=az.us2.main.ca.rms` |

**Dollar signs in passwords must be escaped as `$$` in `.env`** (docker-compose treats `$x` as variable interpolation).

## Restart after credential changes

```bash
cd /Users/toale/Developer/rms-db-mcp && docker compose up -d --force-recreate
```

Wait for `docker inspect rms-db-mcp --format '{{.State.Health.Status}}'` → `healthy` before testing.

## Diagnosing connection failures

### Symptoms and causes

| Symptom | Cause |
|---------|-------|
| `connection_status` hangs indefinitely | Dead tunnels with `is_active=True` — `test_connection` has no timeout; serially blocks on each zombie shard |
| `list_databases` (no shard) times out | Fans out across all shards sequentially; zombie shards block it |
| `execute_sql` on specific shard times out | That shard's SSH tunnel is down |
| `Authentication failed` in logs | SSH password rotated — update `.env` and recreate container |
| `Access denied for user 'integrations'` | `INTEGRATIONS_MYSQL_PASSWORD_*` is wrong |
| `Lost connection to MySQL server` on empty shard | Normal — ProxySQL drops queries with no default schema |

### Verify tunnel health from inside container

```bash
docker exec rms-db-mcp python3 -c "
import socket, struct
def parse(line):
    f=line.strip().split()
    if len(f)<4: return None
    def dec(a):
        ih,ph=a.split(':')
        return socket.inet_ntoa(struct.pack('<I',int(ih,16)))+':'+str(int(ph,16))
    return dec(f[1]),dec(f[2]),f[3]
with open('/proc/net/tcp') as f: lines=f.readlines()[1:]
ssh=[p for p in [parse(l) for l in lines] if p and ':22'==p[1][-3:] and p[2]=='01']
print(f'SSH tunnels: {len(ssh)}')  # expect 14 (8 AG1 + 6 US2)
"
```

### Test a specific shard

```bash
curl -s --max-time 20 -X POST http://localhost:8056/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_databases","arguments":{"environment":"AG1","shard":"lmya"}}}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); r=json.loads(d['result']['content'][0]['text']); print('OK' if r['success'] else r.get('error'))"
```

Use `list_databases` (not `execute_sql` with `information_schema`) as the health check — works correctly on empty shards.

### k8s tools pod is NOT in the data path

The rms-db MCP connects SSH → NOC → ProxySQL. The in-cluster `tools` pod uses direct NLB hostnames (`lpsa-nlb.va.main.ag1.axon.us`) and is irrelevant to MCP connectivity. Don't waste time checking it for MCP issues.
