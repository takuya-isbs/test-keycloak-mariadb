FROM httpd:2.4

# RUN apt-get update && \
#     apt-get install -y --no-install-recommends apache2-utils && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

### MEMO: default configuration from the container
### docker run --rm httpd:2.4 cat /usr/local/apache2/conf/httpd.conf > my-httpd.conf
COPY ./my-httpd.conf /usr/local/apache2/conf/httpd.conf
