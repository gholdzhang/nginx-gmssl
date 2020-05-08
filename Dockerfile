FROM centos:8
LABEL maintainer="NGINX-GMSSL Docker Maintainers <guog@live.cn>"
WORKDIR /usr/local/src/
ENV NGINX_VERSION nginx-1.18.0

RUN set -x \
  && groupadd --system --gid 101 nginx \
  && useradd --system --no-create-home --home-dir /nonexistent --shell /sbin/nologin --comment "nginx user" --gid nginx --uid 101 nginx
  # && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx

RUN yum update -y \
  && yum -y install epel-release wget gcc gcc-c++ glibc make autoconf \
  openssl openssl-devel pcre-devel libxslt-devel gd-devel unzip tar ca-certificates\
  && wget -O gmssl.zip https://github.com/guanzhi/GmSSL/archive/master.zip \
  && unzip -o gmssl.zip \
  && wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz \
  && tar -zxvf ./${NGINX_VERSION}.tar.gz \
  && cd GmSSL-master \
  && ./config --prefix=/usr/local/gmssl --openssldir=/usr/local/gmssl \
  && make && make install \
  && cd ../${NGINX_VERSION} \
  && sed -i 's/\/\.openssl\//\//g' auto/lib/openssl/conf \
  && ./configure --with-http_ssl_module --with-openssl=/usr/local/gmssl \
  && make && make install

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /usr/local/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/nginx/logs/error.log \
    && mkdir /certs

# make default server listen on ipv6
# 支持ipv4和ipv6
RUN sed -i -E 's,listen       80;,listen       80;\n        listen       [::]:80;,' \
        /usr/local/nginx/conf/nginx.conf

RUN sed -i -E 's,listen       80;,listen       80;\n        listen       [::]:80;,' \
        /usr/local/nginx/conf/nginx.conf.default

# WORKDIR /usr/local/src/${NGINX_VERSION}

WORKDIR /

VOLUME /usr/local/nginx/html
VOLUME /usr/local/nginx/conf
VOLUME /certs

ENV LD_LIBRARY_PATH /usr/local/gmssl/lib
ENV PATH /usr/local/nginx/sbin:/usr/local/gmssl/bin:$PATH

EXPOSE 80

STOPSIGNAL SIGTERM

ENTRYPOINT ["nginx"]

CMD ["-g","daemon off;"]