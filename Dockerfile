FROM oven/bun AS build

WORKDIR /app

COPY bun.lockb . 
COPY package.json . 

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

RUN bun install --frozen-lockfile

COPY src ./src

RUN bun build ./src/index.ts --compile --outfile server

FROM ubuntu:22.04

WORKDIR /app

COPY --from=build /app/server /app/server

RUN apt-get update && apt-get install gnupg wget -y && \
  wget --quiet --output-document=- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google-archive.gpg && \
  sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' && \
  apt-get update && \
  apt-get install google-chrome-stable -y --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

RUN mkdir ~/.fonts/ && \
  wget https://github.com/samuelngs/apple-emoji-linux/releases/download/ios-15.4/AppleColorEmoji.ttf -O ~/.fonts/AppleColorEmoji.ttf

ENV RUNNING_IN_DOCKER true
ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/google-chrome-stable
CMD ["/app/server"]