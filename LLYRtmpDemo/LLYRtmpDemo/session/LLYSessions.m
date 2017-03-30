//
//  LLYSessions.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYSessions.h"
#import "LLYRtmpConfig.h"
#import "LLYRtmpSession.h"
#import "LLYVideoPackager.h"
#import "LLYVideoOutputHandler.h"
#import "LLYVideoEncode.h"

#define NOW (CACurrentMediaTime()*1000)


@interface LLYSessions ()<LLYRtmpSessionDelegate,LLYVideoPackagerDelegate,LLYVideoSessionDelegate>
{
    uint64_t _startTime;
    /**
     *  是否可以发送数据
     */
    BOOL     _sendable;
}

@property (nonatomic,strong) LLYRtmpSession *rtmpSession;
@property (nonatomic,strong) LLYVideoPackager *videoPackage;

@end


@implementation LLYSessions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _status = LLYSessionStateNone;
        _sendable = NO;
    }
    return self;
}

- (void)dealloc{

    [self endSession];
    
    self.delegate = nil;
}


- (uint64_t)currentTimestamp{
    return NOW - _startTime;
}

+ (instancetype)defultSession{

    LLYSessions *sessions = [[LLYSessions alloc]init];
    return sessions;
}

- (LLYVideoSession *)videoSession{

    if (!_videoSession) {
        _videoSession = [LLYVideoSession defaultSession];
        _videoSession.delegate = self;
        _videoSession.videoConfig = [LLYVideoConfig defaultConfig];
        
        [self.videoSession.videoOutputHandler startVideoCapture];
    }
    return _videoSession;
}


- (UIView *)preView{

    if (!_preView) {
        _preView = [[UIView alloc]init];
        [_preView setValue:self.videoSession.videoOutputHandler.preLayer forKey:@"_layer"];
    }
    return _preView;
}


- (LLYVideoPackager *)videoPackage{

    if (!_videoPackage) {
        _videoPackage = [[LLYVideoPackager alloc]init];
        _videoPackage.delegate = self;
    }
    return _videoPackage;
}

- (LLYRtmpSession *)rtmpSession{

    if (!_rtmpSession) {
        _rtmpSession = [[LLYRtmpSession alloc]init];
        _rtmpSession.delegate = self;
        _rtmpSession.currentActor = self.currentActor;
        
        LLYRtmpConfig *config = [[LLYRtmpConfig alloc] init];
        config.url = self.url;
        config.width = self.videoSession.videoConfig.videoSize.width;
        config.height = self.videoSession.videoConfig.videoSize.height;
        config.frameDuration = 1.0 / self.videoSession.videoConfig.fps;
        config.videoBitrate = self.videoSession.videoConfig.bitrate;
        _rtmpSession.config = config;
        
       
//        config.audioSampleRate = self.audioConfig.sampleRate;
//        config.stereo = self.audioConfig.channels == 2;
    }
    return _rtmpSession;
}


- (void)startSession{

    [self.rtmpSession connect];
}

- (void)endSession{

    _status = LLYSessionStateEnd;
    _sendable = NO;
    
    [self.rtmpSession disConnect];
    [self.videoPackage reset];
    
    if ([self.delegate respondsToSelector:@selector(sessions:statusDidChanged:)]) {
        [self.delegate sessions:self statusDidChanged:_status];
    }
}


#pragma mark - rtmp delegate
- (void)rtmpSession:(LLYRtmpSession *)rtmpSession didChangeStatus:(LLYRtmpSessionStatus)rtmpStatus{

    switch (rtmpStatus) {
        case LLYRtmpSessionStatusConnected:
        {
            _status = LLYSessionStateConnecting;
        }
            break;
        case LLYRtmpSessionStatusSessionStarted:
        {
            _startTime = NOW;
            _sendable = YES;
            _status = LLYSessionStateConnected;
        }
            
            break;
        case LLYRtmpSessionStatusNotConnected:
        {
            _status = LLYSessionStateEnd;
            [self endSession];
        }
            break;
        case LLYRtmpSessionStatusError:
        {
            _status = LLYSessionStateError;
            [self endSession];
        }
            break;
            
        case LLYRtmpSessionStatusSessionStartPlay:
        {
//            _status = LLYSessionStateConnected;
            
        }
            break;
        default:
            break;
    }
    
    if ([self.delegate respondsToSelector:@selector(sessions:statusDidChanged:)]) {
        [self.delegate sessions:self statusDidChanged:_status];
    }
}

- (void)videOutputHandler:(LLYVideoOutputHandler *)handler didOutputSampleBuffer:(CVPixelBufferRef)pixelBuffer{

    if (!_sendable || self.currentActor == LLYAudienceActor) {
        return;
    }
    
    [self.videoSession.videoEncode videoEncodeData:pixelBuffer time:self.currentTimestamp];
}

- (void)videoEncode:(LLYVideoEncode *)encode sps:(NSData *)sps pps:(NSData *)pps time:(uint64_t)time{

    if (!_sendable || self.currentActor == LLYAudienceActor) {
        return;
    }
    [self.videoPackage packageKeyFrameSps:sps pps:pps timestamp:time];
}
- (void)videoEncode:(LLYVideoEncode *)encode frame:(NSData *)frame time:(uint64_t)time isKeyFrame:(BOOL)isKeyFrame{

    if (!_sendable || self.currentActor == LLYAudienceActor) {
        return;
    }
    [self.videoPackage packageFrame:frame timestamp:time isKeyFrame:isKeyFrame];
}

- (void)videoPackage:(LLYVideoPackager *)package didPacketFrame:(LLYFrame *)frame{

    if (!_sendable || self.currentActor == LLYAudienceActor) {
        return;
    }
    if (_rtmpSession) {
        [_rtmpSession sendBuffer:frame];
    }
}

- (void)rtmpSession:(LLYRtmpSession *)rtmpSession receiveVideoData:(uint8_t *)data length:(int)length{

    if (self.delegate && [self.delegate respondsToSelector:@selector(sessions:receiveVideoData:length:)]) {
        [self.delegate sessions:self receiveVideoData:data length:length];
    }
}
@end
