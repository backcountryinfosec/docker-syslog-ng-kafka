# docker-syslog-ng-kafka

A Docker image for [syslog-ng](https://github.com/syslog-ng/syslog-ng), built from source with the Kafka (`kafka-c`) module enabled.
I ran into problems with most other builds out there, so this one compiles syslog-ng myself on Ubuntu 24.04.

Enabled modules include:

- **kafka**: `kafka-c()` destination (librdkafka)
- **mqtt**: `mqtt()` source and destination (Eclipse Paho)
- **http**: `http()` destination
- **json**: `format-json` / `json-parser`
- TLS for `network()` / `syslog()` (OpenSSL)

Java, Python, MongoDB, AMQP, Riemann and SQL modules are disabled to keep the build simple and the image small.

## Build

```sh
docker build --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') -t syslog-ng-kafka:4.12.0 .
```

The default syslog-ng version is 4.12.0. To build a different release, pass `--build-arg SYSLOG_VERSION=<version>`.

## Run

```sh
docker run -d --name syslog-ng \
  -p 514:514/udp -p 514:514/tcp -p 601:601/tcp \
  -v ./syslog-ng.conf:/etc/syslog-ng/syslog-ng.conf \
  -v ./logs:/mnt/logs \
  syslog-ng-kafka:4.12.0
```

| Path | Purpose |
| --- | --- |
| `/etc/syslog-ng/syslog-ng.conf` | Main configuration (an example is baked in) |
| `/etc/syslog-ng/conf.d/*.conf` | Extra config snippets, included automatically |
| `/mnt/logs` | Where the example config writes log files |

| Port | Protocol |
| --- | --- |
| 514/udp | BSD syslog over UDP |
| 514/tcp | BSD syslog over TCP |
| 601/tcp | RFC 5424 syslog over TCP |

## Configuration

The included [`syslog-ng.conf`](syslog-ng.conf) receives syslog on the ports above and writes it to `/mnt/logs/<host>_<program>.log`.
It also has commented-out examples for a Kafka destination and an MQTT source. Mount your own config over it for real use, and keep credentials out of the image.

To check a config before deploying it:

```sh
docker run --rm -v ./syslog-ng.conf:/etc/syslog-ng/syslog-ng.conf \
  --entrypoint /usr/sbin/syslog-ng syslog-ng-kafka:4.12.0 --syntax-only
```

> On Windows Git Bash, set `MSYS_NO_PATHCONV=1` so paths like `/usr/sbin/syslog-ng` are not rewritten.

## References

- [syslog-ng documentation](https://syslog-ng.github.io/)
- [Kafka destination with template support](https://www.syslog-ng.com/community/b/blog/posts/kafka-destination-improved-with-template-support-in-syslog-ng)
