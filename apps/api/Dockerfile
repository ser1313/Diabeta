FROM node:22-alpine
WORKDIR /app
# Instalación reproducible desde package-lock.json.
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
COPY prisma ./prisma
RUN npx prisma generate
# Tras compilar se eliminan las dependencias de desarrollo (Nest CLI,
# TypeScript...) para reducir la superficie de la imagen. `prisma` es
# dependencia de producción porque CMD ejecuta `prisma migrate deploy`.
RUN npm run build && npm prune --omit=dev && npm cache clean --force
EXPOSE 3000
USER node
CMD ["sh","-c","npx prisma migrate deploy && node dist/main.js"]
