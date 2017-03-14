//
//  LLYVideoConfig.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  H264压缩等级
 */
typedef NS_ENUM(NSUInteger, SGProfileLevel) {
    /**
     *  baseline,默认
     */
    SGProfileLevel_H264_Baseline_AutoLevel,
    /**
     *  main
     */
    SGProfileLevel_H264_Main_AutoLevel,
    /**
     *  high 建议6s以上使用,慎用
     */
    SGProfileLevel_H264_High_AutoLevel,
};


@interface LLYVideoConfig : NSObject

/**
 *  视频尺寸,默认640 * 480
 */
@property (nonatomic,assign) CGSize videoSize;

/**
 *  码率,默认512*1024
 */
@property (nonatomic,assign) int bitrate;

/**
 *  fps,默认30
 */
@property (nonatomic,assign) int fps;

/**
 *  关键帧间隔,一般为fps的倍数,默认fps*2
 */
@property (nonatomic,assign) int keyframeInterval;

/**
 *  H264压缩等级,等级越高,压缩率越高,越节约流量,越耗费cpu,越耗时,手机越烫
 */
@property (nonatomic,assign) SGProfileLevel level;

+ (instancetype)defaultConfig;


@end
