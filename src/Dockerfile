FROM node:20.12.2-slim
WORKDIR /usr/app

COPY package*.json ./
RUN npm ci --omit=dev

COPY app.js server.js ./

ENV NODE_ENV='production'
USER node
EXPOSE 8080
CMD [ "node", "server.js" ]
