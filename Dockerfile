FROM openresty/openresty
COPY . /home/
ENV REDIS_PORT 6379
ENV TOKEN_EXPIRE 600
RUN rm -f /usr/local/openresty/nginx/conf/nginx.conf && ln -s /home/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf