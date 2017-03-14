//
//  LLYRtmpConfig.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/7.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLYRtmpConfig : NSObject


@property (nonatomic,copy  ) NSString *url;
@property (nonatomic,assign) int32_t  width;
@property (nonatomic,assign) int32_t  height;
@property (nonatomic,assign) double   frameDuration;
@property (nonatomic,assign) int32_t  videoBitrate;
@property (nonatomic,assign) double   audioSampleRate;
@property (nonatomic,assign) BOOL     stereo;//立体声


@end
