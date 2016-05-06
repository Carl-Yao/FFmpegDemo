//
//  MediaPlayer.m
//  FFmpegTest
//
//  Created by 姚振兴 on 16/4/29.
//  Copyright © 2016年 kugou. All rights reserved.
//

#import "MediaPlayer.h"
#import <MediaPlayer/MediaPlayer.h> 
@interface MediaPlayer()
@property (nonatomic,strong) MPMoviePlayerController *moviePlayer;//视频播放控制器

@end

@implementation MediaPlayer

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.moviePlayer play];
    
    [self addNotification];
    
}

-(void)dealloc{
    //移除所有通知监控
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(MPMoviePlayerController *)moviePlayer{
    if (!_moviePlayer) {
        NSString *urlStr=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:@"IMG_1841.MOV"];
//        urlStr = @"rtmp://www.velab.com.cn/live/test";
        NSURL *url=[NSURL fileURLWithPath:urlStr];
        _moviePlayer=[[MPMoviePlayerController alloc]initWithContentURL:url];
        _moviePlayer.view.frame=self.view.bounds;
        _moviePlayer.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_moviePlayer.view];
    }
    return _moviePlayer;
}

-(void)addNotification{
    NSNotificationCenter *notificationCenter=[NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(mediaPlayerPlaybackStateChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayer];
    [notificationCenter addObserver:self selector:@selector(mediaPlayerPlaybackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    
}

-(void)mediaPlayerPlaybackStateChange:(NSNotification *)notification{
    switch (self.moviePlayer.playbackState) {
        case MPMoviePlaybackStatePlaying:
            NSLog(@"正在播放...");
            break;
        case MPMoviePlaybackStatePaused:
            NSLog(@"暂停播放.");
            break;
        case MPMoviePlaybackStateStopped:
            NSLog(@"停止播放.");
            break;
        default:
            NSLog(@"播放状态:%li",self.moviePlayer.playbackState);
            break;
    }
}

-(void)mediaPlayerPlaybackFinished:(NSNotification *)notification{
    NSLog(@"播放完成.%li",self.moviePlayer.playbackState);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
