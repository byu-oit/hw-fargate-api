FROM node:14.15.0
WORKDIR /usr/app

COPY package*.json ./
RUN npm install --production

COPY index.js .

ENV NODE_ENV='production'
USER node
EXPOSE 8080
CMD [ "node", "index.js" ]
