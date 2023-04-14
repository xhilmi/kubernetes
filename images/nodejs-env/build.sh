# Build image
docker build -t xhilmi/nodejs-env .

# Push container
docker push xhilmi/nodejs-env

# Create container
docker container create --name nodejs-env xhilmi/nodejs-env

# Start container
docker container start nodejs-env

# See container logs
docker container logs -f nodejs-env

# Stop container
docker container stop nodejs-env

# Remove container
docker container rm nodejs-env
