#!/bin/bash

# Install gdrive: https://github.com/prasmussen/gdrive
# Add IDs for the empty REMOTE_DIR_ID vars with `gdrive list`

BACKUP_DIR=/path/to/dir/for/backup

# Compress BACKUP_DIR and upload to the Google Drive
function upload_compressed {    
    REMOTE_DIR_ID=
    BACKUP_PREFIX=stats

    COMPRESSED_FILE="/tmp/${BACKUP_PREFIX}-$(date +%Y-%m-%d-%H-%M-%S).zip"

    cd "$1"

    zip -r "$COMPRESSED_FILE" . -x "backup/*"
    
    echo "Uploading $COMPRESSED_FILE..."
    gdrive upload -p $REMOTE_DIR_ID $COMPRESSED_FILE
}

# Sync BACKUP_DIR with the remote dir on the Google Drive
function sync_dir {
    REMOTE_DIR_ID=

    gdrive sync upload $1 $REMOTE_DIR_ID
}

# Run backup and syncing
upload_compressed $BACKUP_DIR
sync_dir $BACKUP_DIR

