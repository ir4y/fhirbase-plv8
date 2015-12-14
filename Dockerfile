FROM node:0.12
RUN npm install -g mocha
RUN npm install -g coffee-script
ADD package.json .
RUN npm install
ADD plpl/package.json .
RUN npm install
RUN mkdir /data
ADD . /data
WORKDIR /data
