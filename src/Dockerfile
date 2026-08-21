FROM node:22.23.2-slim
WORKDIR /usr/app

COPY package*.json ./
RUN npm ci --omit=dev

COPY app.js server.js ./

ENV NODE_ENV='production'
USER 1000:1000
EXPOSE 8080
CMD [ "node", "server.js" ]
