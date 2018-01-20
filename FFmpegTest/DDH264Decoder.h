#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>

#include <libavutil/mathematics.h>
#include <libavutil/time.h>

#import <librtmp/rtmp.h>
#import <librtmp/log.h>

@interface DDH264Decoder : NSObject

void Ffmpeg_Decoder_Init();//初始化
void Ffmpeg_Decoder_Show(AVFrame *pFrame, int width, int height);//显示图片
void Ffmpeg_Decoder_Close();//关闭
void Ffmpeg_YUV_Decoder_Show(AVFrame *pFrame, int width, int height);
void h264ConvertYuv(char *inFile, char *outFile);
@end
