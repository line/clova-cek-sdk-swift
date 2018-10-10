# Base image from https://github.com/IBM-Swift/swift-ubuntu-docker
FROM ibmcom/swift-ubuntu:4.1.3

MAINTAINER LINE Corporation
LABEL Description="Sample of CEK"

# Set environment variables for image
ARG PORT
ENV PORT ${PORT}
ARG APPLICATION_ID
ENV APPLICATION_ID ${APPLICATION_ID}
ARG PATH_FOR_DEBUG
ENV PATH_FOR_DEBUG ${PATH_FOR_DEBUG}
ARG LOG_TYPES
ENV LOG_TYPES ${LOG_TYPES}

# For Geocoding API
ARG GOOGLE_API_KEY
ENV GOOGLE_API_KEY ${GOOGLE_API_KEY}

# Project Folder
ADD ./ /app
WORKDIR /app

# RUN apt-get update -qq && apt-get install -y libpq-dev
RUN swift build --product WorldClock -c release
RUN chmod -R a+w /app && chmod 755 /app

CMD .build/release/WorldClock
