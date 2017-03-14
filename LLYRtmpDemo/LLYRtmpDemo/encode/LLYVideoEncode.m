//
//  LLYVideoEncode.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYVideoEncode.h"

@interface LLYVideoEncode ()
{
    VTCompressionSessionRef _compressionSession;
    NSInteger frameCount;
}

@end

@implementation LLYVideoEncode

- (void)stopVideoEncode{

    if (_compressionSession) {
        VTCompressionSessionCompleteFrames(_compressionSession, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_compressionSession);
        CFRelease(_compressionSession);
        _compressionSession = NULL;
    }
}

- (void)setVideoConfig:(LLYVideoConfig *)videoConfig{

    _videoConfig = videoConfig;
    
    [self initCompressionSession];
    
}

- (void)initCompressionSession{
    
//    [self stopVideoEncode];
    
    OSStatus status = VTCompressionSessionCreate(NULL, _videoConfig.videoSize.width, _videoConfig.videoSize.height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressBuffer, (__bridge void *)self, &_compressionSession);
    if(status != noErr){
        return;
    }
    //关键帧间隔 一般为帧率的2倍 间隔越大 压缩比越高
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval,(__bridge CFTypeRef)@(_videoConfig.keyframeInterval));
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration,(__bridge CFTypeRef)@(_videoConfig.keyframeInterval));
    
    
    //Just remember that kVTCompressionPropertyKey_AverageBitRate takes bits and kVTCompressionPropertyKey_DataRateLimits takes bytes and seconds.
//    status = VTSessionSetProperty(session, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(600 * 1024));
//    status = VTSessionSetProperty(session, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[800 * 1024 / 8, 1]);
    //码率 单位是bit
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(_videoConfig.bitrate * 8));
    
    //码率上限 单位为 byte/s
    NSArray *limit = @[@(_videoConfig.bitrate),@(1)];
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(_videoConfig.fps));

    // 设置实时编码输出（避免延迟）
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanFalse);
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_ProfileLevel,  kVTProfileLevel_H264_Baseline_AutoLevel);
    
    //控制是否产生B帧
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    //16:9
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_AspectRatio16x9, kCFBooleanTrue);
    
    VTCompressionSessionPrepareToEncodeFrames(_compressionSession);

}

//开始编码
- (void)videoEncodeData:(CVPixelBufferRef)pixelBuffer time:(uint64_t)time{

    frameCount++;
    
    //CMTimeMake(a,b) a当前第几帧，b每秒钟多少帧。当前播放时间a/b
    CMTime presentationTimeStamp = CMTimeMake(frameCount, 1000);
    
    //每一帧需要播放的时间
    VTEncodeInfoFlags flags;
    CMTime duration = CMTimeMake(1, _videoConfig.fps);
    
    NSDictionary *properties = nil;
    if(frameCount % (int32_t)(self.videoConfig.keyframeInterval) == 0){//强制关键帧
        properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
    }
    
    NSNumber *timeNumber = @(time);
     OSStatus statusCode = VTCompressionSessionEncodeFrame(_compressionSession, pixelBuffer, presentationTimeStamp, duration, (__bridge CFDictionaryRef)properties, (__bridge void *)timeNumber, &flags);
    
    if (statusCode != noErr) {
        NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
        
        VTCompressionSessionInvalidate(_compressionSession);
        CFRelease(_compressionSession);
        _compressionSession = NULL;
        return;
    }
    
    NSLog(@"H264: VTCompressionSessionEncodeFrame Success");
}


//编码完成的回调
static void didCompressBuffer(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer){

    LLYVideoEncode *videoEncode = (__bridge LLYVideoEncode *)VTref;
    uint64_t timeStamp = [((__bridge_transfer NSNumber*)VTFrameRef) longLongValue];
    
    //编码后的原始数据
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, false);
    
    //判断关键帧
    BOOL isKeyFrame = NO;
    if (attachments != NULL) {
        CFDictionaryRef attachment;
        CFBooleanRef dependsOnOthers;
        attachment = (CFDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        dependsOnOthers = (CFBooleanRef)CFDictionaryGetValue(attachment, kCMSampleAttachmentKey_DependsOnOthers);
        isKeyFrame = (dependsOnOthers == kCFBooleanFalse);
    }
    
    //关键帧需要把sps pps信息取出
    if (isKeyFrame) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        
        //sps
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, NULL );
        if (statusCode == noErr) {
            
            //pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, NULL );
            if (statusCode == noErr) {
                
                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                
                if ([videoEncode.delegate respondsToSelector:@selector(videoEncode:sps:pps:time:)]  ) {
                    [videoEncode.delegate videoEncode:videoEncode sps:sps pps:pps time:timeStamp];
                }
            }
        }

        
    }
    
    //视频数据 不管是不是关键帧都需要取出
    //前4个字节表示长度后面的数据的长度
    //除了关键帧,其它帧只有一个数据
    
    size_t length, totalLength;
    char *dataPointer;
    size_t offset = 0;
    int const headLen = 4;// 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length

    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(blockBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        // 循环获取nalu数据
        while (offset < totalLength - headLen) {
            
            int NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + offset, headLen);
            
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            NSData *naluData = [NSData dataWithBytes:dataPointer + headLen + offset length:NALUnitLength];
            offset += headLen + NALUnitLength;
            
            if ([videoEncode.delegate respondsToSelector:@selector(videoEncode:frame:time:isKeyFrame:)]) {
                [videoEncode.delegate videoEncode:videoEncode frame:naluData time:timeStamp isKeyFrame:isKeyFrame];
            }
        }
    }
}

@end
