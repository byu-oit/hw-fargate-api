FROM node:14.18.3
WORKDIR /usr/app

COPY package*.json ./
RUN npm ci --production

COPY app.js server.js ./

ENV NODE_ENV='production'
USER node
EXPOSE 8080
CMD [ "node", "server.js" ]
