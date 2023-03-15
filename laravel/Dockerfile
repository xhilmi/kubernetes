
# Use the official PHP image as the base image
FROM php:8.0-apache

# Set the working directory to /var/www/html
WORKDIR /var/www/html

# Copy the entire application directory to the image
COPY . /var/www/html

# Install necessary extensions
RUN docker-php-ext-install pdo pdo_mysql

# Set the correct file permissions
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Copy the .env file to the container
COPY .env.example .env

# Generate the application key
RUN php artisan key:generate

# Expose port 80 for incoming HTTP traffic
EXPOSE 80

# Start Apache and run the application
CMD ["apache2-foreground"]
