FROM node:latest
WORKDIR /usr/app
EXPOSE 8080
CMD [ "node", "index.js" ]
ADD src /usr/app
RUN npm install