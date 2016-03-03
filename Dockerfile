FROM debian:jessie

MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"

ENV NGINX_VERSION 1.9.11-1~jessie

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
	&& echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -y ca-certificates nginx=${NGINX_VERSION} gettext-base \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# addition due to issue:
# drewbookpro:atlassian andrewkhoury$ docker-compose up -d
# ...
# Recreating atlassian_nginx_1
# ERROR: Cannot start container 665e642afbffd90f162ad387288f4e535c9cbe9452dc5a73dc82c8d8cf8c7b55: [9] System error: not a directory
COPY ["nginx.conf","/etc/nginx/nginx.conf"]

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
