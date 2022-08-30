FROM node:latest
# Creat work dirctory
WORKDIR /usr/src/node
# copy package.jason for js depos
COPY package.json .
COPY package-lock.json .
# Install using npm
RUN npm install
# copy index.js to image system
COPY . .
# run as masud user
# Expoose on port 3030
EXPOSE 3030/tcp
# Start npm
CMD ["npm", "start"]