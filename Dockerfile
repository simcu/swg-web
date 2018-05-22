FROM openresty/openresty:alpine
RUN apk add --update php7 php7-iconv php7-mbstring
COPY . /home/
EXPOSE 80 443
CMD /home/swg