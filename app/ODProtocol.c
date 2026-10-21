#include "ODProtocol.h"
#include <stdlib.h>
#include <string.h>
void ODFrameReaderInit(ODFrameReader *reader, size_t maximum) {
    memset(reader, 0, sizeof *reader);
    reader->maximum = maximum;
}
void ODFrameReaderReset(ODFrameReader *reader) {
    free(reader->payload);
    reader->payload = NULL;
    reader->headerUsed = reader->length = reader->used = 0;
}
void ODFrameReaderDestroy(ODFrameReader *reader) { ODFrameReaderReset(reader); }
int ODFrameReaderFeed(ODFrameReader *reader, const uint8_t *bytes, size_t count,
                      ODBytesCallback callback, void *context) {
    while (count) {
        if (reader->headerUsed < 4) {
            size_t n = 4 - reader->headerUsed;
            if (n > count) n = count;
            memcpy(reader->header + reader->headerUsed, bytes, n);
            reader->headerUsed += n; bytes += n; count -= n;
            if (reader->headerUsed < 4) continue;
            reader->length = ((uint32_t)reader->header[0] << 24) |
                             ((uint32_t)reader->header[1] << 16) |
                             ((uint32_t)reader->header[2] << 8) | reader->header[3];
            if (!reader->length || reader->length > reader->maximum) return -1;
            reader->payload = malloc(reader->length);
            if (!reader->payload) return -1;
        }
        size_t n = reader->length - reader->used;
        if (n > count) n = count;
        memcpy(reader->payload + reader->used, bytes, n);
        reader->used += n; bytes += n; count -= n;
        if (reader->used == reader->length) {
            callback(context, reader->payload, reader->length);
            ODFrameReaderReset(reader);
        }
    }
    return 0;
}
int ODIsControl(const uint8_t *bytes, size_t size) {
    return size > 0 && size < 32768 && bytes[0] == '{' && memchr(bytes, 0, size) == NULL;
}
size_t ODVisitNALUs(const uint8_t *bytes, size_t count, ODBytesCallback callback, void *context) {
    size_t start = SIZE_MAX, found = 0, i = 0;
    while (i + 4 <= count) {
        if (bytes[i] == 0 && bytes[i+1] == 0 && bytes[i+2] == 0 && bytes[i+3] == 1) {
            if (start != SIZE_MAX && i > start) { callback(context, bytes+start, i-start); found++; }
            start = i + 4; i += 4;
        } else i++;
    }
    if (start != SIZE_MAX && count > start) { callback(context, bytes+start, count-start); found++; }
    return found;
}
