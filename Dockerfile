FROM debian:jessie

MAINTAINER Samuel, Yoeri, Tinie

COPY services.sh /services.sh
COPY template /template
COPY oc /usr/local/bin/oc

CMD /services.sh

