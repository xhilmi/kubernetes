

FROM node:14

WORKDIR /app

COPY package*.json ./
COPY . .
COPY .* .
COPY * .

RUN npm install

EXPOSE 8000

CMD [ "npm", "start" ]
