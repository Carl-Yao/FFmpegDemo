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
    btn.frame = CGRectMake(100, 100, 100, 50);
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"播放视频" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(actionPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn1.backgroundColor = [UIColor redColor];
    btn1.frame = CGRectMake(200, 100, 100, 50);
    [btn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn1 setTitle:@"播放音频" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(actionPlayVoice) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn2.backgroundColor = [UIColor redColor];
    btn2.frame = CGRectMake(0, 100, 100, 50);
    [btn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn2 setTitle:@"视频解码" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(clickDecodeButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
    
    UIButton *btn3 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn3.backgroundColor = [UIColor redColor];
    btn3.frame = CGRectMake(0, 150, 100, 50);
    [btn3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn3 setTitle:@"视频转码" forState:UIControlStateNormal];
    [btn3 addTarget:self action:@selector(clickTranscoderButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn3];
    
    UIButton *btn4 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn4.backgroundColor = [UIColor redColor];
    btn4.frame = CGRectMake(100, 150, 100, 50);
    [btn4 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn4 setTitle:@"视频推流" forState:UIControlStateNormal];
    [btn4 addTarget:self action:@selector(clickPushStreamButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn4];
    
    UIButton *btn5 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn5.backgroundColor = [UIColor redColor];
    btn5.frame = CGRectMake(200, 150, 100, 50);
    [btn5 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn5 setTitle:@"拉视频流" forState:UIControlStateNormal];
    [btn5 addTarget:self action:@selector(clickPullStreamButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn5];
    
    UIButton *btn8 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn8.backgroundColor = [UIColor redColor];
    btn8.frame = CGRectMake(100, 250, 100, 50);
    [btn8 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn8 setTitle:@"RGB转YUV" forState:UIControlStateNormal];
    [btn8 addTarget:self action:@selector(clickRGBToYUVButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn8];
    
    UIButton *btn9 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn9.backgroundColor = [UIColor redColor];
    btn9.frame = CGRectMake(0, 250, 100, 50);
    [btn9 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn9 setTitle:@"RGB分解" forState:UIControlStateNormal];
    [btn9 addTarget:self action:@selector(clickRGBPlitButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn9];
    
    UIButton *btn10 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn10.backgroundColor = [UIColor redColor];
    btn10.frame = CGRectMake(0, 300, 100, 50);
    [btn10 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn10 setTitle:@"YUV分解" forState:UIControlStateNormal];
    [btn10 addTarget:self action:@selector(clickYUVPlitButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn10];
    
    UIButton *btn11 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn11.backgroundColor = [UIColor redColor];
    btn11.frame = CGRectMake(100, 300, 100, 50);
    [btn11 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn11 setTitle:@"PCM处理" forState:UIControlStateNormal];
    [btn11 addTarget:self action:@selector(clickPCMButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn11];
}
- (IBAction)clickDecodeButton:(id)sender {
    [MediaManager decoder];
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
    simplest_yuv420_split( [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.yuv"] UTF8String],
                          [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testY.y"] UTF8String],
                          [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testU.y"] UTF8String],
                          [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"testV.y"] UTF8String],1920,1080,193);
}

- (void)clickRGBPlitButton
{
    simplest_rgb24_split([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"susheview2_640x480_rgb24.rgb"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"susheview2_640x480_rgb24_R.y"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"susheview2_640x480_rgb24_G.y"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"susheview2_640x480_rgb24_B.y"] UTF8String], 640, 480, 1);
}

- (void)clickPCMButton{
    simplest_pcm32le_split([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjm.pcm"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjmL.pcm"] UTF8String], [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tdjmR.pcm"] UTF8String]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
