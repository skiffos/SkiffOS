
# Added by skiff core
ADD startup.sh dumb-init /
RUN chmod 0755 /startup.sh /dumb-init && touch /.container_startup_in_progress && mkdir -p /mnt/core
VOLUME ["/mnt/core"]
ENTRYPOINT ["/dumb-init"]
CMD ["/startup.sh"]
