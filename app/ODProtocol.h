#ifndef OD_PROTOCOL_H
#define OD_PROTOCOL_H
#include <stddef.h>
#include <stdint.h>
typedef void (*ODBytesCallback)(void *, const uint8_t *, size_t);
typedef struct {
    uint8_t header[4];
    size_t headerUsed, length, used, maximum;
    uint8_t *payload;
} ODFrameReader;
void ODFrameReaderInit(ODFrameReader *, size_t maximum);
void ODFrameReaderReset(ODFrameReader *);
void ODFrameReaderDestroy(ODFrameReader *);
int ODFrameReaderFeed(ODFrameReader *, const uint8_t *, size_t, ODBytesCallback, void *);
int ODIsControl(const uint8_t *, size_t);
size_t ODVisitNALUs(const uint8_t *, size_t, ODBytesCallback, void *);
#endif
