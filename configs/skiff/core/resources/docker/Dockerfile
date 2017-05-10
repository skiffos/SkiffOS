# Added by skiff core
ADD startup.sh /
RUN chmod 0755 /startup.sh && \
    touch /.container_startup_in_progress && \
    mkdir -p /mnt/core
VOLUME ["/mnt/core"]
ENTRYPOINT ["/startup.sh"]
CMD []
