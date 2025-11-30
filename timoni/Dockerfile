FROM alpine:latest

# Copy CA certificates from local system
COPY ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Copy timoni binary from local system
COPY timoni /usr/local/bin/timoni
RUN chmod +x /usr/local/bin/timoni

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/timoni"]
