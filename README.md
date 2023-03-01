# docker-syslog-ng-kafka
Required files to support my build of syslog-ng with the kafka module enabled. 
I ran into issues with most other builds out there. This one was working when I had been using it in 2022.

# Build command
```docker build --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg SYSLOG_VERSION=3.37.1 -t syslog-ng-kafka:3.37.1 .```
