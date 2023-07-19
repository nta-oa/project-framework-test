FROM node:18

ENV GOOGLE_APPLICATION_CREDENTIALS="/app/cred.json"

WORKDIR /app

COPY build build
COPY sql sql
COPY public public
COPY package.json .
COPY package-lock.json .
COPY .npmrc .
COPY tsconfig.json .
COPY cred.json .

EXPOSE $PORT

RUN npm config set strict-ssl false
RUN npm run prepare
RUN npm ci --omit dev

CMD [ "npm", "start" ]
