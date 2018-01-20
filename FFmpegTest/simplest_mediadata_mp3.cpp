//
//  simplest_mediadata_mp3.cpp
//  FFmpegTest
//
//  Created by 姚振兴 on 2018/2/6.
//  Copyright © 2018年 kugou. All rights reserved.
//

#include <stdio.h>
#include <time.h>
#include <errno.h>
#include <unistd.h>
#include <ctype.h>
#include <inttypes.h>
#include <stdlib.h>

#include <string.h>

#define ID3v2_HEADER_SIZE 10
#define MAX_BUF_SIZE 100000000
//#define MAX_BUF_SIZE 2519178


#define MPA_STEREO  0
#define MPA_JSTEREO 1
#define MPA_DUAL    2
#define MPA_MONO    3

#define AV_RB32(x)  ((((const uint8_t*)(x))[0] << 24) | \
(((const uint8_t*)(x))[1] << 16) | \
(((const uint8_t*)(x))[2] <<  8) | \
((const uint8_t*)(x))[3])


#define FFMAX(a,b) ((a) > (b) ? (a) : (b))

#define MPA_DECODE_HEADER \
int frame_size; \
int error_protection; \
int layer; \
int sample_rate; \
int sample_rate_index; /* between 0 and 8 */ \
int bit_rate; \
int nb_channels; \
int mode; \
int mode_ext; \
int lsf;

typedef struct MPADecodeHeader {
    MPA_DECODE_HEADER
} MPADecodeHeader;

static unsigned char const_buf[MAX_BUF_SIZE];
//const char *filename = "/tmp/MrsLeta.mp3";
//const char *filename = "/tmp/312178.mp3";
//char *filename;
const uint16_t ff_mpa_bitrate_tab[2][3][15] = {
    { {0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448 },
        {0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384 },
        {0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320 } },
    { {0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256},
        {0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160},
        {0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160}
    }
};

const uint16_t ff_mpa_freq_tab[3] = { 44100, 48000, 32000 };

int ff_id3v2_tag_len (unsigned char* buf);
int ff_int_buf(unsigned char *buf,char *filename);
int ff_mpa_decode_header( uint32_t head, int *sample_rate, int *channels, int *frame_size, int *bit_rate);
static inline int ff_mpa_check_header(uint32_t header);
int ff_id3v2_match(const uint8_t *buf);

int simplest_mp3_parser(char *inFile)
{
//    filename = inFile;
//    memcpy(inFile,filename,sizeof(inFile));
    int size = ff_int_buf(const_buf,inFile);
    
    int len = ff_id3v2_tag_len(const_buf);
    
    
    unsigned char *buf0,*buf2,*buf,*end;
    
    int max_frames = 0, first_frames = 0;
    int fsize, frames, sample_rate;
    uint32_t header;
    
    buf0 = const_buf ;
    if(ff_id3v2_match(buf0)) {
        buf0 += ff_id3v2_tag_len(buf0);
    }
    buf = buf0;
    
    end = buf + size - sizeof(uint32_t);
    
    for(; buf < end; buf= buf2+1) {
        buf2 = buf;
        for(frames = 0; buf2 < end; frames++) {
            header = AV_RB32(buf2);
            fsize = ff_mpa_decode_header(header, &sample_rate, &sample_rate, &sample_rate, &sample_rate);
            if(fsize < 0)
                break;
            buf2 += fsize;
        }
        max_frames = FFMAX(max_frames, frames);
    }
    return 0;
}


int ff_int_buf(unsigned char *buf,char *filename)
{
    FILE *f;
    f = fopen(filename, "r");
    if (!f) {
//        fprintf(stderr, "Cannot read file '%s' for pass-2 encoding: %s\n", filename, strerror(errno));
        return -1;
    }
    int size = fread(const_buf, 1, MAX_BUF_SIZE, f);
    const_buf[size] = '\0';
    fclose(f);
    return size;
}

int ff_mpegaudio_decode_header(MPADecodeHeader *s, uint32_t header)
{
    int sample_rate, frame_size, mpeg25, padding;
    int sample_rate_index, bitrate_index;
    if (header & (1<<20)) {
        s->lsf = (header & (1<<19)) ? 0 : 1;
        mpeg25 = 0;
    } else {
        s->lsf = 1;
        mpeg25 = 1;
    }
    
    s->layer = 4 - ((header >> 17) & 3);
    /* extract frequency */
    sample_rate_index = (header >> 10) & 3;
    sample_rate = ff_mpa_freq_tab[sample_rate_index] >> (s->lsf + mpeg25);
    sample_rate_index += 3 * (s->lsf + mpeg25);
    s->sample_rate_index = sample_rate_index;
    s->error_protection = ((header >> 16) & 1) ^ 1;
    s->sample_rate = sample_rate;
    
    bitrate_index = (header >> 12) & 0xf;
    padding = (header >> 9) & 1;
    //extension = (header >> 8) & 1;
    s->mode = (header >> 6) & 3;
    s->mode_ext = (header >> 4) & 3;
    //copyright = (header >> 3) & 1;
    //original = (header >> 2) & 1;
    //emphasis = header & 3;
    if (s->mode == MPA_MONO)
        s->nb_channels = 1;
    else
        s->nb_channels = 2;
    
    if (bitrate_index != 0) {
        frame_size = ff_mpa_bitrate_tab[s->lsf][s->layer - 1][bitrate_index];
        s->bit_rate = frame_size * 1000;
        switch(s->layer) {
            case 1:
                frame_size = (frame_size * 12000) / sample_rate;
                frame_size = (frame_size + padding) * 4;
                break;
            case 2:
                frame_size = (frame_size * 144000) / sample_rate;
                frame_size += padding;
                break;
            default:
            case 3:
                frame_size = (frame_size * 144000) / (sample_rate << s->lsf);
                frame_size += padding;
                break;
        }
        s->frame_size = frame_size;
    } else {
        /* if no frame size computed, signal it */
        return 1;
    }
    
//    #if defined(DEBUG)
    printf("frame_size:%d,layer:%d, %d Hz, %d kbits/s, 声道数：%d",
                s->frame_size, s->layer, s->sample_rate, s->bit_rate,s->nb_channels);
//        if (s->nb_channels == 2) {
//            if (s->layer == 3) {
////                if (s->mode_ext & MODE_EXT_MS_STEREO)
////                    printf("ms-");
////                if (s->mode_ext & MODE_EXT_I_STEREO)
////                    printf("i-");
//            }
//            printf("stereo");
//        } else {
//            printf("mono");
//        }
    
        printf("\n");
//    #endif
    return 0;
}

int ff_id3v2_tag_len (unsigned char* buf)
{
    int len = ((buf[6] & 0x7f) << 21) +
    ((buf[7] & 0x7f) << 14) +
    ((buf[8] & 0x7f) << 7) +
    (buf[9] & 0x7f) +
    ID3v2_HEADER_SIZE;
    if (buf[5] & 0x10)
        len += ID3v2_HEADER_SIZE;
    return len;
}

int ff_mpa_decode_header( uint32_t head, int *sample_rate, int *channels, int *frame_size, int *bit_rate
                         )
{
    MPADecodeHeader s1, *s = &s1;
    
    if (ff_mpa_check_header(head) != 0)
        return -1;
    
    if (ff_mpegaudio_decode_header(s, head) != 0) {
        return -1;
    }
    
    
    switch(s->layer) {
        case 1:
            *frame_size = 384;
            break;
        case 2:
            *frame_size = 1152;
            break;
        default:
        case 3:
            if (s->lsf)
                *frame_size = 576;
            else
                *frame_size = 1152;
            break;
    }
    
    *sample_rate = s->sample_rate;
    *channels = s->nb_channels;
    *bit_rate = s->bit_rate;
    return s->frame_size;
}

/* fast header check for resync */
static inline int ff_mpa_check_header(uint32_t header){
    /* header */
    if ((header & 0xffe00000) != 0xffe00000)
        return -1;
    /* layer check */
    if ((header & (3<<17)) == 0)
        return -1;
    /* bit rate */
    if ((header & (0xf<<12)) == 0xf<<12)
        return -1;
    /* frequency */
    if ((header & (3<<10)) == 3<<10)
        return -1;
    return 0;
}

int ff_id3v2_match(const uint8_t *buf)
{
    return  buf[0] == 'I' &&
    buf[1] == 'D' &&
    buf[2] == '3' &&
    buf[3] != 0xff &&
    buf[4] != 0xff &&
    (buf[6] & 0x80) == 0 &&
    (buf[7] & 0x80) == 0 &&
    (buf[8] & 0x80) == 0 &&
    (buf[9] & 0x80) == 0;
}
