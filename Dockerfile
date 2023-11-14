# ---- Base Node ----
FROM node:19-alpine AS base
WORKDIR /app
COPY package*.json ./

# Create a user with a different UID if 1000 is already in use
RUN adduser -D -u 1001 user

# ---- Dependencies ----
FROM base AS dependencies
RUN npm ci

# ---- Build ----
FROM dependencies AS build
COPY . .
RUN npm run build

# ---- Production ----
FROM node:19-alpine AS production

# Switch to the new user
USER user

# Set the user's home directory
ENV HOME=/home/user

# Set the working directory
WORKDIR $HOME/app

# Copy necessary files with correct user permissions
COPY --chown=user --from=dependencies /app/node_modules ./node_modules
COPY --chown=user --from=build /app/.next ./.next
COPY --chown=user --from=build /app/public ./public
COPY --chown=user --from=build /app/package*.json ./
COPY --chown=user --from=build /app/next.config.js ./next.config.js
COPY --chown=user --from=build /app/next-i18next.config.js ./next-i18next.config.js

# Expose the appropriate port (change if needed)
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
