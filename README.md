# slopyphus

A browser terminal for a [pi](https://pi.dev) agent, and a desktop that composes many of them.

Two images:

| image | built from | what it is |
| --- | --- | --- |
| `initialed85/slopyphus` | `Dockerfile` | one agent: ubuntu, tmux, ttyd, pi, trzsz, docker-cli, uv, go, node, kubectl |
| `initialed85/slopyphus-nginx` | `Dockerfile.nginx` | the UI: nginx plus an entrypoint that renders its config from environment variables |

The name mismatch is real and left alone: the GitHub repo is `slophyphus`, the image tag is
`initialed85/slopyphus`.

# One agent

```sh
NAME=coder-7 MODEL=rooter/auto ./run-agent.sh   # http://localhost:7681/coder-7/
```

`NAME` is what everything is keyed on — the workspace directory (`/workspace/$NAME`), the tmux session,
the pi identity (`pi --name $NAME`), and ttyd's base path (`-b /$NAME`). It defaults to the container's
hostname, which is the agent name in compose and Docker, but a generated pod name in Kubernetes — so set
`NAME` explicitly in a pod spec and the pod name stops mattering.

`MODEL` is required (the entrypoint fails loudly rather than starting an agent with no model).

# The whole stack (compose)

```sh
docker compose up -d          # coordinator, coder-1..4, tester, deployer, and nginx on :80
```

`.env` holds the models (`COORDINATOR_MODEL`, `CODER_MODEL`). The `nginx` service builds
`Dockerfile.nginx` and takes its whole layout from `UI_COLUMNS` / `UI_ROWS` / `UI_LAYOUT` /
`UI_PAGE_TITLE`, which default to the desktop described below.

# Composing a desktop

The front renders `nginx.conf` and `index.html` at container start from these variables:

| variable | default | meaning |
| --- | --- | --- |
| `COLUMNS` | empty | comma separated `name=url` pairs, one full-height column each |
| `ROWS` | empty | comma separated `name=url` pairs, one full-width band each |
| `LAYOUT` | `columns_left` | `columns_left` \| `columns_right` \| `rows_top` \| `rows_bottom` |
| `AGENT_PORT` | `7681` | the port a bare host is assumed to be a ttyd on |
| `PAGE_TITLE` | `slophyphus` | browser tab title |
| `RESOLVER` | auto | DNS server for upstream resolution; `off` to resolve at start instead |

At least one of `COLUMNS` / `ROWS` must be set; both may be. `LAYOUT` decides how the viewport is split
between the two groups, and each group splits its half equally among its panes — one pane or fifty both
work.

```
columns_left                     rows_top
┌────┬────┬────┬────────────┐    ┌──────────────────────┐
│ co │ te │ de │  coder-1   │    │      coder-1         │
│    │    │    ├────────────┤    ├──────────────────────┤
│    │    │    │  coder-2   │    │      coder-2         │
│    │    │    ├────────────┤    ├──────────────────────┤
│    │    │    │  coder-3   │    │      coder-3         │
│    │    │    ├────────────┤    ├──────────────────────┤
│    │    │    │  coder-4   │    │      coder-4         │
└────┴────┴────┴────────────┘    ├──────────┬───────────┤
                                 │   co     │    te     │
                                 └──────────┴───────────┘
```

## `name=url`

The name is what the UI calls the pane: the iframe path (`/name/`), the nginx location that proxies it,
and the label in the corner of the pane. The url is what it proxies to, and it can be written at as much
or as little detail as you like:

| written | upstream | upstream base path | notes |
| --- | --- | --- | --- |
| `coder-1` | `http://coder-1:7681` | `/coder-1` | a slopyphus container; ttyd serves itself under its own name |
| `alice=coder-1` | `http://coder-1:7681` | `/coder-1` | a pane called *alice* showing an agent called *coder-1* |
| `alice=http://coder-1:7681` | `http://coder-1:7681` | `/coder-1` | the same thing, spelled out |
| `alice=https://agent.dev.initialed85.cc/coder-1` | `https://agent.dev.initialed85.cc` | `/coder-1` | any origin |
| `google=https://www.google.com` | `https://www.google.com` | (its own root) | any origin, framed as-is |

So: **no scheme means a slopyphus agent** (port `$AGENT_PORT`, base path `/<host>/`), and **a scheme means
an arbitrary origin** served at whatever path the URL names. An upstream whose port is `$AGENT_PORT` is
treated as a slopyphus agent either way, so `http://coder-1:7681` and `coder-1` mean the same thing.

A pane name must be `[A-Za-z0-9._-]`, may not be `healthz` (reserved by the front's own probe), and may
not appear in both `COLUMNS` and `ROWS`. Anything else — a bad `LAYOUT`, an empty desktop, an unsupported
scheme — stops the container with a message naming what it rejected.

Non-agent origins are proxied rather than framed directly, so every pane is same-origin with the front
and the keyboard relay below works in it. nginx is given the upstream's `Host` header, its SNI name for
https, and `X-Frame-Options` / `Content-Security-Policy` are stripped on the way back. That makes a
refusing site display, not much else: many sites break when their assets, redirects and cookies are
arranged around a path prefix they never asked for. Treat non-agent panes as best effort.

## Resolution

Upstream names are resolved **per request** (`resolver` + a `proxy_pass` built from a variable), using
the DNS server in the container's `/etc/resolv.conf` — `127.0.0.11` on a compose network, kube-dns in the
cluster. That is what lets the front come up at all: a missing agent 502s its own pane, and every other
pane, `/healthz` and the page itself keep serving. Set `RESOLVER=<ip>` to point it somewhere else, or
`RESOLVER=off` to resolve every upstream when nginx starts (then one unresolvable name takes the whole
front down).

## Keyboard

| key | effect |
| --- | --- |
| pointer into a pane | that pane is the active one (green border) |
| `Alt+Shift+Enter` | expand the active pane to the whole viewport; again to put it back |
| `Alt+Shift+G` | broadcast: every keystroke goes to every pane at once (all panes turn red) |
| `Shift+Enter` in a pane | newline — translated to `Ctrl+J`, which is what pi accepts; ttyd/xterm eats `Shift+Enter` |

## Examples

```sh
# The stack in docker-compose.yaml, and what it defaults to
docker run -p 80:80 \
  -e COLUMNS='coordinator,tester,deployer' \
  -e ROWS='coder-1,coder-2,coder-3,coder-4' \
  -e LAYOUT=columns_left \
  initialed85/slopyphus-nginx

# One agent, full screen, nothing else
docker run -p 80:80 -e COLUMNS='coordinator' initialed85/slopyphus-nginx

# Agents from elsewhere, plus a couple of sites, rows across the top
docker run -p 80:80 \
  -e ROWS='coordinator=https://agent.dev.initialed85.cc/coordinator,grafana=https://grafana.prod.initialed85.cc' \
  -e COLUMNS='coder-1=https://agent.dev.initialed85.cc/coder-1,coder-2=https://agent.dev.initialed85.cc/coder-2' \
  -e LAYOUT=rows_top \
  -e PAGE_TITLE='ed desktop' \
  initialed85/slopyphus-nginx
```

In Kubernetes the front is an ordinary Deployment + Service in the same namespace as the agents; bare
names resolve to Services, and each agent Deployment sets `NAME` so its ttyd base path matches the pane
name. `GET /healthz` answers 200 from the front itself (no upstream involved), so a probe measures this
container rather than the desktop it fronts.

# Checks

The front's config is generated, so the check that matters is on the generator, not the image:

```sh
# render and validate a desktop without serving it
docker run --rm -e COLUMNS='a,b' -e ROWS='c' -e LAYOUT=rows_top \
  --entrypoint /docker-entrypoint.nginx.sh initialed85/slopyphus-nginx nginx -t

# look at what it rendered instead
docker run --rm -e COLUMNS='a,b' --entrypoint /docker-entrypoint.nginx.sh \
  initialed85/slopyphus-nginx sh -c 'cat /etc/nginx/conf.d/default.conf; echo; cat /usr/share/nginx/html/index.html'
```

`.woodpecker/ci.yaml` builds both images and then runs `docker-entrypoint.nginx.sh` against a real
`nginx:alpine` using the templates straight from the checkout, asserting the locations, rewrites, grid
CSS and pane count, running `nginx -t` on the result, and asserting that a bad `LAYOUT`, an empty desktop,
a duplicated pane name and a reserved pane name are all rejected.
