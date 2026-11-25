FROM python:trixie

COPY --chmod=755 startup.sh /usr/local/sbin
RUN startup.sh
CMD ["sleep", "3650d"]
