FROM node:12.16.3
WORKDIR /usr/app

COPY package.json .
RUN npm install

COPY index.js .

ENV NODE_ENV='production'
USER node
EXPOSE 8080
CMD [ "node", "index.js" ]
