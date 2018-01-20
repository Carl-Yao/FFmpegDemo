//#import "DDH264Decoder.h"
//
//
//
//@interface DDH264Decoder ()
//{
//    AVCodecParserContext *avParserContext;
//    AVPacket avpkt;            //数据包结构体
//    AVFrame *m_pRGBFrame;    //帧对象
//    AVFrame *m_pYUVFrame;    //帧对象
//    AVCodec *pCodecH264;    //解码器
//    AVCodecContext *c;        //解码器数据结构对象
//    uint8_t *yuv_buff;      //yuv图像数据区
//    uint8_t *rgb_buff;        //rgb图像数据区
//    struct SwsContext *scxt;        //图像格式转换对象
//    uint8_t *filebuf;        //读入文件缓存
//    uint8_t *outbuf;        //解码出来视频数据缓存
//    int nDataLen;            //rgb图像数据区长度
//    FILE *fp_yuv;
//    //    IplImage* img;            //OpenCV图像显示对象
//    
//    uint8_t *pbuf;            //用以存放帧数据
//    int nOutSize;            //用以记录帧数据长度
//    int haveread;            //用以记录已读buf长度
//    int decodelen;            //解码器返回长度
//    int piclen;                //解码器返回图片长度
//    int piccount; //输出图片计数
//}
//
//@end
//
//@implementation DDH264Decoder
//
//void Ffmpeg_Decoder_Init()
//{
//    avcodec_register_all();     //注册编解码器
//    av_init_packet(&self.avpkt);     //初始化包结构
//    self.m_pRGBFrame = new AVFrame[1];//RGB帧数据赋值
//    self.m_pYUVFrame = avcodec_alloc_frame();
//    filebuf = new uint8_t[1024 * 1024];//初始化文件缓存数据区
//    pbuf = new uint8_t[200 * 1024];//初始化帧数据区
//    yuv_buff = new uint8_t[200 * 1024];//初始化YUV图像数据区
//    rgb_buff = new uint8_t[1024 * 1024];//初始化RGB图像帧数据区
//    pCodecH264 = avcodec_find_decoder(CODEC_ID_H264);     //查找h264解码器
//    if (!pCodecH264)
//    {
//        fprintf(stderr, "h264 codec not found\n");
//        exit(1);
//    }
//    avParserContext = av_parser_init(CODEC_ID_H264);
//    if (!pCodecH264)return;
//    c = avcodec_alloc_context3(pCodecH264);//函数用于分配一个AVCodecContext并设置默认值，如果失败返回NULL，并可用av_free()进行释放
//
//    if (pCodecH264->capabilities&CODEC_CAP_TRUNCATED)
//    c->flags |= CODEC_FLAG_TRUNCATED;    /* we do not send complete frames */
//    if (avcodec_open2(c, pCodecH264, NULL) < 0)return;
//    nDataLen = 0;
//}
//void Ffmpeg_Decoder_Show(AVFrame *pFrame, int width, int height)
//{
////    CvSize  rectangle_img_size;
////    rectangle_img_size.height = height;
////    rectangle_img_size.width = width;
////
////    img = cvCreateImage(rectangle_img_size, IPL_DEPTH_8U, 3);
////    uchar* imgdata = (uchar*)(img->imageData);     //图像的数据指针
////
////    for (int y = 0; y<height; y++)
////    {
////        memcpy(imgdata + y*width * 3, pFrame->data[0] + y*pFrame->linesize[0], width * 3);
////    }
////    cvShowImage("解码图像", img);
////    cvWaitKey(1);//可以将图像停留时间设的长点以便观察
////    cvReleaseImage(&img);
////    imgdata = NULL;
//}
//void Ffmpeg_YUV_Decoder_Show(AVFrame *pFrame, int dstWidth, int dstHeight)
//{
//    fwrite(pFrame->data[0],1,dstWidth*dstHeight,fp_yuv);
//    fwrite(pFrame->data[1],1,dstWidth*dstHeight,fp_yuv);
//    fwrite(pFrame->data[2],1,dstWidth*dstHeight,fp_yuv);
//
//
////    fwrite(pFrame->data[0], 1, dstWidth*dstHeight, fp_y);
////    fwrite(pFrame->data[1], 1, dstWidth*dstHeight, fp_u);
////    fwrite(pFrame->data[2], 1, dstWidth*dstHeight, fp_v);
//}
//void Ffmpeg_Decoder_Close()
//{
//    delete[]filebuf;
//    delete[]pbuf;
//    delete[]yuv_buff;
//    delete[]rgb_buff;
//    av_free(m_pYUVFrame);//释放帧资源
//    avcodec_close(c);//关闭解码器
//    av_free(c);
//}
////后面是主函数部分，因为通常解码都是从文件中读取数据流或者从网络中得到数据缓存，所以出于方便和操作性本人把解码的部分代码写在了主函数中
//
//void h264ConvertYuv(char *inFile, char *outFile)
//{
//    Ffmpeg_Decoder ffmpegobj;
//    ffmpegobj.Ffmpeg_Decoder_Init();//初始化解码器
//    FILE *pf = NULL;
//    pf = fopen(inFile, "rb");
//    ffmpegobj.fp_yuv = fopen(outFile, "wb+");
//    while (true)
//    {
//        ffmpegobj.nDataLen = fread(ffmpegobj.filebuf, 1, 1024 * 10, pf);//读取文件数据
//        if (ffmpegobj.nDataLen<=0)
//        {
//            fclose(pf);
//            break;
//        }
//        else
//        {
//            ffmpegobj.haveread = 0;
//            while (ffmpegobj.nDataLen > 0)
//            {
//                int nLength = av_parser_parse2(ffmpegobj.avParserContext, ffmpegobj.c, &ffmpegobj.yuv_buff,
//                                               &ffmpegobj.nOutSize, ffmpegobj.filebuf + ffmpegobj.haveread, ffmpegobj.nDataLen, 0, 0, 0);//查找帧头
//                ffmpegobj.nDataLen -= nLength;//查找过后指针移位标志
//                ffmpegobj.haveread += nLength;
//                if (ffmpegobj.nOutSize <= 0)
//                {
//                    continue;
//                }
//                ffmpegobj.avpkt.size = ffmpegobj.nOutSize;//将帧数据放进包中
//                ffmpegobj.avpkt.data = ffmpegobj.yuv_buff;
//                while (ffmpegobj.avpkt.size > 0)
//                {
//                    ffmpegobj.decodelen = avcodec_decode_video2(ffmpegobj.c, ffmpegobj.m_pYUVFrame, &ffmpegobj.piclen, &ffmpegobj.avpkt);//解码
//                    if (ffmpegobj.decodelen < 0)
//                    {
//                        break;
//                    }
//                    if (ffmpegobj.piclen)
//                    {
//                        ffmpegobj.scxt = sws_getContext(ffmpegobj.c->width, ffmpegobj.c->height, ffmpegobj.c->pix_fmt, ffmpegobj.c->width, ffmpegobj.c->height, PIX_FMT_BGR24, SWS_POINT, NULL, NULL, NULL);//初始化格式转换函数
//                        if (ffmpegobj.scxt!= NULL)
//                        {
//                            avpicture_fill((AVPicture*)ffmpegobj.m_pRGBFrame, (uint8_t*)ffmpegobj.rgb_buff, PIX_FMT_RGB24, ffmpegobj.c->width, ffmpegobj.c->height);//将rgb_buff填充到m_pRGBFrame
//                            if (avpicture_alloc((AVPicture *)ffmpegobj.m_pRGBFrame, PIX_FMT_RGB24, ffmpegobj.c->width, ffmpegobj.c->height) >= 0)
//                            {
//                                sws_scale(ffmpegobj.scxt, ffmpegobj.m_pYUVFrame->data, ffmpegobj.m_pYUVFrame->linesize, 0,
//                                          ffmpegobj.c->height, ffmpegobj.m_pRGBFrame->data, ffmpegobj.m_pRGBFrame->linesize);
//                                ffmpegobj.Ffmpeg_YUV_Decoder_Show(ffmpegobj.m_pYUVFrame, ffmpegobj.c->width, ffmpegobj.c->height);//解码图像显示
//                            }
//                            sws_freeContext(ffmpegobj.scxt);//释放格式转换器资源
//                            avpicture_free((AVPicture *)ffmpegobj.m_pRGBFrame);//释放帧资源
//                            av_free_packet(&ffmpegobj.avpkt);//释放本次读取的帧内存
//                        }
//                    }
//                    ffmpegobj.avpkt.size -= ffmpegobj.decodelen;
//                    ffmpegobj.avpkt.data += ffmpegobj.decodelen;
//                }
//            }
//        }
//    }
//    ffmpegobj.Ffmpeg_Decoder_Close();//关闭解码器
//}
//@end
//
