//
//  MyAudioApi.h
//  myaudio
//
//  Created by user on 16/9/23.
//  Copyright © 2016年 user. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <wushuangtech/ExternalAudioModule.h>

@protocol AudioFileMixStatusDelegate <NSObject>

- (void)OnReportAudioFileEof;
- (void)OnReportAudioFileDuration:(int)duration;
- (void)OnReportAudioFilePlayedSeconds:(int)seconds;

@end


/**
 *  音频外部处理代理，由调用方实现
 */
@protocol ExtAudioProcessDelegate <NSObject>

/*
 * 采集到的pcm数据，用于加入音效或伴奏等
 * @param data pcm数据
 * @param len 数据长度
 * @param samplingFreq 采样率
 * @param isStereo YES-stereo, NO-mono
 */
-(void) onRecordAudioData:(char*)data len:(int)len samplingFreq:(int)samplingFreq isStereo:(bool)isStereo;
/*
 * 即将播放的pcm数据，用于加入音效或伴奏等
 * @param data pcm数据
 * @param len 数据长度
 * @param samplingFreq 采样率
 * @param isStereo YES-stereo, NO-mono
 */
-(void) onPlaybackAudioData:(char*)data len:(int)len samplingFreq:(int)samplingFreq isStereo:(bool)isStereo;

@end

@interface MyAudioApi : NSObject <ExternalAudioModuleDelegate>


+(MyAudioApi*) sharedInstance;

-(void) setAudioFileMixStatusDelegate:(id<AudioFileMixStatusDelegate>)delegate;
-(BOOL) startAudioFileMixing:(const char *)localfile loopback:(BOOL)loopback loopTimes:(int)loopTimes;
-(void) stopAudioFileMixing;
-(void) pauseAudioFileMixing;
-(void) resumeAudioFileMixing;
-(void) seekAudioFileTo:(int)seconds;
-(void) adjustAudioSoloVolumeScale:(float)scale;
-(void) adjustAudioFileVolumeScale:(float)scale;

/*
 * 设置外部音频处理回调代理对象
 * @param delegate 代理对象
 */
-(void) setExternalAudioProcessDelegate:(id<ExtAudioProcessDelegate>)delegate;

/*
 * 开启采集的外部处理
 * 当开启后开始回调ExtAudioProcessDelegate上的onRecordAudioData
 */
-(BOOL) startRecordMix;
/*
 * 停止采集的外部处理
 * 当开启后停止回调ExtAudioProcessDelegate上的onRecordAudioData
 */
-(BOOL) stopRecordMix;

/*
 * 开启播放的外部处理
 * 当开启后开始回调ExtAudioProcessDelegate上的onPlaybackAudioData
 */
-(BOOL) startPlaybackMix;
/*
 * 停止播放的外部处理
 * 当开启后停止回调ExtAudioProcessDelegate上的onPlaybackAudioData
 */
-(BOOL) stopPlaybackMix;

/*
 * 获取开始退路到当前采集的数据总量
 */
-(int) getAudioCaptureDataSize;

/*
 * 获取开始推流到当前编码的数据总量
 */
-(int) getAudioEncodeDataSize;

/*
 * 获取接收到解码后的数据总量
 */
-(int) getAudioDecodedDataSize;

-(int) getAudioEncodeFrameCount;
-(int) getAudioDecodeFrameCount;

/*
 * 麦克风静音
 * @param mute 是否静音麦克风
 */
-(void) muteMic:(BOOL)mute;

// ExternalAudioModuleDelegate, 不要使用
-(BOOL) startAudioCapture;
-(BOOL) stopAudioCapture;
-(BOOL) startAudioPlay;
-(BOOL) stopAudioPlay;
-(void) receiveAudioData:(void*)data len:(int)len;

@end
