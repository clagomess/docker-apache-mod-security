FROM debian:10

RUN apt update
RUN apt install apache2 vim wget -y

# mod-security
RUN apt install libapache2-mod-security2 -y
RUN apachectl -M
RUN a2enmod security2
RUN mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf \
&& sed -i -- "s/SecRuleEngine DetectionOnly/SecRuleEngine On/g" /etc/modsecurity/modsecurity.conf
RUN echo "SecAction \"id:900000,phase:1,nolog,pass,t:none,setvar:tx.paranoia_level=4\"" >> /etc/modsecurity/crs/crs-setup.conf \
&& sed -i -- "s/crs_setup_version=310/crs_setup_version=330/g" /etc/modsecurity/crs/crs-setup.conf

# update
RUN cd /tmp \
&& wget https://github.com/coreruleset/coreruleset/archive/v3.3.0.tar.gz \
&& tar -xvf v3.3.0.tar.gz \
&& cp -R /tmp/coreruleset-3.3.0/rules/** /usr/share/modsecurity-crs/rules \
&& rm -rf /usr/share/modsecurity-crs/rules/**.example

# SSL
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/ssl-proxy-owasp.key \
-out /etc/ssl/certs/ssl-proxy-owasp.crt \
-subj "/C=BR/ST=Distrito Federal/L=Brasilia/O=Claudio/CN=localhost"

# proxy
RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2enmod ssl

# alterar o endereço para o desejado
RUN echo "<VirtualHost *:443>" > /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "ServerAdmin cla.gomess@gmail.com" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "ServerName localhost" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "SSLEngine on" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "SSLCertificateFile      /etc/ssl/certs/ssl-proxy-owasp.crt" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "SSLCertificateKeyFile /etc/ssl/private/ssl-proxy-owasp.key" >> /etc/apache2/conf-available/proxy-owasp.conf \

&& echo "SSLProxyEngine On" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "SSLProxyCheckPeerCN on" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "SSLProxyCheckPeerExpire on" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "ProxyPass \"/\"  \"http://192.168.0.41:3000/\"" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "ProxyPassReverse \"/\"  \"http://192.168.0.41:3000/\"" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "</VirtualHost>" >> /etc/apache2/conf-available/proxy-owasp.conf \

&& echo "<VirtualHost *:80>" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "SSLProxyEngine On" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "SSLProxyCheckPeerCN on" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "SSLProxyCheckPeerExpire on" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "ProxyPass \"/\"  \"http://192.168.0.41:3000/\"" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "ProxyPassReverse \"/\"  \"http://192.168.0.41:3000/\"" >> /etc/apache2/conf-available/proxy-owasp.conf \
&& echo "</VirtualHost>" >> /etc/apache2/conf-available/proxy-owasp.conf

RUN a2enconf proxy-owasp

# config log
RUN ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log \
&& ln -sf /dev/stderr /var/log/apache2/error.log
