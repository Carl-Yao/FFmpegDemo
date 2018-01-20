//
//  MediaManager.h
//  FFmpegTest
//
//  Created by 姚振兴 on 16/5/6.
//  Copyright © 2016年 kugou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MediaManager : NSObject
+ (void)decoder;
+ (void)transcoder;
+ (void)pushstream;
+ (void)pullstream;
+ (void)YUVConvertH264;
+ (void)H264converteYUV;
+ (int)mp3ConvertPCM;
+ (int)pcmConvertMp3;
@end
