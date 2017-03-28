//
//  LLYDirectorVC.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/27.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYDirectorVC.h"
#import "LLYVideoSession.h"
#import "LLYVideoConfig.h"
#import "LLYVideoOutputHandler.h"
#import "LLYSessions.h"

#define RTMP_URL  @"rtmp://10.0.117.190/myapp/mystream"

@interface LLYDirectorVC ()<UIGestureRecognizerDelegate,LLYSessionsDelegate>{

    CGFloat beginGestureScale;
    CGFloat effectiveScale;
    AVCaptureVideoOrientation currentOrientation;

}
@property (nonatomic,strong) LLYSessions *session;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *btn;

@end

@implementation LLYDirectorVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setSessiones];
    
    [self addPinchRecognizer];
    beginGestureScale = effectiveScale = 1.0f;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setSessiones{
    
    currentOrientation = AVCaptureVideoOrientationPortrait;
    
    self.session = [LLYSessions defultSession];
    self.session.currentActor = LLYDirectorActor;
    self.session.delegate = self;
    self.session.url = RTMP_URL;
    
    self.session.preView.frame = self.view.bounds;
    [self.view insertSubview:self.session.preView atIndex:0];
    
}


- (void)sessions:(LLYSessions *)session statusDidChanged:(LLYSessionState)status{
    switch (status) {
        case LLYSessionStateConnecting:
        {
            self.statusLabel.backgroundColor = [UIColor orangeColor];
            self.statusLabel.text = @"连接中...";
        }
            break;
        case LLYSessionStateConnected:
        {
            self.statusLabel.backgroundColor = [UIColor greenColor];
            self.statusLabel.text = @"已连接";
            [self.btn setTitle:@"结束推流" forState:UIControlStateNormal];
        }
            break;
        default:
        {
            self.statusLabel.backgroundColor = [UIColor redColor];
            self.statusLabel.text = @"未连接";
            [self.btn setTitle:@"开始推流" forState:UIControlStateNormal];
        }
            break;
    }
}



//添加缩放手势，调节焦距 ---
- (void)addPinchRecognizer{
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchScreen:)];
    pinchGesture.delegate = self;
    [self.view addGestureRecognizer:pinchGesture];
}

- (void)pinchScreen:(UIPinchGestureRecognizer *)recognizer{
    
    effectiveScale = beginGestureScale * recognizer.scale;
    if (effectiveScale < 1.0)
        effectiveScale = 1.0;
    if (effectiveScale > 10.0)
        effectiveScale = 10.0;
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    [self.view.layer setAffineTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
    [CATransaction commit];
    
    [self.session.videoSession.videoOutputHandler adjustVideoScaleAndCropFactor:effectiveScale];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        beginGestureScale = effectiveScale;
    }
    return YES;
}

- (IBAction)videoOrientation:(id)sender {
    
    //    if (currentOrientation == AVCaptureVideoOrientationPortrait) {
    //        [self.session.videoSession.videoOutputHandler adjustVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
    //        currentOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    //    }
    //    else{
    //        [self.session.videoSession.videoOutputHandler adjustVideoOrientation:AVCaptureVideoOrientationPortrait];
    //        currentOrientation = AVCaptureVideoOrientationPortrait;
    //    }
    
    switch (self.session.status) {
        case LLYSessionStateConnecting:
        case LLYSessionStateConnected:
        {
            [self.session endSession];
        }
            break;
            
        default:
        {
            [self.session startSession];
        }
            break;
    }
    
}


@end
