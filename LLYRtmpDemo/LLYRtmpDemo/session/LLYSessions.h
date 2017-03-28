//
//  LLYSessions.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLYVideoConfig.h"
#import "LLYVideoSession.h"
#import "LLYDemoHeader.h"

/**
 *  连接状态
 */
typedef NS_ENUM(NSUInteger, LLYSessionState) {
    LLYSessionStateNone,
    LLYSessionStateConnecting,
    LLYSessionStateConnected,
    LLYSessionStateReconnecting,
    LLYSessionStateEnd,
    LLYSessionStateError,
};

@class LLYSessions;
@protocol LLYSessionsDelegate <NSObject>

- (void)sessions:(LLYSessions *)session statusDidChanged:(LLYSessionState)status;
- (void)sessions:(LLYSessions *)session receiveVideoData:(uint8_t *)data;

@end

@class LLYRtmpConfig;
@interface LLYSessions : NSObject

@property (nonatomic,strong) LLYVideoSession *videoSession;

@property (nonatomic,weak) id<LLYSessionsDelegate> delegate;

@property (nonatomic,copy) NSString *url;

@property (nonatomic,strong) UIView *preView;

@property (nonatomic,assign) LLYSessionState status;

@property (nonatomic,assign) LLYCurrentActor currentActor;

+ (instancetype)defultSession;

- (void)startSession;
- (void)endSession;

@end
