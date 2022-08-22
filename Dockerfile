FROM almalinux:8.6

RUN yum install yum-utils wget procps -y && \
    yum-config-manager --save --setopt=skip_missing_names_on_install=0 && \
    yum update -y curl && \
    yum -y update-minimal --setopt=tsflags=nodocs --security --sec-severity=Important --sec-severity=Critical && \
    dnf --enablerepo=* clean all && dnf update -y && \
    yum remove -y vim-minimal platform-python-pip.noarch && \
    yum update -y expat libxml2 libgcrypt && \
    yum clean all

ARG BOOTSTRAP_LICENSE
ARG RELEASE_CHANNEL
ARG CLIENT_VERSION
ARG SERVER_VERSION
ARG STUDIO_VERSION
ARG TOOLBOX_VERSION

RUN yum-config-manager --add-repo https://release.memsql.com/${RELEASE_CHANNEL}/rpm/x86_64/repodata/memsql.repo && \
    yum install -y singlestore-client-${CLIENT_VERSION} singlestoredb-server${SERVER_VERSION} singlestoredb-studio-${STUDIO_VERSION} singlestoredb-toolbox-${TOOLBOX_VERSION} && \
    yum clean all

ENV JQ_VERSION='1.6'
RUN wget --no-check-certificate https://raw.githubusercontent.com/stedolan/jq/master/sig/jq-release.key -O /tmp/jq-release.key && \
    wget --no-check-certificate https://raw.githubusercontent.com/stedolan/jq/master/sig/v${JQ_VERSION}/jq-linux64.asc -O /tmp/jq-linux64.asc && \
    wget --no-check-certificate https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 -O /tmp/jq-linux64 && \
    gpg --import /tmp/jq-release.key && \
    gpg --verify /tmp/jq-linux64.asc /tmp/jq-linux64 && \
    cp /tmp/jq-linux64 /usr/bin/jq && \
    chmod +x /usr/bin/jq && \
    rm -f /tmp/jq-release.key && \
    rm -f /tmp/jq-linux64.asc && \
    rm -f /tmp/jq-linux64

RUN mkdir -p /data && chown -R memsql:memsql /data

ADD studio.hcl /var/lib/singlestoredb-studio/studio.hcl
RUN chown memsql:memsql /var/lib/singlestoredb-studio/studio.hcl

USER memsql

ADD init.sh /tmp/init.sh
RUN /tmp/init.sh

ADD start.sh /start.sh
CMD ["/start.sh"]

EXPOSE 3306/tcp
EXPOSE 8080/tcp
EXPOSE 9000/tcp