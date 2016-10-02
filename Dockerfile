FROM debian:jessie

MAINTAINER Samuel, Yoeri, Tinie

COPY services.sh /services.sh
COPY template /template
#COPY oc /usr/local/bin/oc
#RUN curl -sSL https://github.com/openshift/origin/releases/download/v1.3.0/openshift-origin-client-tools-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit.tar.gz |tar -C /usr/local/bin/ -xzv --strip-components=1 */oc
ADD https://github.com/openshift/origin/releases/download/v1.3.0/openshift-origin-client-tools-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit.tar.gz /tmp/oc.tar.gz
RUN tar -C /usr/local/bin/ -xzvf /tmp/oc.tar.gz --strip-components=1 *oc

CMD /services.sh

