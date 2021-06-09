FROM node:14.17.0
WORKDIR /usr/app

COPY package*.json ./
RUN npm ci --production

COPY index.js .

ENV NODE_ENV='production'
USER node
EXPOSE 8080
CMD [ "node", "index.js" ]
