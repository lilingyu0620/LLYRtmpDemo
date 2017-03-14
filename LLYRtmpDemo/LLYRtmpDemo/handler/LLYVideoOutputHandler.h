//
//  LLYVideoOutputHandler.h
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LLYVideoConfig.h"

@class LLYVideoOutputHandler;

@protocol LLYVideoOutputDelegate <NSObject>

- (void)videOutputHandler:(LLYVideoOutputHandler *)handler didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

@interface LLYVideoOutputHandler : NSObject

@property (nonatomic,weak) id<LLYVideoOutputDelegate> delegate;

//预览
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *preLayer;

//配置
@property (nonatomic,strong) LLYVideoConfig *config;

//开始录制
- (void)startVideoCapture;

//结束录制
- (void)stopVideoCapture;

//设置缩放系数
- (void)adjustVideoScaleAndCropFactor:(CGFloat)scale;
//调整画面朝向
- (void)adjustVideoOrientation:(AVCaptureVideoOrientation)orientation;

@end
