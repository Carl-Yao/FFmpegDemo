//
//  MediaManager.m
//  FFmpegTest
//
//  Created by 姚振兴 on 16/5/6.
//  Copyright © 2016年 kugou. All rights reserved.
//

#import "MediaManager.h"

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>

#include <libavutil/mathematics.h>
#include <libavutil/time.h>

#import <librtmp/rtmp.h>
#import <librtmp/log.h>

#ifdef __cplusplus
extern "C"
{
#endif
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswresample/swresample.h>
#ifdef __cplusplus
};
#endif

#define MAX_AUDIO_FRAME_SIZE 192000 // 1 second of 48khz 32bit audio
//#include "ffmpeg.h"
//int ffmpegmain(int argc, char **argv);
@implementation MediaManager

+ (void)decoder
{
    AVFormatContext	*pFormatCtx;
    int				i, videoindex;
    AVCodecContext	*pCodecCtx;
    AVCodec			*pCodec;
    AVFrame	*pFrame,*pFrameYUV;
    uint8_t *out_buffer;
    AVPacket *packet;
    int y_size;
    int ret, got_picture;
    struct SwsContext *img_convert_ctx;
    FILE *fp_yuv;
    int frame_cnt;
    clock_t time_start, time_finish;
    double  time_duration = 0.0;
    
    char input_str_full[500]={0};
    char output_str_full[500]={0};
    char info[1000]={0};
    
    NSString *input_str= [NSString stringWithFormat:@"IMG_1841.mov"];//self.inputurl.text];
    NSString *output_str= [NSString stringWithFormat:@"testdecoder.yuv"];//self.outputurl.text];
    
    NSString *input_nsstr=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:input_str];
    NSString *output_nsstr=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:output_str];
    
    sprintf(input_str_full,"%s",[input_nsstr UTF8String]);
    sprintf(output_str_full,"%s",[output_nsstr UTF8String]);
    
    printf("Input Path:%s\n",input_str_full);
    printf("Output Path:%s\n",output_str_full);
    
    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    
    if(avformat_open_input(&pFormatCtx,input_str_full,NULL,NULL)!=0){
        printf("Couldn't open input stream.\n");
        return ;
    }
    if(avformat_find_stream_info(pFormatCtx,NULL)<0){
        printf("Couldn't find stream information.\n");
        return;
    }
    videoindex=-1;
    for(i=0; i<pFormatCtx->nb_streams; i++)
        if(pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex=i;
            break;
        }
    if(videoindex==-1){
        printf("Couldn't find a video stream.\n");
        return;
    }
    pCodecCtx=pFormatCtx->streams[videoindex]->codec;
    pCodec=avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec==NULL){
        printf("Couldn't find Codec.\n");
        return;
    }
    if(avcodec_open2(pCodecCtx, pCodec,NULL)<0){
        printf("Couldn't open codec.\n");
        return;
    }
    
    pFrame=av_frame_alloc();
    pFrameYUV=av_frame_alloc();
    out_buffer=(unsigned char *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_YUV420P,  pCodecCtx->width, pCodecCtx->height,1));
    av_image_fill_arrays(pFrameYUV->data, pFrameYUV->linesize,out_buffer,
                         AV_PIX_FMT_YUV420P,pCodecCtx->width, pCodecCtx->height,1);
    packet=(AVPacket *)av_malloc(sizeof(AVPacket));
    
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt,
                                     pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    
    
    sprintf(info,   "[Input     ]%s\n", [input_str UTF8String]);
    sprintf(info, "%s[Output    ]%s\n",info,[output_str UTF8String]);
    sprintf(info, "%s[Format    ]%s\n",info, pFormatCtx->iformat->name);
    sprintf(info, "%s[Codec     ]%s\n",info, pCodecCtx->codec->name);
    sprintf(info, "%s[Resolution]%dx%d\n",info, pCodecCtx->width,pCodecCtx->height);
    
    
    fp_yuv=fopen(output_str_full,"wb+");
    if(fp_yuv==NULL){
        printf("Cannot open output file.\n");
        return;
    }
    
    frame_cnt=0;
    time_start = clock();
    
    while(av_read_frame(pFormatCtx, packet)>=0){
        if(packet->stream_index==videoindex){
            ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
            if(ret < 0){
                printf("Decode Error.\n");
                return;
            }
            if(got_picture){
                sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                          pFrameYUV->data, pFrameYUV->linesize);
                
                y_size=pCodecCtx->width*pCodecCtx->height;
                fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
                fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
                fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
                //Output info
                char pictype_str[10]={0};
                switch(pFrame->pict_type){
                    case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
                    case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
                    case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
                    default:sprintf(pictype_str,"Other");break;
                }
                printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
                frame_cnt++;
            }
        }
        av_free_packet(packet);
    }
    //flush decoder
    //FIX: Flush Frames remained in Codec
    while (1) {
        ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
        if (ret < 0)
            break;
        if (!got_picture)
            break;
        sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                  pFrameYUV->data, pFrameYUV->linesize);
        int y_size=pCodecCtx->width*pCodecCtx->height;
        fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
        fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
        fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
        //Output info
        char pictype_str[10]={0};
        switch(pFrame->pict_type){
            case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
            case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
            case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
            default:sprintf(pictype_str,"Other");break;
        }
        printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
        frame_cnt++;
    }
    time_finish = clock();
    time_duration=(double)(time_finish - time_start);
    
    sprintf(info, "%s[Time      ]%fus\n",info,time_duration);
    sprintf(info, "%s[Count     ]%d\n",info,frame_cnt);
    
    sws_freeContext(img_convert_ctx);
    
    fclose(fp_yuv);
    
    av_frame_free(&pFrameYUV);
    av_frame_free(&pFrame);
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);
    
    NSString * info_ns = [NSString stringWithFormat:@"%s", info];
    //    self.infomation.text=info_ns;
}

+ (void)transcoder{
    char command_str_full[1024]={0};
    
    NSString *command_str= @"ffmpeg -i /Users/ZhenxingYao/Desktop/视音频处理技术工具/FFmpegTest/FFmpegTest/war3end.mp4 -b:v 400k -s 640x640 /Users/ZhenxingYao/Desktop/视音频处理技术工具/FFmpegTest/FFmpegTest/war3end.mov";
    NSArray *argv_array=[command_str componentsSeparatedByString:(@" ")];
    int argc=argv_array.count;
    char** argv=(char**)malloc(sizeof(char*)*argc);
    for(int i=0;i<argc;i++)
    {
        argv[i]=(char*)malloc(sizeof(char)*1024);
        strcpy(argv[i],[[argv_array objectAtIndex:i] UTF8String]);
    }
    
//    ffmpegmain(argc, argv);
    
    for(int i=0;i<argc;i++)
        free(argv[i]);
    free(argv);
}
+ (void)pushstream{
    
    char input_str_full[500]={0};
    char output_str_full[500]={0};
    
    NSString *input_str= @"war3end.mp4";
    NSString *input_nsstr=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:input_str];
    
    sprintf(input_str_full,"%s",[input_nsstr UTF8String]);
    sprintf(output_str_full,"%s",[@"rtmp://localhost:1935/rtmplive/room" UTF8String]);//[@"rtmp://mcs.rtmp.yy.com/newpublish/1369601551_1369601551_15013_1765646529_0?cfgid=15013_1200_800&ex_videosrc=20000&t=1517428751&secret=7bb1de685d28f696107aa5896c934adf" UTF8String]);//[@"rtmp://localhost:1935/rtmplive/room" UTF8String]);
    
    printf("Input Path:%s\n",input_str_full);
    printf("Output Path:%s\n",output_str_full);
    
    AVOutputFormat *ofmt = NULL;
    //Input AVFormatContext and Output AVFormatContext
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    AVPacket pkt;
    char in_filename[500]={0};
    char out_filename[500]={0};
    int ret, i;
    int videoindex=-1;
    int frame_index=0;
    int64_t start_time=0;
    //in_filename  = "cuc_ieschool.mov";
    //in_filename  = "cuc_ieschool.h264";
    //in_filename  = "cuc_ieschool.flv";//Input file URL
    //out_filename = "rtmp://localhost/publishlive/livestream";//Output URL[RTMP]
    //out_filename = "rtp://233.233.233.233:6666";//Output URL[UDP]
    
    strcpy(in_filename,input_str_full);
    strcpy(out_filename,output_str_full);
    
    av_register_all();
    //Network
    avformat_network_init();
    //Input
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, 0, 0)) < 0) {
        printf( "Could not open input file.");
        goto end;
    }
    if ((ret = avformat_find_stream_info(ifmt_ctx, 0)) < 0) {
        printf( "Failed to retrieve input stream information");
        goto end;
    }
    
    for(i=0; i<ifmt_ctx->nb_streams; i++)
        if(ifmt_ctx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex=i;
            break;
        }
    
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    
    //Output
    
    avformat_alloc_output_context2(&ofmt_ctx, NULL, "flv", out_filename); //RTMP
    //avformat_alloc_output_context2(&ofmt_ctx, NULL, "mpegts", out_filename);//UDP
    
    if (!ofmt_ctx) {
        printf( "Could not create output context\n");
        ret = AVERROR_UNKNOWN;
        goto end;
    }
    ofmt = ofmt_ctx->oformat;
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, in_stream->codec->codec);
        if (!out_stream) {
            printf( "Failed allocating output stream\n");
            ret = AVERROR_UNKNOWN;
            goto end;
        }
        
        ret = avcodec_copy_context(out_stream->codec, in_stream->codec);
        if (ret < 0) {
            printf( "Failed to copy context from input to output stream codec context\n");
            goto end;
        }
        out_stream->codec->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
            out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
    }
    //Dump Format------------------
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    //Open output URL
    if (!(ofmt->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf( "Could not open output URL '%s'", out_filename);
            goto end;
        }
    }
    
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        printf( "Error occurred when opening output URL\n");
        goto end;
    }
    
    start_time=av_gettime();
    while (1) {
        AVStream *in_stream, *out_stream;
        //Get an AVPacket
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0)
            break;
        //FIX：No PTS (Example: Raw H.264)
        //Simple Write PTS
        if(pkt.pts==AV_NOPTS_VALUE){
            //Write PTS
            AVRational time_base1=ifmt_ctx->streams[videoindex]->time_base;
            //Duration between 2 frames (us)
            int64_t calc_duration=(double)AV_TIME_BASE/av_q2d(ifmt_ctx->streams[videoindex]->r_frame_rate);
            //Parameters
            pkt.pts=(double)(frame_index*calc_duration)/(double)(av_q2d(time_base1)*AV_TIME_BASE);
            pkt.dts=pkt.pts;
            pkt.duration=(double)calc_duration/(double)(av_q2d(time_base1)*AV_TIME_BASE);
        }
        //Important:Delay
        if(pkt.stream_index==videoindex){
            AVRational time_base=ifmt_ctx->streams[videoindex]->time_base;
            AVRational time_base_q={1,AV_TIME_BASE};
            int64_t pts_time = av_rescale_q(pkt.dts, time_base, time_base_q);
            int64_t now_time = av_gettime() - start_time;
            if (pts_time > now_time)
                av_usleep(pts_time - now_time);
            
        }
        
        in_stream  = ifmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        /* copy packet */
        //Convert PTS/DTS
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.duration = av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;
        //Print to Screen
        if(pkt.stream_index==videoindex){
            printf("Send %8d video frames to output URL\n",frame_index);
            frame_index++;
        }
        //ret = av_write_frame(ofmt_ctx, &pkt);
        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        
        if (ret < 0) {
            printf( "Error muxing packet\n");
            break;
        }
        
        av_free_packet(&pkt);
        
    }
    //写文件尾（Write file trailer）
    av_write_trailer(ofmt_ctx);
end:
    avformat_close_input(&ifmt_ctx);
    /* close output */
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE))
        avio_close(ofmt_ctx->pb);
    avformat_free_context(ofmt_ctx);
    if (ret < 0 && ret != AVERROR_EOF) {
        printf( "Error occurred.\n");
        return;
    }
    return;
    
}
+ (void)pullstream {
    double duration = -1;
    int nRead;
    BOOL bLiveStream = true;
    int bufsize = 1024*1024*10;
    char *buf = (char *)malloc(bufsize);
    memset(buf, 0, bufsize);
    long countbufsize = 0;
    
    NSString *recvFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"receive1.flv"];
    FILE *fp = fopen([recvFilePath UTF8String],"wb");
    if (!fp) {
        RTMP_LogPrintf("Open File Error.\n");
        return;
    }
    
    RTMP *rtmp = RTMP_Alloc();
    RTMP_Init(rtmp);
    rtmp->Link.timeout = 10;
    //rtmp://cli.live.fanxing.com/live/fx_hifi_44585348
    //rtmp://cli.live.fanxing.com:80/live/fx_hifi_44585348
    //rtmp://live.hkstv.hk.lxdns.com/live/hks
    
    if (!RTMP_SetupURL(rtmp, "rtmp://live.hkstv.hk.lxdns.com/live/hks")){//rtmp://localhost:1935/rtmplive/room")){ //"rtmp://mcs.rtmp.yy.com/newpublish/1369601551_1369601551_15013_1765646529_0?cfgid=15013_1200_800&ex_videosrc=20000&t=1517428751&secret=7bb1de685d28f696107aa5896c934adf")){//"rtmp://localhost:1935/rtmplive/room")){ //"rtmp://cli.live.fanxing.com/live/fx_hifi_163049448")) {
        //香港卫视：rtmp://live.hkstv.hk.lxdns.com/live/hks
        RTMP_Log(RTMP_LOGERROR,"SetupURL Err\n");
        RTMP_Free(rtmp);
        return ;
    }
    
    if (bLiveStream) {
        rtmp->Link.lFlags |= RTMP_LF_LIVE;
    }
    
    RTMP_SetBufferMS(rtmp, 3600*1000);
    
    if(!RTMP_Connect(rtmp,NULL)) {
        RTMP_Log(RTMP_LOGERROR,"Connect Err\n");
        RTMP_Free(rtmp);
    }
    
    if(!RTMP_ConnectStream(rtmp,0)) {
        RTMP_Log(RTMP_LOGERROR,"ConnectStream Err\n");
        RTMP_Close(rtmp);
        RTMP_Free(rtmp);
    }
    
    while( (nRead = RTMP_Read(rtmp,buf,bufsize)) > 0) {
        fwrite(buf,1,nRead,fp);
        
        countbufsize+=nRead;
        RTMP_LogPrintf("Receive: %5dByte, Total: %5.2fkB\n",nRead,countbufsize*1.0/1024);
    }
    
    if(fp)
        fclose(fp);
    
    if(buf){
        free(buf);
    }
    
    if(rtmp){
        RTMP_Close(rtmp);
        RTMP_Free(rtmp);
        rtmp=NULL;
    }
    
}

int flush_VideoEncoder(AVFormatContext *fmt_ctx,unsigned int stream_index) {
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    
    while (1)
    {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_video2 (fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                     NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame){
            ret=0;
            break;
        }
        printf("Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n",enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;
}

+ (void)YUVConvertH264
{
    AVFormatContext *pFormatCtx;
    AVOutputFormat *fmt;
    AVStream *video_st;
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
    AVPacket pkt;
    uint8_t *picture_buf;
    AVFrame *pFrame;
    int picture_size;
    int y_size;
    int framecnt = 0;
    
    NSString *input_str = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"src_480x272.yuv"];//@"src_480x272.yuv"];
    
    FILE *in_file = fopen([input_str UTF8String], "rb");
    int in_w = 480,in_h = 272;
    int framenum = 100;
    const char *out_file = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"src02.h264"] UTF8String];
    
    av_register_all();
    
    pFormatCtx = avformat_alloc_context();
    
    fmt = av_guess_format(NULL, out_file, NULL);
    
    pFormatCtx->oformat = fmt;
    
    if (avio_open(&pFormatCtx->pb, out_file, AVIO_FLAG_READ_WRITE) < 0) {
        printf("Failed to open output file! \n");
        return ;
    }
    
    video_st = avformat_new_stream(pFormatCtx, 0);
    video_st->time_base.num = 1;
    video_st->time_base.den = 25;
    
    if (video_st == NULL) {
        return;
    }
    
    pCodecCtx = video_st->codec;
    pCodecCtx->codec_id = fmt->video_codec;
    pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    pCodecCtx->pix_fmt = PIX_FMT_YUV420P;
    pCodecCtx->width = in_w;
    pCodecCtx->height = in_h;
    pCodecCtx->time_base.num = 1;
    pCodecCtx->time_base.den = 25;
    pCodecCtx->bit_rate = 400000;
    pCodecCtx->gop_size = 250;
    
    pCodecCtx->qmin = 10;
    pCodecCtx->qmax = 51;
    pCodecCtx->max_b_frames = 3;
    
    AVDictionary *param = 0;
    if (pCodecCtx->codec_id == AV_CODEC_ID_H264) {
        av_dict_set(&param, "preset", "slow", 0);
        av_dict_set(&param, "tune", "zerolatency", 0);
    }
    
    if (pCodecCtx->codec_id == AV_CODEC_ID_H265) {
        av_dict_set(&param, "preset", "ultrafast", 0);
        av_dict_set(&param, "tune", "zero-latency", 0);
    }
    
    av_dump_format(pFormatCtx, 0, out_file, 1);
    
    pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
    if (!pCodec) {
        printf("Can not find encoder ! \n");
        return;
    }
    
    if (avcodec_open2(pCodecCtx, pCodec, &param) < 0) {
        printf("Failed to open encoder! \n");
        return;
    }
    
    pFrame = av_frame_alloc();
    picture_size = avpicture_get_size(pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    picture_buf = (uint8_t *)av_malloc(picture_size);
    avpicture_fill((AVPicture *)pFrame, picture_buf, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    avformat_write_header(pFormatCtx, NULL);
    av_new_packet(&pkt, picture_size);
    
    y_size = pCodecCtx->width * pCodecCtx->height;
    
    for (int i = 0; i < framenum; i++) {
        if (fread(picture_buf, 1, y_size * 3 / 2, in_file) <= 0) {
            printf("Failed to read raw data ! \n");
            return;
        } else if (feof(in_file)) {
            break;
        }
        pFrame->data[0] = picture_buf;
        pFrame->data[1] = picture_buf + y_size;
        pFrame->data[2] = picture_buf + y_size*5/4;
        
        pFrame->pts = i;
        int got_picture = 0;
        int ret = avcodec_encode_video2(pCodecCtx, &pkt, pFrame, &got_picture);
        if (ret < 0) {
            printf("Failed to encode! \n");
            return;
        }
        if (got_picture == 1) {
            printf("Succeed to encode frame:%5d\tsize:%5d\n",framecnt,pkt.size);
            framecnt++;
            pkt.stream_index = video_st->index;
            ret = av_write_frame(pFormatCtx, &pkt);
            av_free_packet(&pkt);
        }
        
    }
    
    int ret  = flush_VideoEncoder(pFormatCtx,0);
    if (ret < 0) {
        printf("Flushing encoder failed\n");
        return;
    }
    
    av_write_trailer(pFormatCtx);
    if (video_st) {
        avcodec_close(video_st->codec);
        av_free(pFrame);
        av_free(picture_buf);
    }
    
    avio_close(pFormatCtx->pb);
    avformat_free_context(pFormatCtx);
    
    fclose(in_file);
}


//视频解码器
+ (void)H264converteYUV
{
    //    AVFormatContext *pFormatCtx;
    int i, videoindex,audioindex;
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
    AVFrame *pFrame,*pFrameYUV;
    AVPacket *packet;
    
    struct SwsContext *img_convert_ctx;
    
    NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"src02.h264"];//@"CheeziPuffs.mov"];
    NSString *outFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"11.yuv"];
    
    NSString *outFilePathY = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"11y.y"];
    NSString *outFilePathU = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"11u.y"];
    NSString *outFilePathV = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"11v.y"];
    
    FILE *fp = fopen([filePath UTF8String],"rb");
    
    av_register_all();
    avformat_network_init();
    
    /*查找 H264 CODEC*/
    pCodec = avcodec_find_decoder(CODEC_ID_H264);
    
    if (!pCodec)
    {
        return ;
    }
    
   pCodecCtx = avcodec_alloc_context3(pCodec);
    
    if(!pCodecCtx)
    {
        return;
    }
    
    int in_w = 320,in_h = 240;
    int framenum = 1000;

    
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        return;
    }
    
//        pCodecCtx = video_st->codec;
//        pCodecCtx->codec_id = fmt->video_codec;
    pCodecCtx->pix_fmt = PIX_FMT_YUV420P;
    pCodecCtx->width = in_w;
    pCodecCtx->height = in_h;
    pCodecCtx->time_base.num = 1;
    pCodecCtx->time_base.den = 25;
    pCodecCtx->bit_rate = 400000;
    pCodecCtx->gop_size = 250;

    pCodecCtx->qmin = 10;
    pCodecCtx->qmax = 51;
    pCodecCtx->max_b_frames = 3;
    
    FILE *fp_yuv = fopen([outFilePath UTF8String], "wb+");
    FILE *fp_y = fopen([outFilePathY UTF8String], "wb+");
    FILE *fp_u = fopen([outFilePathU UTF8String], "wb+");
    FILE *fp_v = fopen([outFilePathV UTF8String], "wb+");
    
    
    
    int dstWidth = pCodecCtx->width;
    int dstHeight = pCodecCtx->height;
    enum AVPixelFormat dstPixfmt = PIX_FMT_YUV444P;
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt, dstWidth, dstHeight, dstPixfmt, SWS_BICUBIC, NULL, NULL, NULL);
    
    packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    
    int ret,got_picture;
    pFrame = av_frame_alloc();
    
    pFrameYUV = av_frame_alloc();
    int size = avpicture_get_size(dstPixfmt, dstWidth, dstHeight);
    uint8_t *out_buffer = (uint8_t *)av_malloc(size);
    avpicture_fill((AVPicture *)pFrameYUV, out_buffer, dstPixfmt, dstWidth, dstHeight);
    got_picture = 1;
    while (1) {
        //           int nalLen = getNextNal(inp_file, Buf);
        //        if (packet->stream_index == videoindex) {
        ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
        if (got_picture>0) {
            
            int h = sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0,
                              pCodecCtx->height, pFrameYUV->data, pFrameYUV->linesize);
            
            fwrite(pFrameYUV->data[0],1,dstWidth*dstHeight,fp_yuv);
            fwrite(pFrameYUV->data[1],1,dstWidth*dstHeight,fp_yuv);
            fwrite(pFrameYUV->data[2],1,dstWidth*dstHeight,fp_yuv);
            
            
            fwrite(pFrameYUV->data[0], 1, dstWidth*dstHeight, fp_y);
            fwrite(pFrameYUV->data[1], 1, dstWidth*dstHeight, fp_u);
            fwrite(pFrameYUV->data[2], 1, dstWidth*dstHeight, fp_v);
        }else{
            break;
        }
        av_free_packet(packet);
    }
    
    fclose(fp);
    fclose(fp_yuv);
    fclose(fp_y);
    fclose(fp_u);
    fclose(fp_v);
    avcodec_close(pCodecCtx);
    //    avformat_close_input(&pFormatCtx);
}


+ (int)mp3ConvertPCM{
    AVFormatContext *pFormatCtx;
    int             i, audioStream;
    AVCodecContext  *pCodecCtx;
    AVCodec         *pCodec;
    AVPacket        *packet;
    uint8_t         *out_buffer;
    AVFrame         *pFrame;
    int ret;
    uint32_t len = 0;
    int got_picture;
    int index = 0;
    int64_t in_channel_layout;
    struct SwrContext *au_convert_ctx;
    
    FILE *pFile=fopen([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testMp3.pcm"] UTF8String], "wb");
    char* url=[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"林俊杰-背对背拥抱.mp3"] UTF8String];
    
    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    //Open
    if(avformat_open_input(&pFormatCtx,url,NULL,NULL)!=0){
        printf("Couldn't open input stream.\n");
        return -1;
    }
    // Retrieve stream information
    if(avformat_find_stream_info(pFormatCtx,NULL)<0){
        printf("Couldn't find stream information.\n");
        return -1;
    }
    // Dump valid information onto standard error
    av_dump_format(pFormatCtx, 0, url, false);
    
    // Find the first audio stream
    audioStream=-1;
    for(i=0; i < pFormatCtx->nb_streams; i++)
        if(pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_AUDIO){
            audioStream=i;
            break;
        }
    
    if(audioStream==-1){
        printf("Didn't find a audio stream.\n");
        return -1;
    }
    
    // Get a pointer to the codec context for the audio stream
    pCodecCtx=pFormatCtx->streams[audioStream]->codec;
    
    // Find the decoder for the audio stream
    pCodec=avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec==NULL){
        printf("Codec not found.\n");
        return -1;
    }
    
    // Open codec
    if(avcodec_open2(pCodecCtx, pCodec,NULL)<0){
        printf("Could not open codec.\n");
        return -1;
    }
    
    packet=(AVPacket *)av_malloc(sizeof(AVPacket));
    av_init_packet(packet);
    
    //Out Audio Param
    uint64_t out_channel_layout=AV_CH_LAYOUT_STEREO;
    //nb_samples: AAC-1024 MP3-1152
    int out_nb_samples=pCodecCtx->frame_size;
    enum AVSampleFormat out_sample_fmt=AV_SAMPLE_FMT_S16;
    int out_sample_rate=44100;
    int out_channels=av_get_channel_layout_nb_channels(out_channel_layout);
    //Out Buffer Size
    int out_buffer_size=av_samples_get_buffer_size(NULL,out_channels ,out_nb_samples,out_sample_fmt, 1);
    
    out_buffer=(uint8_t *)av_malloc(MAX_AUDIO_FRAME_SIZE*2);
    pFrame=av_frame_alloc();
    
    //FIX:Some Codec's Context Information is missing
    in_channel_layout=av_get_default_channel_layout(pCodecCtx->channels);
    //Swr
    au_convert_ctx = swr_alloc();
    au_convert_ctx=swr_alloc_set_opts(au_convert_ctx,out_channel_layout, out_sample_fmt, out_sample_rate,
                                      in_channel_layout,pCodecCtx->sample_fmt , pCodecCtx->sample_rate,0, NULL);
    swr_init(au_convert_ctx);
    
    while(av_read_frame(pFormatCtx, packet)>=0){
        if(packet->stream_index==audioStream){
            
            ret = avcodec_decode_audio4( pCodecCtx, pFrame,&got_picture, packet);
            if ( ret < 0 ) {
                printf("Error in decoding audio frame.\n");
                return -1;
            }
            if ( got_picture > 0 ){
                swr_convert(au_convert_ctx,&out_buffer, MAX_AUDIO_FRAME_SIZE,(const uint8_t **)pFrame->data , pFrame->nb_samples);
                
                printf("index:%5d\t pts:%lld\t packet size:%d\n",index,packet->pts,packet->size);
                //Write PCM
                fwrite(out_buffer, 1, out_buffer_size, pFile);
                index++;
            }
        }
        av_free_packet(packet);
    }
    
    swr_free(&au_convert_ctx);
    
    fclose(pFile);
    
    av_free(out_buffer);
    // Close the codec
    avcodec_close(pCodecCtx);
    // Close the video file
    avformat_close_input(&pFormatCtx);
    return 0;
}

+ (int)pcmConvertMp3{
    AVFormatContext* pFormatCtx;
    AVOutputFormat* fmt;
    AVStream* audio_st;
    AVCodecContext* pCodecCtx;
    AVCodec* pCodec;
    
    uint8_t* frame_buf;
    AVFrame* pFrame;
    AVPacket pkt;
    
    int got_frame=0;
    int ret=0;
    int size=0;
    
    FILE *in_file=NULL;                         //Raw PCM data
    int framenum=1000;                          //Audio frame number
    const char* out_file = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjm.aac"] UTF8String];          //Output URL
    int i;
    
    in_file= fopen([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjm.pcm"] UTF8String], "rb");
    
    av_register_all();
    
    //Method 1.
    pFormatCtx = avformat_alloc_context();
    fmt = av_guess_format(NULL, out_file, NULL);
    pFormatCtx->oformat = fmt;
    
    
    //Method 2.
    //avformat_alloc_output_context2(&pFormatCtx, NULL, NULL, out_file);
    //fmt = pFormatCtx->oformat;
    
    //Open output URL
    if (avio_open(&pFormatCtx->pb,out_file, AVIO_FLAG_READ_WRITE) < 0){
        printf("Failed to open output file!\n");
        return -1;
    }
    
    audio_st = avformat_new_stream(pFormatCtx, 0);
    if (audio_st==NULL){
        return -1;
    }
    pCodecCtx = audio_st->codec;
    pCodecCtx->codec_id = fmt->audio_codec;
    pCodecCtx->codec_type = AVMEDIA_TYPE_AUDIO;
    pCodecCtx->sample_fmt = AV_SAMPLE_FMT_S16;
    pCodecCtx->sample_rate= 44100;
    pCodecCtx->channel_layout=AV_CH_LAYOUT_STEREO;
    pCodecCtx->channels = av_get_channel_layout_nb_channels(pCodecCtx->channel_layout);
    pCodecCtx->bit_rate = 64000;
    
    //Show some information
    av_dump_format(pFormatCtx, 0, out_file, 1);
    
    pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
    if (!pCodec){
        printf("Can not find encoder!\n");
        return -1;
    }
    if (avcodec_open2(pCodecCtx, pCodec,NULL) < 0){
        printf("Failed to open encoder!\n");
        return -1;
    }
    pFrame = av_frame_alloc();
    pFrame->nb_samples= pCodecCtx->frame_size;
    pFrame->format= pCodecCtx->sample_fmt;
    
    size = av_samples_get_buffer_size(NULL, pCodecCtx->channels,pCodecCtx->frame_size,pCodecCtx->sample_fmt, 1);
    frame_buf = (uint8_t *)av_malloc(size);
    avcodec_fill_audio_frame(pFrame, pCodecCtx->channels, pCodecCtx->sample_fmt,(const uint8_t*)frame_buf, size, 1);
    
    //Write Header
    avformat_write_header(pFormatCtx,NULL);
    
    av_new_packet(&pkt,size);
    
    for (i=0; i<framenum; i++){
        //Read PCM
        if (fread(frame_buf, 1, size, in_file) <= 0){
            printf("Failed to read raw data! \n");
            return -1;
        }else if(feof(in_file)){
            break;
        }
        pFrame->data[0] = frame_buf;  //PCM Data
        
        pFrame->pts=i*100;
        got_frame=0;
        //Encode
        ret = avcodec_encode_audio2(pCodecCtx, &pkt,pFrame, &got_frame);
        if(ret < 0){
            printf("Failed to encode!\n");
            return -1;
        }
        if (got_frame==1){
            printf("Succeed to encode 1 frame! \tsize:%5d\n",pkt.size);
            pkt.stream_index = audio_st->index;
            ret = av_write_frame(pFormatCtx, &pkt);
            av_free_packet(&pkt);
        }
    }
    
    //Flush Encoder
    ret = flush_encoder(pFormatCtx,0);
    if (ret < 0) {
        printf("Flushing encoder failed\n");
        return -1;
    }
    
    //Write Trailer
    av_write_trailer(pFormatCtx);
    
    //Clean
    if (audio_st){
        avcodec_close(audio_st->codec);
        av_free(pFrame);
        av_free(frame_buf);
    }
    avio_close(pFormatCtx->pb);
    avformat_free_context(pFormatCtx);
    
    fclose(in_file);
    
    return 0;
}
int flush_encoder(AVFormatContext *fmt_ctx,unsigned int stream_index){
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_audio2 (fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                     NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame){
            ret=0;
            break;
        }
        printf("Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n",enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;
}
@end
