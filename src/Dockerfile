FROM node

RUN cp /usr/app && package*.json ./
RUN npm ci --omit=dev

COPY app.js server.js .

CMD node server.js
