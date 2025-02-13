# Build stage
FROM golang:1.23 AS builder
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./
# Download all dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the Go binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o restapiservice .

# Ensure the binary has execution permissions
RUN chmod +x /app/restapiservice

# Final stage with Smallstep CA
FROM smallstep/step-ca

WORKDIR /root/

USER root

# Install required dependencies
RUN apk add --no-cache openssh doas expect
RUN ssh-keygen -A
RUN mkdir /var/run/sshd
RUN echo 'step:step' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Allow step user to run commands as root
RUN adduser step wheel
RUN echo "permit nopass :wheel" >> /etc/doas.d/doas.conf

USER step

# Set Smallstep CA environment variables
ENV CONFIGPATH="/root/step/config/ca.json"
ENV PWDPATH="/root/step/secrets/password"

VOLUME ["/root/step"]

# Copy the pre-built Go binary and scripts
COPY --from=builder /app/restapiservice /root/restapiservice
COPY scripts ./scripts

# Ensure correct permissions for step user
USER root
RUN chown step:step /root/restapiservice

USER step

# Expose API port
EXPOSE 8080

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Start SSH and Step CA, then run the API service
CMD doas -u root /usr/sbin/sshd && /usr/local/bin/step-ca --password-file $PWDPATH $CONFIGPATH & /root/restapiservice
