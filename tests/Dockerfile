FROM entando/app-builder:6.3.141
USER root
RUN id && cd /opt/app-root/src/app-builder/static/js && for f in $(ls *.js); do echo $f; sed -i -e "s/6\.3\.2/6.4.0/g" $f; done
ADD generate-cert.sh /opt/app-root/src/app-builder/static/js/
USER default