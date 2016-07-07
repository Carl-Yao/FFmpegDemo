//
//  AudioUnitRecord.h
//  FFmpegTest
//
//  Created by 姚振兴 on 16/7/6.
//  Copyright © 2016年 kugou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif

@interface AudioUnitRecord : NSObject{
    AudioComponentInstance audioUnit;
    AudioBuffer tempBuffer; // this will hold the latest data from the microphone
}
@property (readonly) AudioComponentInstance audioUnit;
@property (readonly) AudioBuffer tempBuffer;

- (void) start;
- (void) stop;
- (void) processAudio: (AudioBufferList*) bufferList;


@end
