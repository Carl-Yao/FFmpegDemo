//
//  AudioPlayer.m
//  FFmpegTest
//
//  Created by 姚振兴 on 16/6/13.
//  Copyright © 2016年 kugou. All rights reserved.
//

#import "AudioPlayerViewController.h"
//#import "AVAudioPlayer.h"
#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVAudioRecorder.h>
#import "playAudio.h"
#import "AudioUnitRecord.h"

@implementation AudioPlayerViewController{
    AVAudioPlayer *newPlayer;
    AVAudioRecorder *recorder;
    BOOL isRecord;
    playAudio *audio;
    AudioUnitRecord* record;
}
- (void)viewDidLoad {
    
    [super viewDidLoad];
    isRecord = YES;
    // Provide a nice background for the app user interface.
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.backgroundColor = [UIColor redColor];
    btn.frame = CGRectMake(0, 100, 180, 50);
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"SystemSoundServices" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(systemSoundPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn1.backgroundColor = [UIColor redColor];
    btn1.frame = CGRectMake(180, 100, 100, 50);
    [btn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn1 setTitle:@"AVAudioPlay" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(AVAudioPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn2.backgroundColor = [UIColor redColor];
    btn2.frame = CGRectMake(0, 200, 180, 50);
    [btn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn2 setTitle:@"Audio Queue Services" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(AudioQueueServices) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
    
    UIButton *btn3 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn3.backgroundColor = [UIColor redColor];
    btn3.frame = CGRectMake(0, 300, 180, 50);
    [btn3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn3 setTitle:@"AVAudioRecord" forState:UIControlStateNormal];
    [btn3 addTarget:self action:@selector(record) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn3];
    
    UIButton *btn4 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn4.backgroundColor = [UIColor redColor];
    btn4.frame = CGRectMake(200, 300, 180, 50);
    [btn4 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn4 setTitle:@"AudioUnitRecord" forState:UIControlStateNormal];
    [btn4 addTarget:self action:@selector(unitRecord) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn4];
}
- (void)systemSoundPlay{
    
    SystemSoundID soundFileObject;
    NSString *soundPath = [[NSBundle mainBundle]pathForResource:@"tap" ofType:@"aif"];
    NSURL *soundURL =[NSURL fileURLWithPath:soundPath];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundFileObject);
    // Play the audio
    AudioServicesPlayAlertSound(soundFileObject);
}

- (void)AVAudioPlay{
    NSString *soundFilePath =
    [[NSBundle mainBundle] pathForResource: @"林俊杰-背对背拥抱"
                                    ofType: @"mp3"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    newPlayer =
    [[AVAudioPlayer alloc] initWithContentsOfURL: fileURL
                                           error: nil];
    
    [newPlayer prepareToPlay];
    
//    [newPlayer setDelegate: self];
    newPlayer.numberOfLoops = -1;    // Loop playback until invoke stop method
    [newPlayer play];
}

- (void)AudioQueueServices{
    NSString *soundFilePath =
    [[NSBundle mainBundle] pathForResource: @"林俊杰-背对背拥抱"
                                    ofType: @"mp3"];
    audio= [[playAudio alloc]initWithAudio:soundFilePath];
}

- (void)record{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString* savePath = [docDir stringByAppendingString:@"/testRecord.aac"];
    
    NSURL *url=[NSURL fileURLWithPath:savePath];
    
    if (!isRecord) {
        isRecord = YES;
        [recorder stop];
        
        newPlayer =
        [[AVAudioPlayer alloc] initWithContentsOfURL: url
                                               error: nil];
        
        [newPlayer prepareToPlay];
        
        //    [newPlayer setDelegate: self];
        newPlayer.numberOfLoops = -1;    // Loop playback until invoke stop method
        [newPlayer play];
        return;
    }
    isRecord = NO;
    NSDictionary *settings=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey, [NSNumber numberWithFloat:22050.0], AVSampleRateKey, [NSNumber numberWithInt:1], AVNumberOfChannelsKey, nil];
    NSError *error;
    recorder=[[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (error)
        NSLog(@"%@", [error description]);
    [recorder prepareToRecord];
    [recorder record];
}

- (void)unitRecord{
    if (!record) {
        record = [[AudioUnitRecord alloc] init];

    }
    if (!isRecord) {
        isRecord = YES;
        [record stop];
    }else{
        isRecord = NO;
        [record start];
    }
    
}
@end
