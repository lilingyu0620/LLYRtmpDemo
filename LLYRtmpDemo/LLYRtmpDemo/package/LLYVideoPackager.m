//
//  LLYVideoPackager.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/2.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYVideoPackager.h"
#import "LLYTypeHeader.h"

@interface LLYVideoPackager ()
{
    BOOL _hasSendKeyFrame;
}

@end

@implementation LLYVideoPackager

- (void)dealloc{
    self.delegate = nil;
}

- (instancetype)init{

    if(self=[super init]){
        _hasSendKeyFrame = NO;
    }
    return self;
}

- (void)reset{
    _hasSendKeyFrame = NO;
}

- (void)packageKeyFrameSps:(NSData *)spsData pps:(NSData *)ppsData timestamp:(uint64_t)timestamp{
    
    if (spsData.length <= 0 || ppsData <= 0) {
        return;
    }
    
    if (_hasSendKeyFrame) {
        return;
    }
    
    _hasSendKeyFrame = YES;
    
    const char *sps = spsData.bytes;
    const char *pps = ppsData.bytes;
    NSInteger sps_len = spsData.length;
    NSInteger pps_len = ppsData.length;
    
    NSInteger total = sps_len + pps_len + 16;
    uint8_t *body = (uint8_t *)malloc(total);
    int index = 0;
    
    memset(body,0,total);
    
    body[index++] = 0x17;
    body[index++] = 0x00;//sps_pps
    
    body[index++] = 0x00;
    body[index++] = 0x00;
    body[index++] = 0x00;
    
    body[index++] = 0x01;
    body[index++] = sps[1];
    body[index++] = sps[2];
    body[index++] = sps[3];
    body[index++] = 0xff;
    
    /*sps*/
    body[index++]   = 0xe1;
    body[index++] = (sps_len >> 8) & 0xff;
    body[index++] = sps_len & 0xff;
    memcpy(&body[index],sps,sps_len);
    index +=  sps_len;
    
    /*pps*/
    body[index++]   = 0x01;
    body[index++] = (pps_len >> 8) & 0xff;
    body[index++] = (pps_len) & 0xff;
    memcpy(&body[index], pps, pps_len);
    index +=  pps_len;
    
    if ([self.delegate respondsToSelector:@selector(videoPackage:didPacketFrame:)]) {
        NSData *data = [NSData dataWithBytes:body length:index];
        
        LLYFrame *frame = [[LLYFrame alloc] init];
        frame.data = data;
        frame.timestamp = 0;//一定是0
        frame.msgLength = (int)data.length;
        frame.msgTypeId = LLYMSGTypeID_VIDEO;
        frame.msgStreamId = LLYStreamIDVideo;//video
        frame.isKeyframe = YES;
        [self.delegate videoPackage:self didPacketFrame:frame];
    }

}

- (void)packageFrame:(NSData *)data timestamp:(uint64_t)timestamp isKeyFrame:(BOOL)isKeyFrame{

    if (!_hasSendKeyFrame) {
        return;
    }
    
    NSInteger i = 0;
    NSInteger total = data.length + 9;
    unsigned char *body = (unsigned char *)malloc(total);
    
    memset(body, 0, total);
    
    if (isKeyFrame) {
        body[i++] = 0x17;//1:I Frame 7:AVC
    }
    else{
        body[i++] = 0x27;//2:P Frame 7:AVC
    }
    body[i++] = 0x01;//AVC NALU 不是psp_pps
    
    body[i++] = 0x00;
    body[i++] = 0x00;
    body[i++] = 0x00;//pts - dts

    //长度数据
    body[i++] = (data.length >> 24) & 0xff;
    body[i++] = (data.length >> 16) & 0xff;
    body[i++] = (data.length >>  8) & 0xff;
    body[i++] = (data.length ) & 0xff;

    memcpy(&body[i], data.bytes, data.length);
    
    if ([self.delegate respondsToSelector:@selector(videoPackage:didPacketFrame:)]) {
        NSData *data = [NSData dataWithBytes:body length:total];
        LLYFrame *frame = [[LLYFrame alloc]init];
        frame.data = data;
        frame.timestamp = (int)timestamp;
        frame.msgLength = (int)data.length;
        frame.msgTypeId = LLYMSGTypeID_VIDEO;
        frame.msgStreamId = LLYStreamIDVideo;
        frame.isKeyframe = isKeyFrame;

        [self.delegate videoPackage:self didPacketFrame:frame];
    }
}

@end
