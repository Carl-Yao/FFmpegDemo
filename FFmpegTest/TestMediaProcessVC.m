//
//  TestMediaProcessVC.m
//  FFmpegTest
//
//  Created by 姚振兴 on 16/4/29.
//  Copyright © 2016年 kugou. All rights reserved.
//

#import "TestMediaProcessVC.h"
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libswscale/swscale.h>
#import <libavfilter/avfilter.h>
#import <libavutil/time.h>
#import <libavutil/mathematics.h>
#import <libavutil/opt.h>
#import <librtmp/rtmp.h>
#import <librtmp/log.h>
#import <AudioToolbox/AudioToolbox.h>



#define QUEUE_BUFFER_SIZE 4 //队列缓冲个数
#define MIN_SIZE_PER_FRAME 2000 //每侦最小数据长度

@implementation TestMediaProcessVC
{
    AudioStreamBasicDescription audioDescription;
    AudioQueueRef audioQueue;
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE];
    NSLock *synlock;
}

static void AudioPlayerAQInputCallback(void *input, AudioQueueRef inQ, AudioQueueBufferRef outQB);

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    
    int data_size = av_sample_fmt_is_planar(AV_SAMPLE_FMT_S32);
    int byte = av_get_bytes_per_sample(AV_SAMPLE_FMT_S32);
    
    synlock = [[NSLock alloc] init];
    
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

- (void)YUVConvertH264
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
    
    NSString *input_str = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.yuv"];//@"src_480x272.yuv"];
    
    FILE *in_file = fopen([input_str UTF8String], "rb");
    int in_w = 320,in_h = 240;
    int framenum = 1000;
    const char *out_file = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"src01.h264"] UTF8String];
    
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

int flush_AudioEncoder(AVFormatContext *fmt_ctx,unsigned int stream_index) {
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
        ret = avcodec_encode_audio2(fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                    NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame){
            ret = 0;
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

- (void)PCMConvertAAC
{
    AVFormatContext *pFormatCtx;
    AVOutputFormat *fmt;
    AVStream *audio_st;
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
    
    uint8_t *frame_buf;
    AVFrame *pFrame;
    AVPacket pkt;
    
    int got_frame=0;
    int ret=0;
    int size=0;
    
    FILE *in_file=NULL;                         //Raw PCM data
    int framenum=1800;                          //Audio frame number
    NSString *outFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjm.aac"];
    const char* out_file = [outFilePath UTF8String];          //Output URL
    int i;
    
    NSString *inputFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjm.pcm"];
    in_file = fopen([inputFilePath UTF8String],"rb");
    
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
        return ;
    }
    
    audio_st = avformat_new_stream(pFormatCtx, 0);
    if (audio_st == NULL) {
        return ;
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
        return ;
    }
    ret = avcodec_open2(pCodecCtx, pCodec,NULL);
    if (ret < 0){
        printf("Failed to open encoder!\n");
        return ;
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
            return ;
        } else if(feof(in_file)) {
            break;
        }
        pFrame->data[0] = frame_buf;  //PCM Data
        
        pFrame->pts=i*100;
        got_frame=0;
        //Encode
        ret = avcodec_encode_audio2(pCodecCtx, &pkt,pFrame, &got_frame);
        if(ret < 0) {
            printf("Failed to encode!\n");
            return ;
        }
        if (got_frame==1) {
            printf("Succeed to encode 1 frame! \tsize:%5d\n",pkt.size);
            pkt.stream_index = audio_st->index;
            ret = av_write_frame(pFormatCtx, &pkt);
            av_free_packet(&pkt);
        }
    }
    
    //Flush Encoder
    ret = flush_AudioEncoder(pFormatCtx,0);
    if (ret < 0) {
        printf("Flushing encoder failed\n");
        return ;
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
}

//视频解码器
- (void)MOVconverteYUV
{
    AVFormatContext *pFormatCtx;
    int i, videoindex,audioindex;
    AVCodecContext *pCodecCtx,*pAudioCodecCtx;
    AVCodec *pCodec,*pAudioCodec;
    AVFrame *pFrame,*pFrameYUV;
    AVPacket *packet;
    
    struct SwsContext *img_convert_ctx;
    
    NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"IMG_1841.MOV"];//@"CheeziPuffs.mov"];
    NSString *outFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"11.yuv"];
    
    NSString *outFilePathY = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"11y.y"];
    NSString *outFilePathU = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"11u.y"];
    NSString *outFilePathV = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"11v.y"];
    
    FILE *fp = fopen([filePath UTF8String],"rb");
    
    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    
    if (avformat_open_input(&pFormatCtx, [filePath UTF8String], NULL, NULL) != 0) {
        return;
    }
    
    if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
        return;
    }
    
    
    videoindex = -1;
    for (i = 0; i < pFormatCtx->nb_streams; i++)
    {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            videoindex = i;
            break;
        }
    }
    
    audioindex = -1;
    for (i = 0; i < pFormatCtx->nb_streams; i++)
    {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO)
        {
            audioindex = i;
            break;
        }
    }
    
    if (videoindex == -1 ) {
        return;
    }
    
    pCodecCtx = pFormatCtx->streams[videoindex]->codec;
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    //
    //    pAudioCodecCtx = pFormatCtx->streams[audioindex]->codec;
    //    pAudioCodec = avcodec_find_decoder(pAudioCodecCtx->codec_id);
    
    if (pCodec == NULL) {
        return;
    }
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        return;
    }
    
    //    if (avcodec_open2(pAudioCodecCtx, pAudioCodec, NULL) < 0) {
    //        return;
    //    }
    
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
    
    while (av_read_frame(pFormatCtx, packet) >= 0) {
        if (packet->stream_index == videoindex) {
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
            }
        } else {
            //            ret = avcodec_decode_audio4(pAudioCodecCtx, pFrame, &got_picture, packet);
            //            int data_size = av_samples_get_buffer_size(NULL, pAudioCodecCtx->channels, pFrame->nb_samples, pAudioCodecCtx->sample_fmt, 1);
            //            if (got_picture>0) {
            //               fwrite(pFrame->data[0],1,pFrame->linesize[0],fp_yuv);
            //               //fwrite(pFrame->data[1],1,pFrame->linesize[0],fp_yuv);
            //               //fwrite(pFrame->data[1],1,pFrame->linesize[0],fp_yuv);
            //            }
        }
        av_free_packet(packet);
    }
    
    fclose(fp);
    fclose(fp_yuv);
    fclose(fp_y);
    fclose(fp_u);
    fclose(fp_v);
    //avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);
    
    
}


- (void)pullRTMPStream {
    double duration = -1;
    int nRead;
    BOOL bLiveStream = true;
    int bufsize = 1024*1024*10;
    char *buf = (char *)malloc(bufsize);
    memset(buf, 0, bufsize);
    long countbufsize = 0;
    
    NSString *recvFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"receive.flv"];
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
    
    if (!RTMP_SetupURL(rtmp, "rtmp://cli.live.fanxing.com/live/fx_hifi_163049448")) {
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


//-(void)initAudio
//{
//    ///设置音频参数
//    audioDescription.mSampleRate = 44100;//采样率
//    audioDescription.mFormatID = kAudioFormatLinearPCM;
//    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
//    audioDescription.mChannelsPerFrame = 1;///单声道
//    audioDescription.mFramesPerPacket = 1;//每一个packet一侦数据
//    audioDescription.mBitsPerChannel = 16;//每个采样点16bit量化
//    audioDescription.mBytesPerFrame = (audioDescription.mBitsPerChannel/8) * audioDescription.mChannelsPerFrame;
//    audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame ;
//    ///创建一个新的从audioqueue到硬件层的通道
//    //  AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &audioQueue);///使用当前线程播
//    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, self, nil, nil, 0, &audioQueue);//使用player的内部线程播
//    ////添加buffer区
//    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
//    {
//        int result =  AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
//        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d",i,result);
//    }
//}

-(void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB
{
    //    [synlock lock];
    //    int readLength = fread(pcmDataBuffer, 1, EVERY_READ_LENGTH, file);//读取文件
    //    NSLog(@"read raw data size = %d",readLength);
    //    outQB->mAudioDataByteSize = readLength;
    //    Byte *audiodata = (Byte *)outQB->mAudioData;
    //    for(int i=0;i<readLength;i++)
    //    {
    //        audiodata[i] = pcmDataBuffer[i];
    //    }
    //    /*
    //     将创建的buffer区添加到audioqueue里播放
    //     AudioQueueBufferRef用来缓存待播放的数据区，AudioQueueBufferRef有两个比较重要的参数，AudioQueueBufferRef->mAudioDataByteSize用来指示数据区大小，AudioQueueBufferRef->mAudioData用来保存数据区
    //     */
    //    AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
    //    [synlock unlock];
}

-(void)checkUsedQueueBuffer:(AudioQueueBufferRef) qbuf
{
    if(qbuf == audioQueueBuffers[0])
    {
        NSLog(@"AudioPlayerAQInputCallback,bufferindex = 0");
    }
    if(qbuf == audioQueueBuffers[1])
    {
        NSLog(@"AudioPlayerAQInputCallback,bufferindex = 1");
    }
    if(qbuf == audioQueueBuffers[2])
    {
        NSLog(@"AudioPlayerAQInputCallback,bufferindex = 2");
    }
    if(qbuf == audioQueueBuffers[3])
    {
        NSLog(@"AudioPlayerAQInputCallback,bufferindex = 3");
    }
}


@end
