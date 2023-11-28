function log
{
    # timestamp format is ISO 8601 to match rsyslogd format
    echo "$(date -u +"%Y-%m-%dT%H:%M:%S.%6N%:z") $0 - $1"
}