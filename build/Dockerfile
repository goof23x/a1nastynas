FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    cubic \
    git \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /a1nas

# Copy build scripts
COPY build/create_nas_os.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/create_nas_os.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/create_nas_os.sh"] 