FROM node:22.11.0-alpine
WORKDIR /app
COPY server.mjs ./
USER node
ENV HOST=0.0.0.0 PORT=3110
EXPOSE 3110
CMD ["node", "server.mjs"]
