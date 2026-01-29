FROM node:22-slim

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose the Hardhat node RPC port
EXPOSE 8545

# Command to run the Hardhat node
CMD ["npm", "exec", "hardhat", "--", "node"]