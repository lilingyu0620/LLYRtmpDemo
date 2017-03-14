//
//  LLYStreamSession.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/2.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSStreamEvent LLYStreamStatus;
@class LLYStreamSession;

@protocol LLYStreamSessionDelegate <NSObject>

- (void)streamSession:(LLYStreamSession *)session didChangeStatus:(LLYStreamStatus)streamStatus;

@end

@interface LLYStreamSession : NSObject

@property (nonatomic,weak) id<LLYStreamSessionDelegate> delegate;

@property (nonatomic,assign) LLYStreamStatus streamStatus;

- (void)connectToServer:(NSString *)host port:(UInt32)port;

- (void)disConnect;

- (NSData *)readData;

- (NSInteger)writeData:(NSData *)data;

@end
