FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /workspace

RUN flutter config --no-analytics

CMD ["flutter", "--version"]

