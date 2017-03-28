//
//  LLYVideoOutputHandler.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYVideoOutputHandler.h"
#import "GPUImage.h"

@interface LLYVideoOutputHandler ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    dispatch_queue_t _videoOutputQueue;
}
@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureDevice *videoDevice;
@property (nonatomic,strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic,strong) AVCaptureConnection *videoConnection;

@end

@implementation LLYVideoOutputHandler

- (void)dealloc{

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%s",__func__);
    
}

- (instancetype)init{

    self = [super init];
    if (self) {
        
        [self setVideoCapture];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseCameraCapture) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeCameraCapture) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    
    return self;
}

//进入后台暂停
- (void)pauseCameraCapture{
    [self.session stopRunning];
}
//进入前台开始
- (void)resumeCameraCapture{
    [self.session startRunning];
}

- (AVCaptureVideoPreviewLayer *)preLayer{

    if (_preLayer == nil) {
        _preLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _preLayer;
}

- (void)setVideoCapture{

    self.session = [[AVCaptureSession alloc]init];
    
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
    }
    
    self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    
    if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        if ([self.videoDevice lockForConfiguration:nil]) {
            self.videoDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
    }
    
    self.videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:self.videoDevice error:nil];
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    
    //kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange 表示原始数据的格式为YUV420
//    YUV 4:4:4采样，每一个Y对应一组UV分量。
//    YUV 4:2:2采样，每两个Y共用一组UV分量。
//    YUV 4:2:0采样，每四个Y共用一组UV分量。
    NSDictionary *settings = [[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],kCVPixelBufferPixelFormatTypeKey,nil];
    self.videoDataOutput.videoSettings = settings;
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    _videoOutputQueue = dispatch_queue_create("videoOutputQueue", DISPATCH_QUEUE_SERIAL);
    [self.videoDataOutput setSampleBufferDelegate:self queue:_videoOutputQueue];
    
    if ([self.session canAddOutput:self.videoDataOutput]) {
        [self.session addOutput:self.videoDataOutput];
    }
    
    self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.videoConnection setVideoScaleAndCropFactor:1];

    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
}


- (void)startVideoCapture{

    [self.session startRunning];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)stopVideoCapture{
    
    [self.session stopRunning];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)setConfig:(LLYVideoConfig *)config{

    _config = config;
    NSLog(@"video config is %@",config);
    
    NSError *error;
    [self.videoDevice lockForConfiguration:&error];
    
    if (error == nil) {
        NSLog(@"支持的帧速范围是：%@",[self.videoDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0]);
        
        if (self.videoDevice.activeFormat.videoSupportedFrameRateRanges) {
            [self.videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, config.fps)];
            [self.videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, config.fps)];
        }
    }
    
    [self.videoDevice unlockForConfiguration];
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

    __weak typeof(self) weakSelf = self;
//    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    if ([self.delegate respondsToSelector:@selector(videOutputHandler:didOutputSampleBuffer:)]) {
        [self.delegate videOutputHandler:weakSelf didOutputSampleBuffer:sampleBuffer];
    }
}

- (void)adjustVideoScaleAndCropFactor:(CGFloat)scale{
    
//    AVCaptureConnection *connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
//    [connection setVideoScaleAndCropFactor:scale];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        NSError *error = nil;
        if ([_videoDevice lockForConfiguration:&error])
        {
//            CGFloat zoomFactor = self.videoDevice.activeFormat.videoMaxZoomFactor;
            [_videoDevice rampToVideoZoomFactor:scale withRate:1];
            [_videoDevice unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    });

}

- (void)adjustVideoOrientation:(AVCaptureVideoOrientation)orientation{

    self.videoConnection.videoOrientation = orientation;
}
@end
