//
//  LLYVideoSession.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLYVideoConfig.h"
#import <AVFoundation/AVFoundation.h>

@class LLYVideoEncode;
@class LLYVideoOutputHandler;
@protocol LLYVideoSessionDelegate <NSObject>

- (void)videoEncode:(LLYVideoEncode *)encode sps:(NSData *)sps pps:(NSData *)pps time:(uint64_t)time;
- (void)videoEncode:(LLYVideoEncode *)encode frame:(NSData *)frame time:(uint64_t)time isKeyFrame:(BOOL)isKeyFrame;
- (void)videOutputHandler:(LLYVideoOutputHandler *)handler didOutputSampleBuffer:(CVPixelBufferRef)pixelBuffer;


@end

@class LLYVideoOutputHandler;

@interface LLYVideoSession : NSObject

@property (nonatomic,weak) id<LLYVideoSessionDelegate> delegate;

@property (nonatomic,strong) UIView *preView;

@property (nonatomic,strong) LLYVideoConfig *videoConfig;

@property (nonatomic,strong) LLYVideoOutputHandler *videoOutputHandler;

@property (nonatomic,strong) LLYVideoEncode *videoEncode;

+ (instancetype)defaultSession;

@end
