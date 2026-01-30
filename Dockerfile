# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Clone medplum
RUN apk add --no-cache git
RUN git clone --depth 1 --branch v5.0.13 https://github.com/medplum/medplum.git .

# Apply fix
COPY patches/search-control-fix.patch /tmp/
RUN git apply /tmp/search-control-fix.patch

# Install and build
RUN npm ci --ignore-scripts
RUN npm run build:fast

# Build app with custom branding
WORKDIR /app/packages/app
ENV MEDPLUM_BASE_URL=__MEDPLUM_BASE_URL__
ENV MEDPLUM_APP_NAME=MediSynth
ENV GOOGLE_CLIENT_ID=
ENV RECAPTCHA_SITE_KEY=
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/packages/app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
