FROM node:14.15.5
WORKDIR /usr/app

COPY package*.json ./
RUN npm ci --production

COPY index.js .

ENV NODE_ENV='production'
USER node
EXPOSE 8080
CMD [ "node", "index.js" ]
