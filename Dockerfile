# Static site — no build step, no runtime dependencies.
FROM nginx:1.27-alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/site.conf

COPY index.html support.html 404.html robots.txt /usr/share/nginx/html/

# The policies live under /legal/ so the e-commerce site that replaces this one
# keeps its top-level namespace free. These paths are compiled into app builds
# and cannot move afterwards — see README section 3.
#
# data-deletion.html is not linked from an app build, but its URL is registered
# with Meta as the Facebook Login data deletion instructions URL. A 404 there
# blocks the Meta app from going Live, so it is just as load-bearing.
COPY privacy.html terms.html returns.html shipping.html cancellation.html \
     data-deletion.html \
     /usr/share/nginx/html/legal/

COPY assets/ /usr/share/nginx/html/assets/


EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
