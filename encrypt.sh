#!/bin/bash
#
# Encrypts files in source directory that aren't yet encrypted in the
# destination directory.
#
set -euo pipefail

export REMOVE_PLAINTEXT_SOURCE=${REMOVE_PLAINTEXT_SOURCE:-""}
export GPG_KEYS=${GPG_KEYS:-"/etc/keys"}
export SOURCE=${SOURCE:-"/src"}
export DEST=${DEST:-"/dest"}
export SLEEP_TIME=${SLEEP_TIME:-"5s"}

if [ ! -d "$SOURCE" ]; then
		echo "FATAL: Invalid source directory in SOURCE: $SOURCE" >&2
		exit 2
fi

if [ ! -d "$DEST" ]; then
		echo "FATAL: Invalid destination directory in DEST: $DEST" >&2
		exit 3
fi

if [ ! -d "$GPG_KEYS" ]; then
		echo "FATAL: Invalid GPG keys directory in GPG_KEYS: $GPG_KEYS" >&2
		exit 4
fi

NUM_KEYS=$(ls "$GPG_KEYS/"*.asc 2>/dev/null | wc -l)
if [ $NUM_KEYS -eq 0 ]; then
		echo "FATAL: No GPG keys in directory; checked $GPG_KEYS/*.asc" >&2
		exit 5
fi

echo "Importing $NUM_KEYS GPG keys from $GPG_KEYS/*.asc.."
gpg --batch --import "$GPG_KEYS/"*.asc
KEYS=$(gpg -k --with-colons | grep 'pub:*' | cut -d: -f5)
if [ $(echo "$KEYS" | wc -l) -eq 0 ]; then
		echo "FATAL: bug: failed to find GPG keys." >&2
		exit 6
fi

GPG_ARGS=""
for k in $KEYS; do
		GPG_ARGS="$GPG_ARGS --recipient $k --trusted-key $k"
done

echo "Checking for new files to encrypt in $SOURCE.."
cd $DEST
for sourceFile in $(ls "$SOURCE"); do
		destFile="$sourceFile.gpg"
		if [ -e "$DEST/$destFile" ]; then
				if [ ! -e "$destFile.sha" ]; then
						echo "FATAL: No SHA512 digest for encrypted file $DEST/$destFile." >&2
						exit 7
				fi
				if ! sha512sum -c "$destFile.sha"; then
						echo "FATAL: Failed to verify SHA512 digest for $destFile.sha." >&2
						exit 8
				fi
				if [ "$REMOVE_PLAINTEXT_SOURCE" != "" ]; then
						echo "INFO: Removing $sourceFile.."
						rm -v "$SOURCE/$sourceFile"
						sleep 1
				fi
				sleep 0.1s
				continue
		fi

		if [ -e "$destFile.sha" ]; then
				echo "FATAL: No destination file ($destFile) but SHA512 digest already exists ($destFile.sha)." >&2
				exit 9
		fi
		echo "Encrypting $SOURCE/$sourceFile -> $DEST/$destFile.."
		gpg --output "$destFile" --encrypt --armor $GPG_ARGS "$SOURCE/$sourceFile"
		echo "Creating SHA512 digest in $DEST/$destFile.sha.."
		cd "$DEST" && sha512sum "$sourceFile.gpg" > "$destFile.sha"
		chmod 755 "$destFile" "$destFile.sha"
		echo "Sleeping $SLEEP_TIME.."
		sleep $SLEEP_TIME
done

echo "All done."
