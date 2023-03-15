FROM nginx

# Remove the default Nginx configuration file
RUN rm /etc/nginx/conf.d/default.conf

# Copy the custom Nginx configuration file to the container
COPY nginx.conf /etc/nginx/conf.d/

# Copy the custom HTML file to the container
COPY index.html /usr/share/nginx/html/
