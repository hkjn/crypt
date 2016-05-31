#
# Encrypts directories against public GPG keys.
#
# Mount the directory holding public GPG keys into the container, along
# with the source (plaintext input) and destination (encrypted output)
# directories. E.g, to encrypt /path/in -> /path/out:
# docker run -v /path/keys:/etc/keys -v /path/in:/src \
#            -v /path/out:/dest [this image]
#
# If the REMOVE_PLAINTEXT_SOURCE environment variable is set, the
# plaintext source files that are found to already be encrypted in the
# destination (with valid SHA digests) are removed automatically the
# next time they're encountered. This option should be used with
# caution.

# TODO(hkjn): Switch to alpine as base.
FROM debian
MAINTAINER Henrik Jonsson <me@hkjn.me>
COPY ["encrypt.sh", "/usr/local/sbin/" ]
CMD ["encrypt.sh"]