FROM openresty/openresty
COPY . /home/
RUN rm -f /usr/local/openresty/nginx/conf/nginx.conf && ln -s /home/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf