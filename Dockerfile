FROM registry.access.redhat.com/ubi9 AS ubi-micro-build

ENV KEYCLOAK_VERSION=26.1.3_4.1.2
ARG KEYCLOAK_DIST=keycloak*.tar.gz

ADD $KEYCLOAK_DIST /tmp/keycloak/

RUN mv /tmp/keycloak/keycloak_olvid* /opt/keycloak && mkdir -p /opt/keycloak/data
RUN chmod -R g+rwX /opt/keycloak

ADD ubi-null.sh /tmp/
RUN bash /tmp/ubi-null.sh java-21-openjdk-headless glibc-langpack-en findutils

FROM registry.access.redhat.com/ubi9-micro
ENV LANG=en_US.UTF-8

ENV KC_RUN_IN_CONTAINER=true

COPY --from=ubi-micro-build /tmp/null/rootfs/ /
COPY --from=ubi-micro-build --chown=1000:0 /opt/keycloak /opt/keycloak

RUN echo "keycloak:x:0:root" >> /etc/group && \
    echo "keycloak:x:1000:0:keycloak user:/opt/keycloak:/sbin/nologin" >> /etc/passwd

USER 1000

EXPOSE 8080

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres

RUN /opt/keycloak/bin/kc.sh build

ENTRYPOINT [ "/opt/keycloak/bin/kc.sh" ]