//
//  MyVideoApi.h
//  myvideo
//
//  Created by apple on 16/5/19.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <wushuangtech/ExternalVideo.h>

/// 视频采集分辨率(都是16：9 当此设备不支持当前分辨率，自动降低一级)
typedef NS_ENUM (NSUInteger, GSVideoSessionPreset){
    /// 低分辨率
    GSCaptureSessionPreset360x640 = 0,
    /// 中分辨率
    GSCaptureSessionPreset540x960 = 1,
    /// 高分辨率
    GSCaptureSessionPreset720x1280 = 2
};

typedef NS_ENUM(NSUInteger, GSImageFillModeType) {
    // 拉伸图像以填充整个视图, 这可能会使图像变形。
    GSImageFillModeStretch,
    // 如果视频尺寸与显示视窗尺寸不一致，在保持长宽比的前提下，将视频进行缩放后填满视窗。
    GSImageFillModePreserveAspectRatio,
    // 如果视频尺寸与显示视窗尺寸不一致，则视频流会按照显示视窗的比例进行周边裁剪或图像拉伸后填满视窗。
    GSImageFillModePreserveAspectRatioAndFill
};

/**
 *  视频源类型
 */
typedef NS_ENUM(NSUInteger, TTTVideoSourceType) {
    TTTVideoSourceTypeMyVideo        = 0,
    TTTVideoSourceTypeExternal       = 1,
    TTTVideoSourceTypeScreenRecorder = 2,
};

typedef struct GSVideoConfig
{
    /*
     * 视频编码分辨率，应当选用合适的采集分辨率
     */
    CGSize videoSize;
    /*
     * 视频帧率
     */
    NSUInteger videoFrameRate;
    /*
     * I帧间隔，决定一个gop内帧数的大小
     */
    NSUInteger videoMaxKeyframeInterval;
    /*
     * 视频码率,单位bps
     */
    NSUInteger videoBitRate;
    /*
     * 采集分辨率
     */
    GSVideoSessionPreset sessionPreset;
    /*
     * 是否使用前置摄像头，YES-前置摄像头， NO-后置摄像头
     */
    BOOL enableFrontCam;
    
    // 图像填充模式
    GSImageFillModeType imageFillMode;
} GSVideoConfig;

/**
 *  视频状态上报代理，由调用方实现
 */
@protocol VideoStatReportDelegate <NSObject>

//当第一次获取到远端视频数据或视频尺寸改变时触发回调
- (void)updateRemoteVideo:(NSString *)deviceID videoSize:(CGSize)videoSize;

- (void)cameraDidReady;
- (void)videoDidStop;

- (void)outputCaptured:(CVPixelBufferRef)pixelBuffer;
- (void)remoteVideoDecoded:(NSString *)deviceID pixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)firstRemoteVideoFrameDecoded:(NSString *)deviceID videoSize:(CGSize)videoSize;
- (void)firstRemoteVideoFrameRendered:(NSString *)deviceID videoSize:(CGSize)videoSize;

- (void)reportH264Sei:(NSString *)deviceID sei:(uint8_t*)sei seiSize:(int)seiSize;

@end

@protocol MyVideoApiDelegate <NSObject>

- (void)onStartSendEncodedVideoData;
- (void)onStopSendEncodedVideoData;

- (void)onStartSendDualEncodedVideoData;
- (void)onStopSendDualEncodedVideoData;

@end

@protocol MyVideoApiExternalDelegate <NSObject>

- (void)onGetEncodedData:(NSArray *)dataArray isKeyFrame:(BOOL)isKeyFrame width:(int)width height:(int)height;
- (void)onGetDualEncodedData:(NSArray *)dataArray isKeyFrame:(BOOL)isKeyFrame width:(int)width height:(int)height;

@end

@interface MyVideoApi : NSObject<ExternalVideoModuleDelegate>

@property (nonatomic, weak) id<MyVideoApiDelegate> delegate;
@property (nonatomic, weak) id<MyVideoApiExternalDelegate> externalDelegate;
@property (nonatomic, assign) TTTVideoSourceType videoSourceType;

+(MyVideoApi*) sharedInstance;

/*
 * 增加视频委托者
 * @param consignor 视频委托者（遵从“ExternalVideoProtocol”协议）
 */
- (void)addVideoConsignor:(id<ExternalVideoProtocol>)consignor;

/*
 * 移除视频委托者
 * @param consignor 视频委托者（遵从“ExternalVideoProtocol”协议）
 */
- (void)removeVideoConsignor:(id<ExternalVideoProtocol>)consignor;

/*
 * 设置视频状态上报回调代理对象
 */
-(void)setVideoStatReportDelegate:(id<VideoStatReportDelegate>)delegate;

/*
 * 获取视频参数
 * @return 视频参数
 */
-(GSVideoConfig) getVideoConfig;

/*
 * 设置视频参数
 * @param config 视频参数
 */
-(void) setVideoConfig:(GSVideoConfig)config;

/*
 * 设置播放窗口
 * 
 * @param devID       设备ID，指定显示该设备视频
 * @param imgView     视频显示控件
 * @param contentMode 图像填充模式（缺省值：UIViewContentModeScaleAspectFill）
 */

-(void) setViewForPlay:(NSString*)devID imgView:(UIImageView*)imgView;
-(void) setViewForPlay:(NSString*)devID imgView:(UIImageView*)imgView contentMode:(UIViewContentMode)contentMode;

/*
 * 设置本地视频预览窗口
 * @param view 视频显示控件
 */
-(void) setViewForCapture:(UIView*) view;

/*
 * 开启本地预览
 * 可以在推流前调用该接口预览本地视频
 */
-(void) startPreview;

/*
 * 关闭本地预览
 * 必须与startPreview成对调用。
 * 若是在推流进行中调用该函数，并不会真正停止预览，推流停止后预览真正停止
 */
-(void) stopPreview;

/*
 * 设置美颜效果
 * @param enable YES-开启美颜， NO-关闭美颜
 * @param beautyLevel: default is 0.5, between 0.0~1.0
 * @param brightLevel: default is 0.5, between 0.0~1.0
 */
-(void) setBeautyFaceStatus:(BOOL)enable beautyLevel:(CGFloat)beautyLevel brightLevel:(CGFloat)brightLevel;

/*
 * 设置水印
 *
 * 水印的大小位置以及透明度均由view自身属性制定
 */
-(void) setWaterMarkView:(UIView*) view;

/*
 * 暂停视频采集
 */
-(void) pauseVideo;
/*
 * 恢复视频采集
 */
-(void) resumeVideo;

/*
 * 开始播放远端视频
 * @param userID 远端设备ID
 */
-(BOOL) startVideoPlay:(NSString*) devID;

/*
 * 停止播放远端视频
 * @param devID 远端设备ID
 */
-(BOOL) stopVideoPlay:(NSString*) devID;

/*
 * 设置闪光灯
 * @param on YES-开启闪光灯， NO-关闭闪光灯
 */
-(void)turnTorchOn:(BOOL)on;

/*
 * 将视频帧数据编码
 * 仅当 isExternalVideoSourceEnabled 为 YES 时可用
 * @param pixelBuffer 视频帧数据
 */
- (void)encodeCaptureBuffer:(CVPixelBufferRef)pixelBuffer;

/**
 *  手动开始视频采集并编码
 *
 *  @return YES-成功 NO-失败
 */
-(BOOL)manualStartVideoCapture;

/**
 *  手动停止视频采集并编码
 *
 *  @return YES-成功 NO-失败
 */
-(BOOL)manualStopVideoCapture;

/*
 * 获取视频编码尺寸
 */
-(void) getVideoEncodeWidth:(int*)width height:(int*)height;

/*
 * 获取开始推流到当前编码的数据总量
 */
-(int) getVideoEncodeDataSize;

/*
 * 获取编码总帧数
 */
-(int)getVideoEncodeFrameCount;

/*
 * 获取开始采集到当前的总帧数
 */
-(int)getVideoCaptureFrameCount;

/*
 * 获取解码帧数
 *
 */
-(int) getVideoDecodeFrameCount;

/*
 * 获取显示帧数
 *
 */
-(int) getVideoRenderFrameCount;

/**
 获取远端视频统计信息

 @param deviceID           远端设备ID
 @param delay              延时(毫秒)
 @param width              视频流宽（像素）
 @param height             视频流高（像素）
 @param receivedDataSize   接收的数据总量
 @param receivedFrameCount 接收的总帧数
 */
- (BOOL)getRemoteVideoStats:(NSString *)deviceID delay:(int *)delay width:(int *)width height:(int *)height
           receivedDataSize:(int *)receivedDataSize receivedFrameCount:(int *)receivedFrameCount;

/**
 * 向 h.264 码流中插入sei
 *
 * @param content sei中payload信息
 */
- (void)inserH264SeiContent:(NSString*)content;

@end
