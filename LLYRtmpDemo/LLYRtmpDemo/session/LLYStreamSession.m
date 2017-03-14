//
//  LLYStreamSession.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/2.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYStreamSession.h"

@interface LLYStreamSession ()<NSStreamDelegate>

@property (nonatomic,strong) NSInputStream *inputStream;
@property (nonatomic,strong) NSOutputStream *outputStream;

@end

@implementation LLYStreamSession

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.streamStatus = NSStreamEventNone;
    }
    return self;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    [self close];
}



- (void)connectToServer:(NSString *)host port:(UInt32)port{

    if (self.streamStatus > 0) {
        [self close];
    }
    
    //输入流 用来读取数据
    CFReadStreamRef readStream;
    //输出流，用来发送数据
    CFWriteStreamRef writeStream;
    
    if (port <= 0) {
        //RTMP默认端口1935
        port = 1935;
    }
    
    //建立socket链接
    CFStreamCreatePairWithSocketToHost(NULL,(__bridge CFStringRef)host, port, &readStream, &writeStream);
    
    //注意__bridge_transfer,转移对象的内存管理权
    _inputStream           = (__bridge_transfer  NSInputStream  *)readStream;
    _outputStream          = (__bridge_transfer  NSOutputStream *)writeStream;

    _inputStream.delegate = self;
    _outputStream.delegate = self;
    
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [_inputStream  scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

    
    [_inputStream open];
    [_outputStream open];
}



- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{

    switch (eventCode) {
        case NSStreamEventNone: {
            return;//此处是return
        }
        case NSStreamEventOpenCompleted: {
            if (_inputStream == aStream ) {
                NSLog(@"连接成功");
                _streamStatus = NSStreamEventOpenCompleted;
            }
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"有字节可读");
            _streamStatus |= NSStreamEventHasBytesAvailable;
            break;
        }
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"可以发送字节");
            _streamStatus |= NSStreamEventHasSpaceAvailable;
            break;
        }
        case NSStreamEventErrorOccurred: {
            NSLog(@"连接出现错误");
            _streamStatus = NSStreamEventErrorOccurred;
            
            NSError *theError = [aStream streamError];
;
            NSLog(@"error =====   %@",[NSString stringWithFormat:@"Error %li: %@",
                                     (long)[theError code], [theError localizedDescription]]);

            break;
        }
        case NSStreamEventEndEncountered: {
            NSLog(@"连接结束");
            NSError *theError = [aStream streamError];
            NSLog(@"error =====   %@",[NSString stringWithFormat:@"Error %li: %@",
                                       (long)[theError code], [theError localizedDescription]]);
            _streamStatus = NSStreamEventEndEncountered;
            break;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(streamSession:didChangeStatus:)]) {
        [self.delegate streamSession:self didChangeStatus:_streamStatus];
    }
}

- (void)disConnect{
    [self close];
}

- (void)close{

    [_inputStream  close];
    [_outputStream close];
    [_inputStream  removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    _streamStatus = NSStreamEventNone;
    _inputStream.delegate = nil;
    _outputStream.delegate = nil;
    _outputStream = nil;
    _inputStream  = nil;
}


- (NSData *)readData{

    uint8_t buff[4096];//缓冲区
    
    NSUInteger len = [_inputStream read:buff maxLength:sizeof(buff)];
    
    NSData *data = nil;
    
    if (len < sizeof(buff) && (_streamStatus & NSStreamEventHasBytesAvailable)) {
        _streamStatus ^= NSStreamEventHasBytesAvailable;
        data = [NSData dataWithBytes:buff length:len];
    }
    
    return data;
}

- (NSInteger)writeData:(NSData *)data{

    if (data.length == 0) {
        return 0;
    }
    
    NSInteger ret = 0;
    if (_outputStream.hasSpaceAvailable) {
        ret = [_outputStream write:data.bytes maxLength:data.length];
    }
    
    if (ret > 0 && (_streamStatus & NSStreamEventHasBytesAvailable)) {
        //移除标志位
        _streamStatus ^= NSStreamEventHasBytesAvailable;
    }
    
    if (ret == -1) {
        NSLog(@"xxxxxxxxxxxxxxxx");
    }
    
    return ret;
}
@end
