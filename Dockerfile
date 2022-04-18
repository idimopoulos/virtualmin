FROM ubuntu:xenial

RUN sed -i 's#exit 101#exit 0#' /usr/sbin/policy-rc.d
RUN rm  /etc/apt/apt.conf.d/docker-gzip-indexes \
    &&  apt-get -o Acquire::GzipIndexes=false update -y \
    &&  apt-get upgrade -y

# Fixes issue with running systemD inside docker builds
# From https://github.com/gdraheim/docker-systemctl-replacement
COPY systemctl.py /usr/bin/systemctl.py
RUN chmod +x /usr/bin/systemctl.py \
    && cp -f /usr/bin/systemctl.py /usr/bin/systemctl

RUN DEBIAN_FRONTEND=noninteractive apt-get -y -f install wget perl apt-utils opendkim
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -f install curl screen bind9 bind9-host dnsutils dovecot-common dovecot-imapd
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -f install dovecot-pop3d postfix procmail postgrey spamassassin clamav
# Removed "shorewall".
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -f install openssh-server fail2ban ruby apache2 mysql-server-5.7 quota
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -f install libcrypt-ssleay-perl unzip zip rsyslog python-software-properties
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -f install software-properties-common language-pack-en
RUN apt-get -y -f install php php-pear php-fpm php-cgi php-cli php-common php-curl php-enchant php-gd php-imap php-intl php-ldap php-mcrypt php-readline php-pspell php-tidy php-xmlrpc php-xsl php-json php-sqlite3 php-mysql php-mysqli php-opcache php-bz2 webalizer apache2-suexec-custom libapache2-mod-php

RUN DEBIAN_FRONTEND=noninteractive wget http://www.webmin.com/jcameron-key.asc -qO - | apt-key add - \
    && echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list \
	&& wget http://software2.virtualmin.com/lib/RPM-GPG-KEY-virtualmin-6 -qO - | apt-key add - \
    && echo "deb http://software.virtualmin.com/vm/6/gpl/apt virtualmin-xenial main" >> /etc/apt/sources.list \
    && echo "deb http://software.virtualmin.com/vm/6/gpl/apt virtualmin-universal main" >> /etc/apt/sources.list \
    && wget -q http://download.webmin.com/download/virtualmin/webmin-virtual-server-theme_9.3_all.deb \
    && wget -q http://download.webmin.com/download/virtualmin/webmin-virtual-server_6.01.gpl_all.deb \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y -f install webmin usermin jailkit proftpd \
    && dpkg -i webmin-virtual-server_6.01.gpl_all.deb \
    && apt-get install -f \
    && dpkg -i webmin-virtual-server-theme_9.3_all.deb \
    && apt-get install -f \
    && apt-get dist-upgrade -y \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm webmin-virtual-server_6.01.gpl_all.deb \
    && rm webmin-virtual-server-theme_9.3_all.deb \
    && rm -rf /var/lib/apt/lists/*

COPY postfix.main.cf /etc/postfix/main.cf
COPY postfix.master.cf /etc/postfix/master.cf
COPY shorewall.zones /etc/shorewall/zones
COPY shorewall.interfaces /etc/shorewall/interfaces
COPY shorewall.policy /etc/shorewall/policy
COPY shorewall.rules /etc/shorewall/rules

RUN apt-get update
RUN chmod +x /etc/init.d/dovecot \
    && chmod 6711 /usr/bin/procmail \
    && chown root:root /usr/bin/procmail \
    && chown -R postfix:postdrop /var/spool/postfix \
    && touch /etc/postfix/dependent.db /var/log/auth.log /var/log/fail2ban.log \
    && echo "/bin/false" >> /etc/shells \
    && sed -i 's#/var/www#/home#' /etc/apache2/suexec/www-data \
    && sed -i "s@#Port 22@Port 2122@" /etc/ssh/sshd_config \
    && sed -i 's/SetHandler/#SetHandler/' /etc/apache2/mods-available/php7.0.conf

# Removed "shorewall.service".
RUN systemctl enable rsyslog.service sshd.service mysql.service fail2ban.service dovecot.service cron.service bind9.service opendkim.service postfix.service apache2.service postgrey.service proftpd.service usermin.service webmin.service
RUN echo "root:virtualmin" | chpasswd



EXPOSE 80 443 21 25 110 143 465 587 993 995 2122 10000 20000 53/udp 53/tcp

# ENTRYPOINT ["/usr/bin/systemctl","default","--init"]
ENTRYPOINT ["tail", "-f", "/dev/null"]

