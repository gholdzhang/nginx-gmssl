# nginx-gmssl

## 镜像说明

ngxin目录在`/usr/local/nginx`,公开的volumes:

- /usr/local/nginx/html : nginx默认的html文件目录
- /usr/local/nginx/conf : nginx配置文件目录
- /certs : 存放证书的目录

### 部署示例

docker-compose.yml

```yaml
version: "3"
services:
  nginx-gmssl:
    container_name: nginx-gmssl
    image: nginx-gmssl:1.18.0
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    ports:
      - 10001:80
      - 10002:443
    volumes:
      # 证书目录
      - ./certs:/certs
      # nginx配置文件
      - ./nginx.conf:/usr/local/nginx/conf/nginx.conf
```

nginx.conf

```conf
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;
    # HTTP
    server {
        listen       80;
        listen       [::]:80;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
    # HTTPS
    server {
       listen       443 ssl;
       server_name  localhost;
       # 证书
       ssl_certificate      /certs/user.crt;
       ssl_certificate_key  /certs/user.key;

       ssl_session_cache    shared:SSL:1m;
       ssl_session_timeout  5m;

       ssl_ciphers  HIGH:!aNULL:!MD5;
       ssl_prefer_server_ciphers  on;

       location / {
           root   html;
           index  index.html index.htm;
       }
    }

}
```

## 用gmssl命令生成sm2证书

生成SM2私钥及证书请求

```sh
gmssl ecparam -genkey -name sm2p256v1 -text -out user.key
gmssl req -new -key user.key -out user.req
```

用私钥对csr进行自签名

```sh
gmssl x509 -req -days 36500 -sm3 -in user.req -signkey user.key -out user.crt
```

生成的证书即可应用于上方.

### 证书转换

- crt转cer

```sh
gmssl x509 -inform pem -in user.crt -outform der -out user.cer
```

- PKCS 转成crt

```sh
openssl pkcs12 -in cacert.p12 -out mycerts.crt -nokeys -clcerts
```

- PEM转成PKCS12

```sh
openssl pkcs12 -export -out cacert.p12 -in cacert.pem
```

- 查看证书内容

**pet\crt格式(begin..end格式base64):**

```sh
gmssl x509 -in user.crt -text -noout
```

**der\cer(hex)格式:**

```sh
gmssl x509 -in user.cer -inform der -text -noout
```

参考: [那些证书相关的玩意儿(SSL,X.509,PEM,DER,CRT,CER,KEY,CSR,P12等)](https://www.cnblogs.com/guogangj/p/4118605.html)
