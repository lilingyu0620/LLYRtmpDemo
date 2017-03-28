//
//  LLYAudienceVC.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/27.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYAudienceVC.h"
#import "LYOpenGLView.h"
#import <VideoToolbox/VideoToolbox.h>
#import "LLYSessions.h"

@interface LLYAudienceVC ()<UIGestureRecognizerDelegate,LLYSessionsDelegate>
{
    dispatch_queue_t mDecodeQueue;
    VTDecompressionSessionRef mDecodeSession;
    CMFormatDescriptionRef  mFormatDescription;
    uint8_t *mSPS;
    long mSPSSize;
    uint8_t *mPPS;
    long mPPSSize;
    
    // 输入
    NSInputStream *inputStream;
    uint8_t*       packetBuffer;
    long         packetSize;
    uint8_t*       inputBuffer;
    long         inputSize;
    long         inputMaxSize;

}
@property (nonatomic , strong) LYOpenGLView *mOpenGLView;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *btn;

@property (nonatomic,strong) LLYSessions *session;

@end

const uint8_t lyStartCode[4] = {0, 0, 0, 1};
#define RTMP_URL  @"rtmp://10.0.117.190/myapp/mystream"


@implementation LLYAudienceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
//    self.mOpenGLView = (LYOpenGLView *)self.view;
//    [self.mOpenGLView setupGL];
    
    mDecodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [self setSessiones];
}
- (IBAction)playAndResume:(id)sender {
    
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


- (void)setSessiones{

    self.session = [LLYSessions defultSession];
    self.session.currentActor = LLYAudienceActor;
    self.session.delegate = self;
    self.session.url = RTMP_URL;
    
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
            [self.btn setTitle:@"停止" forState:UIControlStateNormal];
        }
            break;
        default:
        {
            self.statusLabel.backgroundColor = [UIColor redColor];
            self.statusLabel.text = @"未连接";
            [self.btn setTitle:@"播放" forState:UIControlStateNormal];
        }
            break;
    }
}

- (void)sessions:(LLYSessions *)session receiveVideoData:(uint8_t *)data{
    NSLog(@"%s",data);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
