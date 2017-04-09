//
//  LLYAudienceVC.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/27.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "LLYAudienceVC.h"
#import <VideoToolbox/VideoToolbox.h>
#import "LLYSessions.h"
#import "AAPLEAGLLayer.h"


// NALU单元
typedef struct _NaluUnit
{
    int type;
    int size;
    unsigned char *data;
}NaluUnit;

const uint8_t lyStartCode[4] = {0, 0, 0, 1};

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
    
    uint8_t *naluBuffer;
    
    AAPLEAGLLayer *playLayer;

}

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *btn;

@property (nonatomic,strong) LLYSessions *session;

@property (nonatomic,assign) LLYSessionState sessionStatus;

@end

#define RTMP_URL @"rtmp://5072.liveplay.myqcloud.com/live/5072_dev10549"//  @"rtmp://192.168.1.2/myapp/mystream"


@implementation LLYAudienceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    playLayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.frame];
    playLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:playLayer];
    playLayer.zPosition = -1;
    
    mDecodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
//    inputSize = 0;
//    //    inputMaxSize = 640 * 480 * 3 * 4;
//    inputMaxSize = 512*1024;
//    inputBuffer = malloc(inputMaxSize);
    
    [self setSessiones];
}

- (void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
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
        
        uint8_t avcType = packetBuffer[0];
        long totalLength = packetSize;
        
        while (avcType == 0x17 || avcType == 0x27) {
            
            uint8_t type = packetBuffer[1];
            if (type == 0) {
                
                //获取sps
//                int spsnum = packetBuffer[10]&0x1f;
                int number_sps = 11;
                int count_sps = 1;
                int spsTotalLen = 0;
                uint8_t *spsTmp;
                
//                if (count_sps <= spsnum)
                {
                    int spslen =(packetBuffer[number_sps]&0x000000FF)<<8 | (packetBuffer[number_sps+1]&0x000000FF);
                    number_sps += 2;
                    
                    spsTmp = malloc(spslen + 4);
                    memcpy(spsTmp, lyStartCode, 4);
                    spsTotalLen += 4;
                    
                    memcpy(spsTmp+4,packetBuffer + number_sps , spslen);
                    spsTotalLen += spslen;
                    
                    number_sps += spslen;
                    
                    totalLength -= number_sps;
                    count_sps ++;
                }
                [self decodeNalu:spsTmp withSize:spsTotalLen];
                
                packetBuffer += number_sps+1;
                //获取pps
//                int ppsnum = packetBuffer[number_sps]&0x1f;
                int number_pps = 0;
                int count_pps = 1;
                int ppsTotalLen = 0;
                uint8_t *ppsTmp;
//                if (count_pps <= ppsnum)
                {
                    int ppslen =(packetBuffer[number_pps]&0x000000FF)<<8 | (packetBuffer[number_pps+1]&0x000000FF);
                    number_pps += 2;
                    
                    ppsTmp = malloc(ppslen + 4);
                    memcpy(ppsTmp, lyStartCode, 4);
                    ppsTotalLen += 4;
                    memcpy(ppsTmp +  4,packetBuffer + number_pps,ppslen);
                    ppsTotalLen += ppslen;
                    number_pps += ppslen;
                    
                    totalLength -= number_pps;
                    count_pps ++;
                }
                [self decodeNalu:ppsTmp withSize:ppsTotalLen];
                
                packetBuffer += number_pps;
                avcType = packetBuffer[0];
            }
            else if(type == 1){
                
                BOOL isNalu = YES;
                
                //获取avc nalu
                int len =0;
                int num =5;
                int naluTotalLen = 0;
                
                while (isNalu)
                {
                    
                    len = (packetBuffer[num]&0x000000FF)<<24 | (packetBuffer[num+1]&0x000000FF)<<16
                    | (packetBuffer[num+2]&0x000000FF)<<8 | (packetBuffer[num+3]&0x000000FF);
                    
                    naluBuffer = malloc(len + 4);
                    naluTotalLen += 4;
                    naluTotalLen += len;

                    memcpy(naluBuffer,packetBuffer + num,len + 4);
                    
                    num = num + len + 4;
                    totalLength -= num;
                    
                    [self decodeNalu:naluBuffer withSize:naluTotalLen];
                    packetBuffer += num;
                    num = 0;
                    naluTotalLen = 0;
                    free(naluBuffer);
                    
                    //可能存在下一个NALU
                    if (totalLength > 4) {
                        avcType = packetBuffer[0];
                        if (avcType == 0x17 || avcType == 0x27) {
                            isNalu = NO;
                        }
                        else{
                            len = (packetBuffer[num]&0x000000FF)<<24 | (packetBuffer[num+1]&0x000000FF)<<16
                            | (packetBuffer[num+2]&0x000000FF)<<8 | (packetBuffer[num+3]&0x000000FF);
                            
                            if (len >= (totalLength - 4)) {
                                return;
                            }
                        }
                    }
                    else{
                        return;
                    }
                }
            }
            
        }
    });
}


-(void) decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    //    NSLog(@">>>>>>>>>>开始解码");
    int nalu_type = (frame[4] & 0x1F);
    CVPixelBufferRef pixelBuffer = NULL;
    
//    uint32_t nalSize = (uint32_t)(frameSize - 4);
//    uint8_t *pNalSize = (uint8_t*)(&nalSize);
//    frame[0] = *(pNalSize + 3);
//    frame[1] = *(pNalSize + 2);
//    frame[2] = *(pNalSize + 1);
//    frame[3] = *(pNalSize);
    //传输的时候。关键帧不能丢数据 否则绿屏   B/P可以丢  这样会卡顿
    switch (nalu_type)
    {
        case 0x05:
            //NSLog(@"nalu_type:%d Nal type is IDR frame",nalu_type);  //关键帧
            {
                uint32_t dataLength32 = htonl (frameSize - 4);
                memcpy (frame, &dataLength32, sizeof (uint32_t));
                
                [self initVideoToolBox];
                pixelBuffer = [self decode:frame withSize:frameSize];
                [self displayDecodedFrame:pixelBuffer];
            }
            break;
        case 0x07:
            //NSLog(@"nalu_type:%d Nal type is SPS",nalu_type);   //sps
            mSPSSize = frameSize - 4;
            mSPS = malloc(mSPSSize);
            memcpy(mSPS, frame + 4, mSPSSize);
            break;
        case 0x08:
        {
            //NSLog(@"nalu_type:%d Nal type is PPS",nalu_type);   //pps
            mPPSSize = frameSize - 4;
            mPPS = malloc(mPPSSize);
            memcpy(mPPS, frame + 4, mPPSSize);
            break;
        }
        default:
        {
            //NSLog(@"Nal type is B/P frame");//其他帧
            {
                uint32_t dataLength32 = htonl (frameSize - 4);
                memcpy (frame, &dataLength32, sizeof (uint32_t));
                
                [self initVideoToolBox];
                pixelBuffer = [self decode:frame withSize:frameSize];
                [self displayDecodedFrame:pixelBuffer];

            }
            break;
        }
    }
    
//    if(pixelBuffer)
//    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.mOpenGLView displayPixelBuffer:pixelBuffer];
//            CVPixelBufferRelease(pixelBuffer);
//        });
//    }
}

-(CVPixelBufferRef)decode:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    if (!mDecodeSession) {
        return nil;
    }
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(NULL,
                                                          (void *)frame,
                                                          frameSize,
                                                          kCFAllocatorNull,
                                                          NULL,
                                                          0,
                                                          frameSize,
                                                          FALSE,
                                                          &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {frameSize};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           mFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
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
    
    return outputPixelBuffer;
}


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
            callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
            
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


- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer
{
    if(imageBuffer)
    {
        playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
