FROM debian:buster-slim

# Install OpenSSH client
RUN apt-get update && apt-get install -y openssh-client

# Copy the private key file to the container
COPY ~/.ssh/aws_id_rsa /root/.ssh/id_rsa

# Set the permissions for the private key file
RUN chmod 600 /root/.ssh/id_rsa

# Start the SSH tunnel
# ssh -i ~/.ssh/aws_id_rsa -g -N -R 0.0.0.0:1025:mail.lan:25 ubuntu@aws.olafrv.com
CMD ["ssh", "-N", "-R", \
    "-i /root/.ssh/id_rsa", \
     "1025:mail.lan:25", \
     "ubuntu@aws.olafrv.com" \ 
]
