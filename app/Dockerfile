FROM node:20-alpine

USER node

ENV NODE_ENV=production

WORKDIR /home/node/app

COPY --chown=node:node --chmod=400 package.json .

RUN npm i --only=production

COPY --chown=node:node --chmod=500 bin ./bin
COPY --chown=node:node --chmod=u=rX,g=,o= src ./src

EXPOSE 3000

CMD ["npm", "start"]
