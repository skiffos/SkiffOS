#!/bin/bash
set -eo pipefail

IMAGE_NAME="quay.io/skiffos/skiff-core-debian"
DOCKERFILE="./Dockerfile"

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
    echo "Dockerfile not found in the current directory."
    exit 1
fi

# Define ARCH_TAGS and ARCH_IMAGES
ARCH_TAGS=(
    arm
    arm64
    amd64
    riscv64
    i386
)
ARCH_IMAGES=("${ARCH_TAGS[@]/#/${IMAGE_NAME}:}")

# Function to convert tag to platform
tag_to_platform() {
    case $1 in
        "arm") echo "linux/arm/v7" ;;
        "arm64") echo "linux/arm64" ;;
        "amd64") echo "linux/amd64" ;;
        "riscv64") echo "linux/riscv64" ;;
        "i386") echo "linux/386" ;;
        *) echo "unknown" ;;
    esac
}

# Build and push for each architecture
for tag in "${ARCH_TAGS[@]}"; do
    platform=$(tag_to_platform $tag)
    
    echo "Building for $platform..."
    docker buildx build --platform $platform -t ${IMAGE_NAME}:${tag} -f $DOCKERFILE . --push
    
    if [ $? -eq 0 ]; then
        echo "Successfully built and pushed ${IMAGE_NAME}:${tag}"
    else
        echo "Failed to build or push ${IMAGE_NAME}:${tag}"
        exit 1
    fi
done

echo "All architectures built and pushed successfully."

