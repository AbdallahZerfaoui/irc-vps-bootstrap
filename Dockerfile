# Dockerfile

# Use ARG to declare a build-time argument.
# We give it a default value, though it will be overridden by docker-compose.
ARG FOLDER_NAME=default_folder

# Start from a base image with necessary libraries
FROM debian:bullseye-slim

# Set an ENV variable from the ARG.
# ENV variables are available at runtime (for CMD), and also during the build.
ENV FOLDER_NAME=${FOLDER_NAME}
ENV PORT=${PORT}

# Install necessary packages for building the project
RUN apt-get update && apt-get install -y build-essential

# Set the working directory inside the container
WORKDIR /app

# Copy the source code for the specific branch into the container.
# Dockerfile ARGs *can* be used in the COPY instruction.
# This assumes your project structure is: ./branches/dev-abdallah/ and ./branches/dev-tobias/
COPY branches/${FOLDER_NAME}/ ./

# Compile the source code
# The ENV variable is expanded by the shell here.
RUN make re

# Make sure it's executable (good practice)
RUN chmod +x ./ircserv

# The command to run when the container starts.
# The shell will expand the ENV variable here.
# NOTE: Use the 'shell' form of CMD to allow variable expansion.
CMD ./ircserv ${PORT} ${FOLDER_NAME}