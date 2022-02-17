# Deploy the app in a Docker container. Use node as the base image. Version node:10 or later should work.
#FROM node:10
FROM node:current-alpine
# git is needed to pull the source from github, obviously
# RUN yum install -y git
RUN apk add --no-cache git openssh-client
# Pull down the source code from git, placing it into /app
RUN mkdir -p /app && git clone https://github.com/rearc/quest /app
# Install dependencies in working directory
WORKDIR /app
COPY package*.json ./
RUN npm install
# Copy only what we need, excluding dev files
COPY bin ./bin
COPY src ./src
# It would be much more secure in a real life situation to use AWS Secrets Manager or something similar to store any actual secrets, but good enough for a demo?
ENV SECRET_WORD=TwelveFactor
# Serve the application on port 3000, even though that's something one would usually use for dev
EXPOSE 3000
# One could have written `CMD [ "node", "src/000.js" ]`
CMD [ "npm", "start" ]
