FROM node:22-bookworm AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        zip \
        unzip \
        wget \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN npm install

RUN node -e "const fs=require('fs'); const config=JSON.parse(fs.readFileSync('libs-config.json','utf8')); if (!config.fonts?.extraFonts?.length) throw new Error('extraFonts saknas i libs-config.json'); console.log('libs-config.json OK'); console.log(config.fonts.extraFonts);"

RUN npm run build:libs

RUN npm run build


FROM nginx:1.27-alpine

RUN rm -rf /usr/share/nginx/html/* \
    && mkdir -p /usr/share/nginx/html/library \
    && mkdir -p /usr/share/nginx/html/models

COPY --from=build /app/dist/ /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY library.html /usr/share/nginx/html/library/index.html

RUN chmod 644 \
    /etc/nginx/conf.d/default.conf \
    /usr/share/nginx/html/library/index.html

EXPOSE 80

HEALTHCHECK \
    --interval=30s \
    --timeout=3s \
    --start-period=15s \
    --retries=3 \
    CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
