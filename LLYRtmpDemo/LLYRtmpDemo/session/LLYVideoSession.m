//
//  LLYVideoSession.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYVideoSession.h"
#import "LLYVideoOutputHandler.h"
#import "LLYVideoEncode.h"

#define NOW (CACurrentMediaTime()*1000)

@interface LLYVideoSession ()<LLYVideoEncodeDelegate,LLYVideoOutputDelegate>
{
    NSFileHandle *_fileHandle;
}

@end

@implementation LLYVideoSession

+ (instancetype)defaultSession{

    LLYVideoSession *session = [[LLYVideoSession alloc]init];
    return session;
}

- (instancetype)init{

    if(self=[super init]){
        
        NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"LLY.h264"];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    return self;
}

- (void)dealloc{

    NSLog(@"%@ 已销毁",NSStringFromClass([self class]));
    
}

- (void)setVideoConfig:(LLYVideoConfig *)videoConfig{

    _videoConfig = videoConfig;
    
    self.videoOutputHandler.config = videoConfig;
    self.videoEncode.videoConfig = videoConfig;
    
}


- (LLYVideoOutputHandler *)videoOutputHandler{

    if (!_videoOutputHandler) {
        _videoOutputHandler = [[LLYVideoOutputHandler alloc]init];
        _videoOutputHandler.delegate = self;
    }
    return _videoOutputHandler;
}

- (LLYVideoEncode *)videoEncode{

    if (!_videoEncode) {
        _videoEncode = [[LLYVideoEncode alloc]init];
        _videoEncode.delegate = self;
    }
    return _videoEncode;
}

#pragma mark - LLYVideoEncodeDelegate
- (void)videoEncode:(LLYVideoEncode *)encode sps:(NSData *)sps pps:(NSData *)pps time:(uint64_t)time{

    NSLog(@"gotSpsPps %d %d", (int)[sps length], (int)[pps length]);
//    const char bytes[] = "\x00\x00\x00\x01";
//    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
//    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
//    [_fileHandle writeData:byteHeader];
//    [_fileHandle writeData:sps];
//    [_fileHandle writeData:byteHeader];
//    [_fileHandle writeData:pps];
    
    if ([self.delegate respondsToSelector:@selector(videoEncode:sps:pps:time:)]) {
        [self.delegate videoEncode:encode sps:sps pps:pps time:time];
    }
    
}
- (void)videoEncode:(LLYVideoEncode *)encode frame:(NSData *)frame time:(uint64_t)time isKeyFrame:(BOOL)isKeyFrame{


    NSLog(@"gotEncodedData %d", (int)[frame length]);
    
//    const char bytes[] = "\x00\x00\x00\x01";
//    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
//    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
//    [_fileHandle writeData:byteHeader];
//    [_fileHandle writeData:frame];
    
    if ([self.delegate respondsToSelector:@selector(videoEncode:frame:time:isKeyFrame:)]) {
        [self.delegate videoEncode:encode frame:frame time:time isKeyFrame:isKeyFrame];
    }
}

#pragma mark - LLYVideoOutputDelegate
- (void)videOutputHandler:(LLYVideoOutputHandler *)handler didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{

    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    if ([self.delegate respondsToSelector:@selector(videOutputHandler:didOutputSampleBuffer:)]) {
        [self.delegate videOutputHandler:handler didOutputSampleBuffer:pixelBufferRef];
    }
    
//    [self.videoEncode videoEncodeData:sampleBuffer time:NOW];
    
}

@end
