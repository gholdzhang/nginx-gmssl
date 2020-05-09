# 构建过程参考文档

## 用gmssl命令生成sm2证书(已验证)

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

---

## 用gmssl制作国密SM2证书(未验证)

以下做出的证书都是：Signature Algorithm: sm2sign-with-sm3

创建demoCA目录，在demoCA目录下执行：

```sh
mkdir certs crl newcerts private

touch index.txt

echo "01" > serial
```

将通过以下自签名生成的cacert.pem放到demoCA目录下，cakey.pem放到demoCA/private

创建公私钥和证书请求：

```sh
gmssl ecparam -genkey -name sm2p256v1 -out cakey.pem

gmssl req -new -sm3 -key cakey.pem -out cacsr.pem
```

自签名

```sh
gmssl req -x509 -sm3 -days 3650 -key cakey.pem -in cacsr.pem -out cacert.pem
```

ca签名（在demoCA的父目录下执行）

```sh
gmssl ca -md sm3 -in client_csr.pem -out client_cert.pem -days 3650
```

显示证书信息：

```sh
gmssl x509 -text -noout -in cacert.pem

gmssl req -in cacsr.pem -noout -text
```

证书通信测试命令

SERVER:

```sh
gmssl s_server -key server_key.pem -cert server_cert.pem -CAfile cacert.pem -cipher ECDHE-SM4-SM3 -verify 1
```

CLIENT:

```sh
gmssl s_client -key client_key.pem -cert client_cert.pem -CAfile cacert.pem -cipher ECDHE-SM4-SM3 -verify 1
```

---

## 基于nginx镜像构建(失败)

```sh
# 从nginx构建容器 1.17.10
docker run --name nginx-gmssl -d -p 10001:80 -p 10002:443 nginx:latest
# 查看版本
cat /etc/os-release
# 更改源:添加163镜像源
echo "deb http://mirrors.163.com/debian/ stretch main non-free contrib" >> /etc/apt/sources.list.d/163.list \
&& echo "deb http://mirrors.163.com/debian/ stretch-updates main non-free contrib" >> /etc/apt/sources.list.d/163.list \
&& echo "deb http://mirrors.163.com/debian/ stretch-backports main non-free contrib" >> /etc/apt/sources.list.d/163.list \
&& echo "deb-src http://mirrors.163.com/debian/ stretch main non-free contrib" >> /etc/apt/sources.list.d/163.list \
&& echo "deb-src http://mirrors.163.com/debian/ stretch-updates main non-free contrib" >> /etc/apt/sources.list.d/163.list \
&& echo "deb-src http://mirrors.163.com/debian/ stretch-backports main non-free contrib" >> /etc/apt/sources.list.d/163.list \
&& echo "deb http://mirrors.163.com/debian-security/ stretch/updates main non-free contrib" >> /etc/apt/sources.list.d/163.list \
&& echo "deb-src http://mirrors.163.com/debian-security/ stretch/updates main non-free contrib" >> /etc/apt/sources.list.d/163.list
# update
apt-get update
# wget安装
apt-get install wget
# unzip安装
apt-get install unzip
# 在root目录下
cd ~
# 下载GmSSL源码
wget -O gmssl.zip https://github.com/guanzhi/GmSSL/archive/master.zip
# 解压缩,解压缩到了GmSSL-master目录中,或者解压到指定目录 unzip -o gmssl.zip -d ./gmssl/
unzip -o gmssl.zip
# 下载nginx源码
wget -O nginx-1.18.0.tar.gz https://nginx.org/download/nginx-1.18.0.tar.gz

# 解压nginx,或者解压到指定目录 tar -zxvf ./nginx-1.18.0.tar.gz -C ./nginx
tar -zxvf ./nginx-1.18.0.tar.gz
```

## 基于centos8镜像构建

```sh
docker run -it --name  centos8 -d -p 10001:80 -p 10002:443 centos:8 /bin/bash
yum update -y
yum -y install epel-release wget gcc gcc-c++ glibc make autoconf openssl openssl-devel pcre-devel libxslt-devel gd-devel unzip tar

mkdir /nginx_gmsslg
cd /nginx_gmssl/
wget -O gmssl.zip https://github.com/guanzhi/GmSSL/archive/master.zip && unzip -o gmssl.zip && wget -O nginx-1.18.0.tar.gz https://nginx.org/download/nginx-1.18.0.tar.gz && tar -zxvf ./nginx-1.18.0.tar.gz

# 编译GmSSL
cd GmSSL-master/
./config #--prefix=/usr/local/gmssl --openssldir=/usr/local/gmssl
make
make install
# 添加环境变量
# export LD_LIBRARY_PATH=/usr/local/lib64
echo "export LD_LIBRARY_PATH=/usr/local/lib64" >> /etc/profile
# 是否将gmssl添加进环境变量PATH中?待确认
gmssl version -a

# 编译nginx ,参见https://www.zybuluo.com/guog/note/1697005
```