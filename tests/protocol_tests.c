#include "ODProtocol.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

static int frames;
static unsigned lengths[8];
static unsigned char first[8];
static void frame(void *context, const uint8_t *bytes, size_t size) {
    (void)context;
    lengths[frames] = (unsigned)size;
    first[frames++] = bytes[0];
}
static int nalus;
static unsigned types[8], sizes[8];
static void nalu(void *context, const uint8_t *bytes, size_t size) {
    (void)context;
    types[nalus] = bytes[0] & 31;
    sizes[nalus++] = (unsigned)size;
}
int main(void) {
    ODFrameReader reader;
    ODFrameReaderInit(&reader, 1024);
    const uint8_t wire[] = {0,0,0,2,'{','}',0,0,0,3,0x65,0x12,0x34};
    /* A TCP read can split anywhere, including inside the length header. */
    for (size_t i=0; i<sizeof wire; i++)
        assert(ODFrameReaderFeed(&reader, wire+i, 1, frame, NULL) == 0);
    assert(frames == 2 && lengths[0] == 2 && first[0] == '{' && lengths[1] == 3 && first[1] == 0x65);
    frames=0;
    assert(ODFrameReaderFeed(&reader, wire, sizeof wire, frame, NULL) == 0);
    assert(frames == 2);
    const uint8_t oversize[] = {0,0,4,1}, zero[] = {0,0,0,0};
    assert(ODFrameReaderFeed(&reader, oversize, 4, frame, NULL) == -1);
    ODFrameReaderReset(&reader);
    assert(ODFrameReaderFeed(&reader, zero, 4, frame, NULL) == -1);
    ODFrameReaderDestroy(&reader);
    assert(ODIsControl((const uint8_t *)"{\"type\":\"ping\"}", 15));
    const uint8_t binary[] = {'{',0,0,0,1,0x65};
    assert(!ODIsControl(binary, sizeof binary));
    /* JSON telemetry precedes the first Annex B start code. */
    const uint8_t video[] = {'{','}',0,0,0,1,0x67,0x42,0,0,0,1,0x68,0x12,0,0,0,1,0x65,0x88};
    assert(ODVisitNALUs(video, sizeof video, nalu, NULL) == 3);
    assert(nalus == 3 && types[0] == 7 && types[1] == 8 && types[2] == 5);
    assert(sizes[0] == 2 && sizes[1] == 2 && sizes[2] == 2);
    assert(ODVisitNALUs((const uint8_t *)"broken", 6, nalu, NULL) == 0);
    const uint8_t empty[] = {0,0,0,1};
    assert(ODVisitNALUs(empty, sizeof empty, nalu, NULL) == 0);
    puts("PASS: fragmented/coalesced framing, length bounds, demux, Annex B telemetry and NAL boundaries");
}
