FROM debian:buster-slim

# procps is for ps, pkill and kill commands
RUN apt-get update && apt-get install -y openssh-client procps
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "bash" ]
