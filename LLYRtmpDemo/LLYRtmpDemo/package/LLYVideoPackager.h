//
//  LLYVideoPackager.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/2.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLYFrame.h"

@class LLYVideoPackager;
@protocol LLYVideoPackagerDelegate <NSObject>

- (void)videoPackage:(LLYVideoPackager *)package didPacketFrame:(LLYFrame *)frame;

@end



@interface LLYVideoPackager : NSObject

@property (nonatomic,weak) id<LLYVideoPackagerDelegate> delegate;

- (void)reset;

- (void)packageKeyFrameSps:(NSData *)spsData pps:(NSData *)ppsData timestamp:(uint64_t)timestamp;

- (void)packageFrame:(NSData *)data timestamp:(uint64_t)timestamp isKeyFrame:(BOOL)isKeyFrame;

@end
