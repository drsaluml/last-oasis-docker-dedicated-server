# Kubernetes manifests

Production-ready manifests for running Last Oasis dedicated servers on
Kubernetes. Each server is a single-replica `Deployment` pinned to one
node via a node label, using `hostNetwork` so the game ports are
served directly from the node's IP.

## Files

| File | Purpose |
|---|---|
| [`namespace.yaml`](namespace.yaml) | Creates the `last-oasis` namespace |
| [`secret.yaml.example`](secret.yaml.example) | Per-server credentials template |
| [`last-oasis.yaml`](last-oasis.yaml) | PVC + Deployment for one server |
| [`install-job.yaml`](install-job.yaml) | One-shot Job to download the game files |
| [`backup-cronjob.yaml`](backup-cronjob.yaml) | Daily save-data backup |

## First-time setup

```shell
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Label the node that will host the realm's IP
kubectl label node <your-node-name> oasis=last-oasis-1

# 3. Create the secret
cp secret.yaml.example secret-last-oasis-1.yaml
# edit secret-last-oasis-1.yaml — fill every <REPLACE_*>
kubectl apply -f secret-last-oasis-1.yaml

# 4. Create the PVC + Deployment
kubectl apply -f last-oasis.yaml

# 5. Run the install Job (downloads ~10–15 GB into the PVC)
kubectl apply -f install-job.yaml
kubectl -n last-oasis logs -f job/last-oasis-1-install

# 6. Once the Job finishes successfully, restart the deployment so
#    the server picks up the freshly-installed files
kubectl -n last-oasis rollout restart deployment/last-oasis-1

# 7. (Optional) Schedule daily backups
kubectl apply -f backup-cronjob.yaml
```

## Day-to-day operations

```shell
# Health
kubectl -n last-oasis get pods
kubectl -n last-oasis describe pod -l app=last-oasis-1

# Logs
kubectl -n last-oasis logs -f deploy/last-oasis-1

# Tail Mist.log inside the container
kubectl -n last-oasis exec deploy/last-oasis-1 -- \
  tail -f /mnt/steam/.steam/last-oasis/Mist/Saved/Logs/Mist.log

# Open a shell
kubectl -n last-oasis exec -it deploy/last-oasis-1 -- bash

# Manual backup (without waiting for CronJob)
kubectl -n last-oasis create job --from=cronjob/last-oasis-1-backup \
  last-oasis-1-backup-manual-$(date +%s)
```

## Updating game files

The `install` Job is idempotent — running it on an existing volume
just validates and downloads any changed files.

```shell
# Stop the server
kubectl -n last-oasis scale deploy/last-oasis-1 --replicas=0

# Re-run install (downloads only the diff)
kubectl -n last-oasis delete job last-oasis-1-install --ignore-not-found
kubectl apply -f install-job.yaml
kubectl -n last-oasis wait --for=condition=complete job/last-oasis-1-install --timeout=30m

# Start back up
kubectl -n last-oasis scale deploy/last-oasis-1 --replicas=1
```

## Running multiple servers

Each server is a copy-and-rename of `last-oasis.yaml`,
`secret.yaml.example`, `install-job.yaml`, and `backup-cronjob.yaml`:

```shell
# Substitute the suffix on a fresh copy
sed 's/last-oasis-1/last-oasis-2/g' last-oasis.yaml > last-oasis-2.yaml
sed 's/last-oasis-1/last-oasis-2/g' install-job.yaml > install-job-2.yaml
sed 's/last-oasis-1/last-oasis-2/g' backup-cronjob.yaml > backup-cronjob-2.yaml
```

Each new server needs:

- A unique `SERVER_IDENTIFIER` and `SERVER_PORT` / `SERVER_QUERY_PORT`
  in its Secret
- A node labeled `oasis=last-oasis-2`
- Its own PVC (created from the renamed `last-oasis-2.yaml`)

## Troubleshooting

### `Pod stuck Pending` — no node matches the selector

Make sure exactly one node has the `oasis=last-oasis-N` label:
```shell
kubectl get nodes -L oasis
```

### `Failed to install app '920720' (Missing configuration)`

A transient steamcmd quirk. The install Job already retries with
backoff (`DOWNLOAD_MAX_ATTEMPTS=10`); if it still fails after all
retries, just re-apply the Job — Steam's CMS license cache eventually
warms up.

### `Redirecting stderr to '/nonexistent/Steam/logs/stderr.txt'`

Image was built with `HOME` defaulted to `/nonexistent`. The manifests
already set `HOME=/home/steam` as a fallback; if you see this with a
freshly pulled image, your `imagePullPolicy: Always` is working but
the registry has a stale build — push a new tag.

### Pod restarts every few minutes despite the server running

Liveness probe failing because `SERVER_QUERY_PORT` mismatch between
the Secret and what the server actually binds. Make sure the Secret's
`SERVER_QUERY_PORT` matches the value passed via `-QueryPort` (the
healthcheck script reads `$SERVER_QUERY_PORT`).
