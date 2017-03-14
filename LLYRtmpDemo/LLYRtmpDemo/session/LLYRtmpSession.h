//
//  LLYRtmpSession.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLYFrame.h"

typedef NS_ENUM(NSUInteger, LLYRtmpSessionStatus){
    
    LLYRtmpSessionStatusNone              = 0,
    LLYRtmpSessionStatusConnected         = 1,
    
    LLYRtmpSessionStatusHandshake0        = 2,
    LLYRtmpSessionStatusHandshake1        = 3,
    LLYRtmpSessionStatusHandshake2        = 4,
    LLYRtmpSessionStatusHandshakeComplete = 5,
    
    LLYRtmpSessionStatusFCPublish         = 6,
    LLYRtmpSessionStatusReady             = 7,
    LLYRtmpSessionStatusSessionStarted    = 8,
    
    LLYRtmpSessionStatusError             = 9,
    LLYRtmpSessionStatusNotConnected      = 10
};

@class LLYRtmpSession;
@protocol LLYRtmpSessionDelegate <NSObject>

- (void)rtmpSession:(LLYRtmpSession *)rtmpSession didChangeStatus:(LLYRtmpSessionStatus)rtmpStatus;

@end

@class LLYRtmpConfig;
@interface LLYRtmpSession : NSObject

@property (nonatomic,copy) NSString *url;
@property (nonatomic,strong) LLYRtmpConfig *config;

@property (nonatomic,weak) id<LLYRtmpSessionDelegate> delegate;

- (void)connect;

- (void)disConnect;

- (void)sendBuffer:(LLYFrame *)frame;

@end
