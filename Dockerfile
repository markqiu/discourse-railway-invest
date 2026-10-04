# Discourse on Railway.
#
# discourse/discourse is upstream's own prebuilt image: the official base image plus
# the Discourse source, gems and node modules, assembled by the same pups templates
# the supported ./launcher install runs. It boots under runit — nginx in front of
# unicorn, with sidekiq inside the unicorn master (UNICORN_SIDEKIQS=1) — and takes all
# of its configuration from DISCOURSE_* environment variables.
#
# 2026.7.1 is the current stable release. `latest` is built from the `main` branch
# (the 2026.8.0 development line), so it is not the tag to run a forum on.
FROM discourse/discourse:2026.7.1

# Real client IPs behind Railway's edge. See nginx/10-real-client-ip.conf for why;
# the outlet is included in the http context, ahead of the server block.
COPY nginx/10-real-client-ip.conf /etc/nginx/conf.d/outlets/before-server/10-real-client-ip.conf
RUN sed -i 's|proxy_set_header X-Forwarded-For \$remote_addr;|proxy_set_header X-Forwarded-For $real_client_ip;|g' \
      /etc/nginx/conf.d/discourse.conf \
 && ! grep -q 'X-Forwarded-For .remote_addr;' /etc/nginx/conf.d/discourse.conf \
 && test "$(grep -c 'X-Forwarded-For .real_client_ip;' /etc/nginx/conf.d/discourse.conf)" -ge 3 \
 && nginx -t

COPY bootstrap-admin.rb /usr/local/bin/railway-bootstrap-admin.rb
COPY entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 0755 /usr/local/bin/railway-entrypoint.sh /usr/local/bin/railway-bootstrap-admin.rb

# 俱乐部自研插件：自选股 + 备忘录（放进官方插件目录，自动被发现、迁移随 db:migrate 执行）
COPY plugins/discourse-invest-tools /var/www/discourse/plugins/discourse-invest-tools
RUN chown -R discourse:discourse /var/www/discourse/plugins/discourse-invest-tools

# Replaces the image's own `CMD ["/sbin/boot"]`; the entrypoint execs it.
CMD ["/usr/local/bin/railway-entrypoint.sh"]
