# Last Oasis: Ubuntu Linux / Docker based dedicated server

**WARNING:** This is pretty much a WIP Proof of Concept. Use at **your own risk!**.

This repo might help you to run dedicated servers for [Last Oasis](https://lastoasis.gg/) on Linux and/or with docker.\
You should bring basic knowledge of Linux CLI in order to utilize what we got here.

## Installation

Download this repository either via git:

```shell
git clone https://github.com/deradon/last-oasis-docker-dedicated-server
```

or via plain [download](https://github.com/Deradon/last-oasis-docker-dedicated-server/archive/refs/heads/main.zip).

## Usage

You might utilize this tool with a plain Linux (tested with Ubuntu 20.04), `docker` or `docker-compose`:

---

### Ubuntu

* Requirements: [Downloading SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD#Linux)

#### Configure

Copy the example config file and adjust it to your needs:

```shell
# Get repo (@see Installation)
cp config.example config
```

It should look close to:

<details>
  <summary>Example config</summary>

    # Get it from https://myrealm.lastoasis.gg/Settings ("Game server registration key")
    SERVER_CUSTOMER_KEY="XgZyB0HDYtv4JJ1tUUybXg"

    # Server name to use. Must be unique per server realm.
    SERVER_IDENTIFIER="Example Server"

    # How many slots the server should offer. (Default: "10")
    SERVER_SLOTS="25"

    # Eternal server ip to use.
    SERVER_IP_ADDRESS=233.252.0.98

    # Server port to use. Must be unique per server realm and IP.
    SERVER_PORT="62001"

    # Server query port to use. Must be unique per server realm and IP.
    SERVER_QUERY_PORT="27015"

    # Get it from https://myrealm.lastoasis.gg/Settings ("Self hosted game servers registration keys")
    SERVER_PROVIDER_KEY="6fSIs5nTwnhfjcaVlZ5BmA"

    # Steam user name to login with.
    STEAM_USER="FancyAlice"
</details>

#### Install

The Last Oasis dedicated server (Steam App ID `920720`) can be downloaded
anonymously — `STEAM_USER` defaults to `anonymous`, so no Steam account or
2FA is required.

If you need to use a personal Steam account (e.g. to pin a specific build),
set `STEAM_USER` and run `login` once interactively to provide the password
and 2FA code.

**IMPORTANT:** Whenever an unknown tool asks you for your password, check the source! Fight scamming and phishing!

```shell
./last-oasis install
```

#### Run

```shell
./last-oasis run
```

#### Backup

Create a tarball of the save data (`Mist/Saved/`) under `$INSTALL_DIR/backups`:

```shell
./last-oasis backup
```

Override the destination via the `BACKUP_DIR` env var.

#### Help

```shell
./last-oasis help
```

---

### Docker

* Requirements: [Get Docker](https://docs.docker.com/get-docker/)

#### Configure

Copy the example config file and adjust it to your needs:

```shell
# Get repo (@see Installation)
cp config.example config
```

It should look close to:

<details>
  <summary>Example config</summary>

    # Get it from https://myrealm.lastoasis.gg/Settings ("Game server registration key")
    SERVER_CUSTOMER_KEY="XgZyB0HDYtv4JJ1tUUybXg"

    # Server name to use. Must be unique per server realm.
    SERVER_IDENTIFIER="Example Server"

    # How many slots the server should offer. (Default: "10")
    SERVER_SLOTS="25"

    # Eternal server ip to use.
    SERVER_IP_ADDRESS=233.252.0.98

    # Server port to use. Must be unique per server realm and IP.
    SERVER_PORT="62001"

    # Server query port to use. Must be unique per server realm and IP.
    SERVER_QUERY_PORT="27015"

    # Get it from https://myrealm.lastoasis.gg/Settings ("Self hosted game servers registration keys")
    SERVER_PROVIDER_KEY="6fSIs5nTwnhfjcaVlZ5BmA"

    # Steam user name to login with.
    STEAM_USER="FancyAlice"
</details>

#### Install

The Last Oasis dedicated server (Steam App ID `920720`) can be downloaded
anonymously — `STEAM_USER` defaults to `anonymous`, so no Steam account or
2FA is required.

If you need to use a personal Steam account (e.g. to pin a specific build),
set `STEAM_USER` and run `login` once interactively to provide the password
and 2FA code.

**IMPORTANT:** Whenever an unknown tool asks you for your password, check the source! Fight scamming and phishing!

```shell
./last-oasis-docker install
```

#### Run

```shell
./last-oasis-docker run
```

#### Logs

Tail the latest entries from `Mist.log` inside the volume:

```shell
./last-oasis-docker logs
```

#### Backup

Create a tarball of the save data into `./backups` on the host:

```shell
./last-oasis-docker backup
```

Override the destination via the `HOST_BACKUP_DIR` env var.

#### Help

```shell
./last-oasis-docker help
```

#### Pre-built image

A pre-built image is available on GitHub Container Registry — pull a
released version instead of building locally:

```shell
docker pull ghcr.io/drsaluml/last-oasis-docker-dedicated-server:latest
```

Tags follow [SemVer](https://semver.org/) (e.g. `1.2.3`, `1.2`, `latest`).

---

### Docker Compose

**WARNING** Experimental!

* Requirements: [Install Docker Compose](https://docs.docker.com/compose/install/)

#### Configure

Two templates ship with the repo — pick whichever matches your host:

| Template | Use when |
|---|---|
| [`docker-compose.yml.single-server`](docker-compose.yml.single-server) | Running a **single map** on a small box (~4 vCPU / 6 GB RAM). Pre-tuned to 25 slots with CPU and memory caps. |
| [`docker-compose.yml.example`](docker-compose.yml.example) | Running **multiple maps** or you want to start from a multi-server skeleton. |

Copy the chosen template to `docker-compose.yml` and edit the placeholders:

```shell
# Single-server (small host)
cp docker-compose.yml.single-server docker-compose.yml

# Multi-server (custom layout)
cp docker-compose.yml.example docker-compose.yml
```

**NOTE** Do NOT copy `config.example` to `config` here — it would overwrite the per-service `environment:` block on each `compose run`.

It should look close to:

<details>
  <summary>Example config</summary>

    version: '3.8'

    x-service-template: &service-template
      build: .
      restart: always
      command: run
      volumes:
        - "last-oasis-volume:/mnt/steam/"

    x-environment-template: &environment-template
      SERVER_CUSTOMER_KEY: XgZyB0HDYtv4JJ1tUUybXg
      SERVER_PROVIDER_KEY: 6fSIs5nTwnhfjcaVlZ5BmA
      SERVER_IP_ADDRESS: 233.252.0.98
      SERVER_SLOTS: 25
      STEAM_USER: FancyAlice

    services:
      # @note Don't remove this service. The `maintenance` service is used
      #       for installing and updating.
      maintenance:
        <<: *service-template
        restart: never
        command: help
        environment:
          <<: *environment-template


      server-01:
        <<: *service-template
        ports:
          - "62001:62001"
          - "62001:62001/udp"
          - "62101:62101"
          - "62101:62101/udp"
        environment:
          <<: *environment-template
          SERVER_IDENTIFIER: server-01
          SERVER_PORT: 62001
          SERVER_QUERY_PORT: 62101

      server-02:
        <<: *service-template
        ports:
          - "62002:62002"
          - "62002:62002/udp"
          - "62102:62102"
          - "62102:62102/udp"
        environment:
          <<: *environment-template
          SERVER_IDENTIFIER: server-02
          SERVER_PORT: 62002
          SERVER_QUERY_PORT: 62102

      server-03:
        <<: *service-template
        ports:
          - "62003:62003"
          - "62003:62003/udp"
          - "62103:62103"
          - "62103:62103/udp"
        environment:
          <<: *environment-template
          SERVER_IDENTIFIER: server-03
          SERVER_PORT: 62003
          SERVER_QUERY_PORT: 62103

    volumes:
      last-oasis-volume:
</details>

##### Single-server quick start (small host)

For a host sized around **4 vCPU / 6 GB RAM / 60 GB SSD / 400 Mbps**:

```shell
cp docker-compose.yml.single-server docker-compose.yml
```

Then open `docker-compose.yml` and replace every `<REPLACE_*>` placeholder:

| Placeholder | Where to get it |
|---|---|
| `<REPLACE_CUSTOMER_KEY>` | myrealm.lastoasis.gg → Settings → "Game server registration key" |
| `<REPLACE_PROVIDER_KEY>` | myrealm.lastoasis.gg → Settings → "Self hosted game servers registration keys" |
| `<REPLACE_EXTERNAL_IP>` | Public IPv4 of your host |
| `<REPLACE_SERVER_NAME>` | Anything unique within the realm (e.g. `oasis-01`) |

The dedicated server downloads anonymously, so no Steam credentials are
required — `STEAM_USER` defaults to `anonymous`.

The template is pre-tuned to:

- `SERVER_SLOTS: 25` (raise to 30–35 once stable)
- `cpus: 3.0` (leaves 1 core for the host OS)
- `mem_limit: 4g` / `mem_reservation: 2g` (leaves ~2 GB for the host)
- Ports: `62001/tcp+udp` (game) and `27015/tcp+udp` (Steam query)

Make sure those ports are open on your firewall / router.

#### Install

The Last Oasis dedicated server (Steam App ID `920720`) can be downloaded
anonymously — `STEAM_USER` defaults to `anonymous`, so no Steam account or
2FA is required.

If you need to use a personal Steam account (e.g. to pin a specific build),
set `STEAM_USER` and run `login` once interactively to provide the password
and 2FA code.

**IMPORTANT:** Whenever an unknown tool asks you for your password, check the source! Fight scamming and phishing!

```shell
./last-oasis-compose login
./last-oasis-compose install
```

#### Start all servers

```shell
./last-oasis-compose up
```

#### Update

```shell
./last-oasis-compose update
```

#### Stop all servers

```shell
./last-oasis-compose down
```

#### Logs

Tail combined logs from all services:

```shell
./last-oasis-compose logs
```

#### Backup

Create a tarball of the save data via the `maintenance` service:

```shell
./last-oasis-compose backup
```

#### Help

```shell
./last-oasis-compose help
```

---

## Docker image releases

The Docker image is built and published to GitHub Container Registry by
[`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml)
**only when a SemVer tag is pushed** (`v1.2.3`).

To cut a new release:

```shell
git tag v1.2.3
git push origin v1.2.3
```

The workflow will build and push three tags:

- `ghcr.io/drsaluml/last-oasis-docker-dedicated-server:1.2.3`
- `ghcr.io/drsaluml/last-oasis-docker-dedicated-server:1.2`
- `ghcr.io/drsaluml/last-oasis-docker-dedicated-server:latest`

The workflow can also be triggered manually via *Actions → Build and
publish Docker image → Run workflow*.

## Healthcheck

The Docker image ships with a Steam A2S query healthcheck that pings
the configured `SERVER_QUERY_PORT`. Containers running the `run`
command will be marked **unhealthy** if the server hangs but keeps the
process alive — pair this with `restart: always` (already set in the
compose template) so Docker will recycle a stuck server.

---

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/deradon/last-oasis-docker-dedicated-server.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Foo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/deradon/last-oasis-docker-dedicated-server/blob/master/CODE_OF_CONDUCT.md).

## Disclaimer

> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.
