FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY tsconfig.json ./
COPY src ./src
COPY prisma ./prisma
RUN npx prisma generate
RUN npm run build
EXPOSE 3000
CMD ["node","dist/main.js"]