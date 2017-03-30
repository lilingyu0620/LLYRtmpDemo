//
//  LLYRtmpSession.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLYFrame.h"
#import "LLYDemoHeader.h"

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
    LLYRtmpSessionStatusNotConnected      = 10,
    
    LLYRtmpSessionStatusSessionStartPlay = 11
};

@class LLYRtmpSession;
@protocol LLYRtmpSessionDelegate <NSObject>

- (void)rtmpSession:(LLYRtmpSession *)rtmpSession didChangeStatus:(LLYRtmpSessionStatus)rtmpStatus;

- (void)rtmpSession:(LLYRtmpSession *)rtmpSession receiveVideoData:(uint8_t *)data length:(int)length;

@end

@class LLYRtmpConfig;
@interface LLYRtmpSession : NSObject

@property (nonatomic,copy) NSString *url;
@property (nonatomic,strong) LLYRtmpConfig *config;
@property (nonatomic,assign) LLYCurrentActor currentActor;

@property (nonatomic,weak) id<LLYRtmpSessionDelegate> delegate;

- (void)connect;

- (void)disConnect;

- (void)sendBuffer:(LLYFrame *)frame;

@end
