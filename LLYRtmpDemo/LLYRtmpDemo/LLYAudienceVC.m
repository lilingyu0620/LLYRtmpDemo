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

@property (nonatomic,assign) LLYSessionState sessionStatus;

@end

const uint8_t lyStartCode[4] = {0, 0, 0, 1};
#define RTMP_URL  @"rtmp://10.0.117.190/myapp/mystream"


@implementation LLYAudienceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.mOpenGLView = [[LYOpenGLView alloc]init];
    [self.view addSubview:_mOpenGLView];
    [_mOpenGLView setupGL];
    
    mDecodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
//    inputSize = 0;
//    //    inputMaxSize = 640 * 480 * 3 * 4;
//    inputMaxSize = 512*1024;
//    inputBuffer = malloc(inputMaxSize);
    
    [self setSessiones];
}
- (IBAction)playAndResume:(id)sender {
    
    switch (self.session.status) {
        case LLYSessionStateConnecting:
        case LLYSessionStateConnected:
        {
            [self.session endSession];
            [self EndVideoToolBox];
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
    
    self.sessionStatus = status;
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

- (void)sessions:(LLYSessions *)session receiveVideoData:(uint8_t *)data length:(int)length{
    NSLog(@"xxxxxxxxxxxxxx%s",data);
    packetBuffer = data;
    packetSize = length;
    [self updateFrame];
}


- (void)updateFrame{

    dispatch_sync(mDecodeQueue, ^{
        if(packetBuffer == NULL) {
            return ;
        }
    
        uint32_t nalSize = (uint32_t)(packetBuffer - 4);
        uint32_t *pNalSize = (uint32_t *)packetBuffer;
        *pNalSize = CFSwapInt32HostToBig(nalSize);
        
        // 在buffer的前面填入代表长度的int
        CVPixelBufferRef pixelBuffer = NULL;
        int nalType = packetBuffer[4] & 0x1F;
        switch (nalType) {
            case 0x05:
                NSLog(@"Nal type is IDR frame");
                [self initVideoToolBox];
                pixelBuffer = [self decode];
                break;
            case 0x07:
                NSLog(@"Nal type is SPS");
                mSPSSize = packetSize - 4;
                mSPS = malloc(mSPSSize);
                memcpy(mSPS, packetBuffer + 4, mSPSSize);
                break;
            case 0x08:
                NSLog(@"Nal type is PPS");
                mPPSSize = packetSize - 4;
                mPPS = malloc(mPPSSize);
                memcpy(mPPS, packetBuffer + 4, mPPSSize);
                break;
            default:
                NSLog(@"Nal type is B/P frame");
                pixelBuffer = [self decode];
                break;
        }
        
        if(pixelBuffer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.mOpenGLView displayPixelBuffer:pixelBuffer];
                CVPixelBufferRelease(pixelBuffer);
            });
        }
        NSLog(@"Read Nalu size %ld", packetSize);
    });
}

//- (void)readPacket {
//    if (packetSize && packetBuffer) {
//        packetSize = 0;
//        free(packetBuffer);
//        packetBuffer = NULL;
//    }
//    
//    int totalLen = sizeof(&inputBuffer);
//    long length = strlen(&inputBuffer);
//    if (inputSize < inputMaxSize && totalLen > 0) {
//        inputSize += totalLen;
//    }
//    if (memcmp(inputBuffer, lyStartCode, 4) == 0) {
//        if (inputSize > 4) { // 除了开始码还有内容
//            uint8_t *pStart = inputBuffer + 4;
//            uint8_t *pEnd = inputBuffer + inputSize;
//            while (pStart != pEnd) { //这里使用一种简略的方式来获取这一帧的长度：通过查找下一个0x00000001来确定。
//                if(memcmp(pStart - 3, lyStartCode, 4) == 0) {
//                    packetSize = pStart - inputBuffer - 3;
//                    if (packetBuffer) {
//                        free(packetBuffer);
//                        packetBuffer = NULL;
//                    }
//                    packetBuffer = malloc(packetSize);
//                    memcpy(packetBuffer, inputBuffer, packetSize); //复制packet内容到新的缓冲区
//                    memmove(inputBuffer, inputBuffer + packetSize, inputSize - packetSize); //把缓冲区前移
//                    inputSize -= packetSize;
//                    break;
//                }
//                else {
//                    ++pStart;
//                }
//            }
//        }
//    }
//}

- (void)initVideoToolBox {
    if (!mDecodeSession) {
        const uint8_t* parameterSetPointers[2] = {mSPS, mPPS};
        const size_t parameterSetSizes[2] = {mSPSSize, mPPSSize};
        OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                              2, //param count
                                                                              parameterSetPointers,
                                                                              parameterSetSizes,
                                                                              4, //nal start code size
                                                                              &mFormatDescription);
        if(status == noErr) {
            CFDictionaryRef attrs = NULL;
            const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
            //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
            //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
            uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
            attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
            
            VTDecompressionOutputCallbackRecord callBackRecord;
            callBackRecord.decompressionOutputCallback = didDecompress;
            callBackRecord.decompressionOutputRefCon = NULL;
            
            status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                                  mFormatDescription,
                                                  NULL, attrs,
                                                  &callBackRecord,
                                                  &mDecodeSession);
            CFRelease(attrs);
        } else {
            NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
        }
    }
}

void didDecompress(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

-(CVPixelBufferRef)decode {
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    if (mDecodeSession) {
        CMBlockBufferRef blockBuffer = NULL;
        OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                              (void*)packetBuffer, packetSize,
                                                              kCFAllocatorNull,
                                                              NULL, 0, packetSize,
                                                              0, &blockBuffer);
        if(status == kCMBlockBufferNoErr) {
            CMSampleBufferRef sampleBuffer = NULL;
            const size_t sampleSizeArray[] = {packetSize};
            status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                               blockBuffer,
                                               mFormatDescription,
                                               1, 0, NULL, 1, sampleSizeArray,
                                               &sampleBuffer);
            if (status == kCMBlockBufferNoErr && sampleBuffer) {
                VTDecodeFrameFlags flags = 0;
                VTDecodeInfoFlags flagOut = 0;
                // 默认是同步操作。
                // 调用didDecompress，返回后再回调
                OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(mDecodeSession,
                                                                          sampleBuffer,
                                                                          flags,
                                                                          &outputPixelBuffer,
                                                                          &flagOut);
                
                if(decodeStatus == kVTInvalidSessionErr) {
                    NSLog(@"IOS8VT: Invalid session, reset decoder session");
                } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                    NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
                } else if(decodeStatus != noErr) {
                    NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
                }
                
                CFRelease(sampleBuffer);
            }
            CFRelease(blockBuffer);
        }
    }
    
    return outputPixelBuffer;
}

- (void)EndVideoToolBox
{
    if(mDecodeSession) {
        VTDecompressionSessionInvalidate(mDecodeSession);
        CFRelease(mDecodeSession);
        mDecodeSession = NULL;
    }
    
    if(mFormatDescription) {
        CFRelease(mFormatDescription);
        mFormatDescription = NULL;
    }
    
    free(mSPS);
    free(mPPS);
    mSPSSize = mPPSSize = 0;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
