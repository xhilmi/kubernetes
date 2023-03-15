# Use an official Node.js runtime as a parent image
FROM node:14 as build

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json to the container
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code to the container
COPY . .

# Build the production version of the app
RUN npm run build

# Use the official Nginx image as a parent image
FROM nginx:latest

# Copy the built app from the build stage to the container
COPY --from=build /app/build /usr/share/nginx/html

# Copy the custom index.html file to the container
COPY index.html /usr/share/nginx/html/index.html

# Copy the custom Nginx configuration file to the container
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 8181
EXPOSE 8181

# Start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]
