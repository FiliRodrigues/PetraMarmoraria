# Stage 1 - Build the Flutter Web application
FROM ghcr.io/cirruslabs/flutter:3.29.0 AS build-env

# Set working directory
WORKDIR /app

# Copy dependency files first
COPY petra_erp/pubspec.yaml petra_erp/pubspec.lock ./
RUN flutter pub get

# Copy all source files
COPY petra_erp/ .

# Build the web application in release mode
RUN flutter build web --release

# Stage 2 - Serve the application using Nginx
FROM nginx:alpine

# Copy the build artifacts from the build stage to Nginx html folder
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
