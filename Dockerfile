FROM node:20-alpine AS builder
WORKDIR /app

RUN apk add --no-cache git

# Clone medplum v5.0.13
RUN git clone --depth 1 --branch v5.0.13 https://github.com/medplum/medplum.git .

# Fix: Remove isDataTypeLoaded check that causes infinite loader
# Also remove now-unused imports to satisfy TypeScript
RUN sed -i '/if (!isDataTypeLoaded(memoizedSearch.resourceType))/,/^  }/d' \
    packages/react/src/SearchControl/SearchControl.tsx && \
    sed -i 's/  Loader,//' packages/react/src/SearchControl/SearchControl.tsx && \
    sed -i 's/  isDataTypeLoaded,//' packages/react/src/SearchControl/SearchControl.tsx

# Install deps
RUN npm ci --ignore-scripts

# Build
RUN npm run build:fast

# Build app
WORKDIR /app/packages/app
ENV MEDPLUM_BASE_URL=__MEDPLUM_BASE_URL__
ENV MEDPLUM_APP_NAME=MediSynth
RUN npm run build

# Production
FROM nginx:alpine
COPY --from=builder /app/packages/app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
