FROM gradle:7.4.1-jdk17-alpine AS build

WORKDIR /data
COPY . /data

RUN apk upgrade --update && apk add --update curl unzip && \
  curl -O https://download.newrelic.com/newrelic/java-agent/newrelic-agent/current/newrelic-java.zip && \
  unzip -q newrelic-java.zip

RUN gradle assemble --no-daemon



FROM eclipse-temurin:17-jre-alpine

LABEL maintainer='ArcoTech'

ARG WITH_NEW_RELIC=true
ENV WITH_NEW_RELIC=$WITH_NEW_RELIC
ENV NEW_RELIC_LICENSE_KEY=$NEWRELIC_KEY
ENV NEW_RELIC_LOG_FILE_NAME="STDOUT"

RUN addgroup -S kotlin && \
  adduser -S kotlin -G kotlin
COPY --chown=kotlin:kotlin --from=build /data/newrelic/newrelic.jar /opt/app/newrelic/newrelic.jar
COPY --chown=kotlin:kotlin --from=build /data/newrelic/newrelic.yml /opt/app/newrelic/newrelic.yml
COPY --chown=kotlin:kotlin --from=build /data/application/build/libs/application-0.0.1-SNAPSHOT.jar /opt/app/app.jar

USER kotlin
EXPOSE 9011

CMD ["java", "-XX:MaxRAMPercentage=75", "-javaagent:/opt/app/newrelic/newrelic.jar", "-jar", "/opt/app/app.jar"]
