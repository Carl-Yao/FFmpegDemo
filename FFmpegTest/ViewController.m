//
//  ViewController.m
//  FFmpegTest
//
//  Created by xiaogch on 15/12/3.
//  Copyright © 2015年 kugou. All rights reserved.
//

#import "ViewController.h"

//#import "VideoPictureManager.h"
//#import "audioPCMManager.h"
#import "MediaPlayer.h"
#import "MediaManager.h"
#import "AudioPlayerViewController.h"

/**
 * Split Y, U, V planes in YUV420P file.
 * @param url  Location of Input YUV file.
 * @param w    Width of Input YUV file.
 * @param h    Height of Input YUV file.
 * @param num  Number of frames to process.
 *
 */
int simplest_yuv420_split(char *url,char *urlY,char *urlU,char *urlV, int w, int h,int num);
int simplest_rgb24_split(char *url,char *urlR,char *urlG,char *urlB, int w, int h,int num);
int simplest_rgb24_to_yuv420(char *url_in, int w, int h,int num,char *url_out);
int simplest_pcm32le_split(char *url, char *outUrl_L,char *outUrl_R);
int simplest_h264_parser(char *url);
int simplest_flv_parser(char *url,char *outputFlv,char *outputMp3);
int h264ConvertYuv(char *inFile, char *outFile);
int simplest_aac_parser(char *url);
int simplest_mp3_parser(char *inFile);

@interface ViewController ()
{
    NSLock *synlock;
}
@end

@implementation ViewController

- (void)actionPlay {
    //    [self pullRTMPStream];
    
    //    [self test];
    //    NSString *outFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"11.yuv"];
    //    simplest_yuv444_split([outFilePath UTF8String], 1920, 1080, 1);
    MediaPlayer *pl = [[MediaPlayer alloc] init];
    [self presentViewController:pl animated:YES completion:nil];
}
- (void)actionPlayVoice {
    MediaPlayer *pl = [[MediaPlayer alloc] init];
    [self presentViewController:pl animated:YES completion:nil];
}
- (void)viewDidLoad {
    
    [super viewDidLoad];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.backgroundColor = [UIColor redColor];
    btn.frame = CGRectMake(0, 444, 100, 50);
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"播放视频" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(actionPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn1.backgroundColor = [UIColor redColor];
    btn1.frame = CGRectMake(100, 444, 100, 50);
    [btn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn1 setTitle:@"播放音频" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(actionPlayVoice) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn2.backgroundColor = [UIColor redColor];
    btn2.frame = CGRectMake(100, 174, 100, 50);
    [btn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn2 setTitle:@"视频解码" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(clickDecodeButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
    
//    UIButton *btn3 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    btn3.backgroundColor = [UIColor redColor];
//    btn3.frame = CGRectMake(200, 390, 100, 50);
//    [btn3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [btn3 setTitle:@"视频转码" forState:UIControlStateNormal];
//    [btn3 addTarget:self action:@selector(clickTranscoderButton) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:btn3];
    
    UIButton *btn4 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn4.backgroundColor = [UIColor redColor];
    btn4.frame = CGRectMake(0, 70, 100, 50);
    [btn4 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn4 setTitle:@"视频推流" forState:UIControlStateNormal];
    [btn4 addTarget:self action:@selector(clickPushStreamButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn4];
    
    UIButton *btn5 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn5.backgroundColor = [UIColor redColor];
    btn5.frame = CGRectMake(100, 70, 100, 50);
    [btn5 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn5 setTitle:@"RTMP解协议" forState:UIControlStateNormal];
    [btn5 addTarget:self action:@selector(clickPullStreamButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn5];
    
    UIButton *btn8 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn8.backgroundColor = [UIColor redColor];
    btn8.frame = CGRectMake(0, 336, 100, 50);
    [btn8 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn8 setTitle:@"RGB转YUV" forState:UIControlStateNormal];
    [btn8 addTarget:self action:@selector(clickRGBToYUVButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn8];
    
    UIButton *btn9 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn9.backgroundColor = [UIColor redColor];
    btn9.frame = CGRectMake(0, 282, 100, 50);
    [btn9 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn9 setTitle:@"RGB分解" forState:UIControlStateNormal];
    [btn9 addTarget:self action:@selector(clickRGBPlitButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn9];
    
    UIButton *btn10 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn10.backgroundColor = [UIColor redColor];
    btn10.frame = CGRectMake(100, 282, 100, 50);
    [btn10 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn10 setTitle:@"YUV分解" forState:UIControlStateNormal];
    [btn10 addTarget:self action:@selector(clickYUVPlitButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn10];
    
    UIButton *btn11 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn11.backgroundColor = [UIColor redColor];
    btn11.frame = CGRectMake(100, 336, 100, 50);
    [btn11 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn11 setTitle:@"PCM处理" forState:UIControlStateNormal];
    [btn11 addTarget:self action:@selector(clickPCMButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn11];
    
    UIButton *btn20 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn20.backgroundColor = [UIColor redColor];
    btn20.frame = CGRectMake(0, 390, 100, 50);
    [btn20 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn20 setTitle:@"视频编码" forState:UIControlStateNormal];
    [btn20 addTarget:self action:@selector(clickYUVToH264Button) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn20];
    
    UIButton *btn21 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn21.backgroundColor = [UIColor redColor];
    btn21.frame = CGRectMake(0, 174, 100, 50);
    [btn21 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn21 setTitle:@"H264分解" forState:UIControlStateNormal];
    [btn21 addTarget:self action:@selector(clickH264Button) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn21];
    
    
    UIButton *btn31 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn31.backgroundColor = [UIColor redColor];
    btn31.frame = CGRectMake(0, 500, 100, 50);
    [btn31 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn31 setTitle:@"音频demo" forState:UIControlStateNormal];
    [btn31 addTarget:self action:@selector(clickAudioButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn31];
    
    UIButton *btn41 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn41.backgroundColor = [UIColor redColor];
    btn41.frame = CGRectMake(0, 122, 100, 50);
    [btn41 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn41 setTitle:@"FLV解封装" forState:UIControlStateNormal];
    [btn41 addTarget:self action:@selector(clickFlvSplitButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn41];
    
    
    UIButton *btn51 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn51.backgroundColor = [UIColor redColor];
    btn51.frame = CGRectMake(0, 230, 100, 50);
    [btn51 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn51 setTitle:@"mp3分解" forState:UIControlStateNormal];
    [btn51 addTarget:self action:@selector(clickMP3SplitButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn51];
    
    UIButton *btn52 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn52.backgroundColor = [UIColor redColor];
    btn52.frame = CGRectMake(100, 230, 100, 50);
    [btn52 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn52 setTitle:@"mp3解码" forState:UIControlStateNormal];
    [btn52 addTarget:self action:@selector(clickMp3DecodeButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn52];
    
    UIButton *btn53 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn53.backgroundColor = [UIColor redColor];
    btn53.frame = CGRectMake(100, 390, 100, 50);
    [btn53 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn53 setTitle:@"音频编码" forState:UIControlStateNormal];
    [btn53 addTarget:self action:@selector(clickPcmEncodeButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn53];
}
- (IBAction)clickDecodeButton:(id)sender {
    [MediaManager decoder];
//    [MediaManager MOVconverteYUV];
}

- (void)clickTranscoderButton{
    
}

- (void)clickPushStreamButton{
    dispatch_async(dispatch_get_global_queue(0, 0), ^(){
        [MediaManager pushstream];
    });
}

- (void)clickPullStreamButton{
    dispatch_async(dispatch_get_global_queue(0, 0), ^(){
        [MediaManager pullstream];
    });
}

- (void)clickRGBToYUVButton
{
    simplest_rgb24_to_yuv420([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"susheview2_640x480_rgb24.rgb"] UTF8String], 640, 480,1,[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"susheview2_640x480_yuv420.yuv"] UTF8String]);
}

- (void)clickYUVPlitButton
{
//        simplest_yuv420_split( [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"lena_256x256_yuv420p.yuv"] UTF8String],
//                              [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"lena1_256x256_yuv420p.yuv"] UTF8String],
//                              [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"lena2_256x256_yuv420p.yuv"] UTF8String],
//                              [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"lena3_256x256_yuv420p.yuv"] UTF8String],256,256,1);
    simplest_yuv420_split( [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test1.yuv"] UTF8String],
                          [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testY_1920x1080yuv420p.yuv"] UTF8String],
                          [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testU_1920x1080yuv420p.yuv"] UTF8String],
                          [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testV_1920x1080yuv420p.yuv"] UTF8String],1920,1080,193);
//    simplest_yuv420_split( [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.yuv"] UTF8String],
//                          [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testY.yuv"] UTF8String],
//                          [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testU.yuv"] UTF8String],
//                          [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testV.yuv"] UTF8String],176,144,2001);
}

- (void)clickRGBPlitButton
{
    simplest_rgb24_split([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"cie1931_500x500.rgb"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"cie19312_500x500_rgb24_R.y"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"cie19312_500x500_rgb24_G.y"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"cie19312_500x500_rgb24_B.y"] UTF8String], 500, 500, 1);
}

- (void)clickPCMButton{
    simplest_pcm32le_split([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjm.pcm"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjmL.pcm"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjmR.pcm"] UTF8String]);
}

- (void)clickH264Button{
    simplest_h264_parser([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"src01.h264"] UTF8String]);//sintel.h264
}

- (void)clickFlvSplitButton{
    simplest_flv_parser([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"cuc_ieschool.flv"] UTF8String],[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"outputH264.h264"] UTF8String],[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"outputMp3.mp3"] UTF8String]);
}

- (void)clickYUVToH264Button{
    [MediaManager YUVConvertH264];
}

- (void)clickMP3SplitButton{
    simplest_mp3_parser([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"林俊杰-背对背拥抱.mp3"] UTF8String]);
}

- (void)clickMp3DecodeButton{
    [MediaManager mp3ConvertPCM];
}

- (void)clickAudioButton{
    AudioPlayerViewController *vc = [[AudioPlayerViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)clickPcmEncodeButton{
    [MediaManager pcmConvertMp3];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
