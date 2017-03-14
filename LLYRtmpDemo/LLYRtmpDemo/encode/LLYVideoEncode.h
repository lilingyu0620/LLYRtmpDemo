//
//  LLYVideoEncode.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "LLYVideoConfig.h"

@class LLYVideoEncode;
@protocol LLYVideoEncodeDelegate <NSObject>
//
- (void)videoEncode:(LLYVideoEncode *)encode sps:(NSData *)sps pps:(NSData *)pps time:(uint64_t)time;
- (void)videoEncode:(LLYVideoEncode *)encode frame:(NSData *)frame time:(uint64_t)time isKeyFrame:(BOOL)isKeyFrame;

@end

@interface LLYVideoEncode : NSObject
@property (nonatomic,weak) id<LLYVideoEncodeDelegate> delegate;

@property (nonatomic,strong) LLYVideoConfig *videoConfig;

- (void)stopVideoEncode;

- (void)videoEncodeData:(CVPixelBufferRef)pixelBuffer time:(uint64_t)time;

@end
