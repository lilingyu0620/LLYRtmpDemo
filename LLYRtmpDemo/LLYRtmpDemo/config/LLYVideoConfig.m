//
//  LLYVideoConfig.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYVideoConfig.h"

@implementation LLYVideoConfig

+ (instancetype)defaultConfig{
    LLYVideoConfig *config = [[self alloc] init];
    config.videoSize = CGSizeMake(480, 640);
    config.bitrate = 512 *1024;
    config.fps = 30;
    config.level = SGProfileLevel_H264_Baseline_AutoLevel;
    config.keyframeInterval = config.fps/3;
    return config;
}

- (NSString *)description{
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:@"{\n"];
    [desc appendFormat:@"class: %@\n",[self class]];
    [desc appendFormat:@"videoSize:%@\n",NSStringFromCGSize(self.videoSize)];
    [desc appendFormat:@"bitRate:%d\n",self.bitrate];
    [desc appendFormat:@"fps:%d\n}",self.fps];
    return desc;
}


@end
