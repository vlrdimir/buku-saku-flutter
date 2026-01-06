# ============================================
# DOCKERFILE UNTUK TIM YANG TIDAK INSTALL FLUTTER
# ============================================
# 
# File ini dibuat karena beberapa anggota kelompok
# mengalami kendala saat instalasi Flutter SDK.
#
# ============================================
# Multi-stage build: Flutter SDK -> Nginx
# ============================================

# Build arguments for API configuration
ARG API_BASE_URL=http://localhost:8082/v1

# ============================================
# Stage 1: Build Flutter Web Application
# ============================================
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files first for better layer caching
COPY pubspec.yaml pubspec.lock ./

# Get dependencies (cached if pubspec unchanged)
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Accept the API_BASE_URL build arg
ARG API_BASE_URL

# Build the Flutter web app with the API URL
# This compiles the app with the specified API endpoint
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ============================================
# Stage 2: Production Nginx Server
# ============================================
FROM nginx:alpine AS production

# Install curl for healthcheck
RUN apk add --no-cache curl

# Remove default nginx config
RUN rm -rf /usr/share/nginx/html/*

# Copy built Flutter web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
