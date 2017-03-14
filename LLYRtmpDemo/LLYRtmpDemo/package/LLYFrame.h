//
//  LLYFrame.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/2.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLYFrame : NSObject

//数据
@property (nonatomic,strong) NSData *data;

//时间戳
@property (nonatomic,assign) int timestamp;

//长度
@property (nonatomic,assign) int msgLength;

//typeId
@property (nonatomic,assign) int msgTypeId;

//msgStreamId
@property (nonatomic,assign) int msgStreamId;

//关键帧
@property (nonatomic,assign) BOOL isKeyframe;

@end
