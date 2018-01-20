//
//  AudioUnitRecord.m
//  FFmpegTest
//
//  Created by 姚振兴 on 16/7/6.
//  Copyright © 2016年 kugou. All rights reserved.
//
// setup a global iosAudio variable, accessible everywhere
//extern AudioUnitRecord* iosAudio;
#import "AudioUnitRecord.h"
#import <AudioToolbox/AudioToolbox.h>
//#import "faac.h"
#define kOutputBus 0
#define kInputBus 1

AudioUnitRecord* iosAudio;
FILE *pFile;

void checkStatus(int status){
    if (status) {
        printf("Status not 0! %d/n", status);
        //        exit(1);
    }
}

/**
 This callback is called when new audio data from the microphone is
 available.
 */
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    
    AudioBuffer buffer;
    OSStatus status;
    buffer.mDataByteSize = inNumberFrames *2;
    buffer.mNumberChannels = 1;
    buffer.mData= malloc(inNumberFrames *2);
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    status = AudioUnitRender([iosAudio audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    [iosAudio processAudio:&bufferList];
    NSLog(@"%u", (unsigned int)bufferList.mBuffers[0].mDataByteSize);
    //    NSLog(@"%@", bufferList.mBuffers[0].mData);
    
    
    fwrite(bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize,1 , pFile);
    fflush(pFile);
    free(bufferList.mBuffers[0].mData);
    
    return noErr;
}

/**
 This callback is called when the audioUnit needs new data to play through the
 speakers. If you don't have any, just don't write anything in the buffers
 */

@implementation AudioUnitRecord
@synthesize audioUnit, tempBuffer;

/**
 Initialize the audioUnit and allocate our own temporary buffer.
 The temporary buffer will hold the latest data coming in from the microphone,
 and will be copied to the output when this is requested.
 */
- (id) init {
    self = [super init];
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *Pathes = path.lastObject;
    NSString *filePath = [Pathes stringByAppendingPathComponent:@"testaudio5.pcm"];
    const char *str = [filePath UTF8String];
    pFile = fopen(str, "w");
    
    
    
    OSStatus status;
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status);
    
    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    //    // Enable IO for playback
    //    status = AudioUnitSetProperty(audioUnit,
    //                                  kAudioOutputUnitProperty_EnableIO,
    //                                  kAudioUnitScope_Output,
    //                                  kOutputBus,
    //                                  &flag,
    //                                  sizeof(flag));
    //    checkStatus(status);
    
    // Describe format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate            = 44100.00;
    audioFormat.mFormatID            = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame    = 1;
    audioFormat.mBitsPerChannel        = 16;
    audioFormat.mBytesPerPacket        = 2;
    audioFormat.mBytesPerFrame        = 2;
    
    // Apply format
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    //    status = AudioUnitSetProperty(audioUnit,
    //                                  kAudioUnitProperty_StreamFormat,
    //                                  kAudioUnitScope_Input,
    //                                  kOutputBus,
    //                                  &audioFormat,
    //                                  sizeof(audioFormat));
    //    checkStatus(status);
    
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Set output callback
    //    callbackStruct.inputProc = playbackCallback;
    //    callbackStruct.inputProcRefCon = self;
    //    status = AudioUnitSetProperty(audioUnit,
    //                                  kAudioUnitProperty_SetRenderCallback,
    //                                  kAudioUnitScope_Global,
    //                                  kOutputBus,
    //                                  &callbackStruct,
    //                                  sizeof(callbackStruct));
    //    checkStatus(status);
    
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    flag = 0;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    
    // Allocate our own buffers (1 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
    // Practice learns the buffers used contain 512 frames, if this changes it will be fixed in processAudio.
    tempBuffer.mNumberChannels = 1;
    tempBuffer.mDataByteSize = 512 * 2;
    tempBuffer.mData = malloc( 512 * 2 );
    
    // Initialise
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
    
    return self;
}

/**
 Start the audioUnit. This means data will be provided from
 the microphone, and requested for feeding to the speakers, by
 use of the provided callbacks.
 */
- (void) start {
    OSStatus status = AudioOutputUnitStart(audioUnit);
    checkStatus(status);
}

/**
 Stop the audioUnit
 */
- (void) stop {
    OSStatus status = AudioOutputUnitStop(audioUnit);
    checkStatus(status);
    
    
}

/**
 Change this funtion to decide what is done with incoming
 audio data from the microphone.
 Right now we copy it to our own temporary buffer.
 */
- (void) processAudio: (AudioBufferList*) bufferList{
    AudioBuffer sourceBuffer = bufferList->mBuffers[0];
    
    // fix tempBuffer size if it's the wrong size
    if (tempBuffer.mDataByteSize != sourceBuffer.mDataByteSize) {
        free(tempBuffer.mData);
        tempBuffer.mDataByteSize = sourceBuffer.mDataByteSize;
        tempBuffer.mData = malloc(sourceBuffer.mDataByteSize);
    }
    // copy incoming audio data to temporary buffer
    memcpy(tempBuffer.mData, bufferList->mBuffers[0].mData, bufferList->mBuffers[0].mDataByteSize);
}

- (void) dealloc {
//    [super dealloc];
    AudioUnitUninitialize(audioUnit);
    free(tempBuffer.mData);
}
@end
