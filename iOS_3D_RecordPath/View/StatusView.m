//
//  StatusView.m
//  iOS_2D_RecordPath
//
//  Created by PC on 15/7/16.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "StatusView.h"
#import <AVFoundation/AVFoundation.h>

#define controlHeight 20

@interface StatusView()

@property (nonatomic, strong) UIButton *control;

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, assign) BOOL isOpen;

@property (nonatomic, assign) CGRect originFrame;
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@end

@implementation StatusView

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
         self.synthesizer = [[AVSpeechSynthesizer alloc] init];
        //后台播放音频设置
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        
    
        self.isOpen = YES;
        self.originFrame = self.frame;
        
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        
        self.control = [UIButton buttonWithType:UIButtonTypeCustom];
        self.control.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), controlHeight);
        self.control.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [self.control setTitle:@"opened" forState:UIControlStateNormal];
        [self.control addTarget:self action:@selector(actionSwitch) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:self.control];
        
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, controlHeight, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-controlHeight)];
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.textColor = [UIColor whiteColor];
        self.textView.font = [UIFont systemFontOfSize:12];
        self.textView.editable = NO;
        self.textView.selectable = NO;
        
        [self addSubview:self.textView];
        
    }
    return self;
}

- (void)actionSwitch
{
    _isOpen = ! _isOpen;
    
    if (_isOpen)
    {
        [_control setTitle:@"opened" forState:UIControlStateNormal];
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = _originFrame;
            self.textView.frame = CGRectMake(0, controlHeight, self.frame.size.width, self.frame.size.height-controlHeight);
        }];
    }
    else
    {
        [_control setTitle:@"closed" forState:UIControlStateNormal];
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = CGRectMake(self.originFrame.origin.x, self.originFrame.origin.y, self.originFrame.size.width, controlHeight);
            self.textView.frame = CGRectMake(0, 0, 0, 0);
        }];
    }
}

- (void)stopSpeech
{
    AVSpeechSynthesizer *talked = self.synthesizer;
    if([talked isSpeaking]) {
        [talked stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@""];
        [talked speakUtterance:utterance];
        [talked stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}

- (void)showStatusWith:(CLLocation *)location
{
    NSMutableString *info = [[NSMutableString alloc] init];
    [info appendString:@"经纬度:\n"];
    [info appendString:[NSString stringWithFormat:@"%.4f, %.4f\n", location.coordinate.latitude,location.coordinate.longitude]];
    
    [info appendString:@"速度:\n"];
    
    double speed = location.speed > 0 ? location.speed : 0;
    [info appendString:[NSString stringWithFormat:@"<%.2fm/s(%.2fkm/h)>\n", speed, speed * 3.6]];
    
    
   
    if(speed*3.6>60){
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@"您已经超速，请您减速慢行。"];
        //设置语言类别（不能被识别，返回值为nil）
        AVSpeechSynthesisVoice *voiceType = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
        utterance.voice = voiceType;
        //设置语速快慢
        //utterance.rate *= 0.5;
        //语音合成器会生成音频
        [self.synthesizer speakUtterance:utterance];
    }else{
        [self stopSpeech];
    }
    
    [info appendString:@"精确度:\n"];
    [info appendString:[NSString stringWithFormat:@"%.2fm\n", location.horizontalAccuracy]];
    
    [info appendString:@"海拔:\n"];
    [info appendString:[NSString stringWithFormat:@"%.2fm", location.altitude]];
    
    _textView.text = info;
}

@end
