# ---- Base Node ----
FROM node:19-alpine AS base
WORKDIR /app
COPY package*.json ./

# Set up a new user named "user" with user ID 1000
# This is to avoid permission issues as per Hugging Face guidelines
RUN adduser -D -u 1000 user

# ---- Dependencies ----
FROM base AS dependencies
RUN npm ci

# ---- Build ----
FROM dependencies AS build
COPY . .
RUN npm run build

# ---- Production ----
FROM node:19-alpine AS production

# Switch to the "user" user
USER user

# Set home to the user's home directory
ENV HOME=/home/user

# Set the working directory to the user's home directory
WORKDIR $HOME/app

# Copying necessary files with appropriate user permissions
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package*.json ./
COPY --from=build /app/next.config.js ./next.config.js
COPY --from=build /app/next-i18next.config.js ./next-i18next.config.js

# Expose the port the app will run on
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
