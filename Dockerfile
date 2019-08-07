FROM openjdk:8u171-jdk-stretch as builder

MAINTAINER andrey.dyachkov@gmail.com

WORKDIR /tmp
RUN apt-get update && apt-get install -y curl wget jq tar
RUN wget -O nakadi.tar.gz "https://codeload.github.com/zalando/nakadi/tar.gz/r3.2.4-2019-08-01"
RUN tar -xvf nakadi.tar.gz --strip-components=1
RUN wget -O nakadi-authz-file-plugin-0.1.jar https://github.com/adyach/nakadi-authz-file-plugin/releases/download/v0.1/nakadi-authz-file-plugin-0.1.jar
RUN cp nakadi-authz-file-plugin-0.1.jar plugins/nakadi-authz-file-plugin-0.1.jar
RUN chmod u+x gradlew
RUN ./gradlew assemble

FROM openjdk:8u171-jdk-alpine3.7

# configure Nakadi
COPY --from=builder /tmp/build/libs/nakadi.jar .
COPY --from=builder /tmp/api/nakadi-event-bus-api.yaml ./api/nakadi-event-bus-api.yaml

# file based authz config
COPY --from=builder /tmp/plugins/nakadi-authz-file-plugin-0.1.jar ./plugins/nakadi-authz-file-plugin-0.1.jar
COPY ./data/authz.json /data/authz.json
ENV NAKADI_AUTHZ_FILE_PLUGIN_AUTHZ_FILE=/data/authz.json

EXPOSE 8080
ENTRYPOINT exec java -Dloader.path=plugins -Djava.security.egd=file:/dev/./urandom -jar nakadi.jar

