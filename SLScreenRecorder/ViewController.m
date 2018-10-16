//
//  ViewController.m
//  SLScreenRecorder
//
//  Created by SunLu on 2018/10/12.
//  Copyright © 2018年 Sl. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>
#import <AVFoundation/AVFoundation.h>
#import "SLVideoPLayerView.h"
#import "ImageWriteToMP4Tool.h"





@interface ViewController ()

@property(nonatomic, strong) NSMutableArray *imageArr;
@property(nonatomic, strong) NSString  *theVideoPath;
@property(nonatomic, strong) SLVideoPLayerView *player;
@property(nonatomic, strong) NSTimer *recorderTimer;

@property(nonatomic, assign) float duration;

@property(nonatomic, strong) ImageWriteToMP4Tool *writerTool;



@property(nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController
-(NSMutableArray *)imageArr
{
    if (!_imageArr) {
        _imageArr = [NSMutableArray new];
    }
    return _imageArr;
}
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *moviePath =[[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",@"screenRecorder_6"]];
    self.theVideoPath = moviePath;
    self.duration = 0.0f;
    
    
    self.player = [[SLVideoPLayerView alloc] init];
    [self.view addSubview:self.player];
    [self.player mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(64);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@(200));
    }];
    self.player.videoPath = @"http://183.60.197.26/11/w/w/q/z/wwqzjymzsljpgcbnzziajfmdujfwbx/he.yinyuetai.com/8F21015D163444E9FEC0A733966E8FA7.mp4?sc%5Cu003d28633f340cb1d44d%5Cu0026br%5Cu003d3095%5Cu0026vid%5Cu003d2904251%5Cu0026aid%5Cu003d42423%5Cu0026area%5Cu003dML%5Cu0026vst%5Cu003d4";
    
    
    
    
//    self.imageArr =[[NSMutableArray alloc]initWithObjects:
//
//                    [UIImage imageNamed:@"1.jpg"],[UIImage imageNamed:@"2.jpg"],[UIImage imageNamed:@"3.jpg"],[UIImage imageNamed:@"4.jpg"],[UIImage imageNamed:@"5.jpg"],[UIImage imageNamed:@"6.jpg"],[UIImage imageNamed:@"7"],[UIImage imageNamed:@"8"],[UIImage imageNamed:@"9.jpg"],[UIImage imageNamed:@"10.jpg"],[UIImage imageNamed:@"11.jpg"],[UIImage imageNamed:@"12.jpg"],[UIImage imageNamed:@"13.jpg"],[UIImage imageNamed:@"14.jpg"],[UIImage imageNamed:@"15.jpg"],[UIImage imageNamed:@"16.jpg"],[UIImage imageNamed:@"17.jpg"],[UIImage imageNamed:@"18.jpg"],[UIImage imageNamed:@"19.jpg"],[UIImage imageNamed:@"20.jpg"],[UIImage imageNamed:@"21.jpg"],[UIImage imageNamed:@"22.jpg"],[UIImage imageNamed:@"23.jpg"],nil];
    
    UIButton * button =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(0,300, 100,50)];
    [button setTitle:@"合成"forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startRecord:)forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
    
    UIButton * button1 =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button1 setFrame:CGRectMake(120,300, 100,50)];
    [button1 setTitle:@"播放"forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(playAction)forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    
    
    self.imageView = [[UIImageView alloc] init];
    [self.view addSubview:self.imageView];
    self.imageView.backgroundColor = [UIColor blackColor];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@200);
    }];
    
    

}
-(void)startRecord:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        self.writerTool = [[ImageWriteToMP4Tool alloc] initWriterWithMoviePath:self.theVideoPath withSize:self.player.bounds.size byFPS:10];
        self.recorderTimer  = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0 target:self selector:@selector(recorderTimerAction:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.recorderTimer forMode:NSRunLoopCommonModes];
    }else{
        [self.recorderTimer invalidate];
        [self.writerTool stopWrite];
    }
}
-(void)recorderTimerAction:(NSTimer *)sender
{
    UIImage *image = [self.player getCurrentVideoSnapshot];
    if (image) {
        [self.writerTool writeImage:image];
    }
}

-(UIImage *)ScreenShotWithView:(UIView *)view{
    
    //这里因为我需要全屏接图所以直接改了，宏定义iPadWithd为1024，iPadHeight为768，
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);     //设置截屏大小
   // UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);     //设置截屏大小
    [[view layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //NSData *imageViewData = UIImagePNGRepresentation(viewImage);
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *pictureName= [NSString stringWithFormat:@"healthyLifeShareImage_%d.png",0];
//    NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:pictureName];
//    NSLog(@"截屏路径打印: %@", savedImagePath);
    //这里我将路径设置为一个全局String，这里做的不好，我自己是为了用而已，希望大家别这么写
    //[self SetPickPath:savedImagePath];
    
    //[imageViewData writeToFile:savedImagePath atomically:YES];//保存照片到沙盒目录
    //CGImageRelease(imageRefRect);
    return viewImage;
}

-(void)playAction
{
    
    //    MPMoviePlayerViewController *theMovie =[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:self.theVideoPath]];
    //
    //    [self presentMoviePlayerViewControllerAnimated:theMovie];
    //
    //    theMovie.moviePlayer.movieSourceType=MPMovieSourceTypeFile;[theMovie.moviePlayer play];
}






//二：视频跟音频的合成
// 混合音乐
-(void)merge
{
    
    // mbp提示框
    
    //  [MBProgressHUD showMessage:@"正在处理中"];
    
    // 路径
    
    NSString *documents = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    // 声音来源
    NSURL *audioInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"蓝瘦香菇" ofType:@"mp3"]];
    // 视频来源
    NSURL *videoInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"2016全球三大超跑宣传片_超清" ofType:@"mp4"]];
    // 最终合成输出路径
    NSString *outPutFilePath = [documents stringByAppendingPathComponent:@"merge.mp4"];
    // 添加合成路径
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outPutFilePath];
    
    // 时间起点
    
    CMTime nextClistartTime = kCMTimeZero;
    
    // 创建可变的音视频组合
    AVMutableComposition *comosition = [AVMutableComposition composition];
    // 视频采集
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoInputUrl options:nil];
    // 视频时间范围
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    // 视频通道 枚举 kCMPersistentTrackID_Invalid = 0
    AVMutableCompositionTrack *videoTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 视频采集通道
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    //  把采集轨道数据加入到可变轨道之中
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:nextClistartTime error:nil];
    
    
    // 声音采集
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioInputUrl options:nil];
    // 因为视频短这里就直接用视频长度了,如果自动化需要自己写判断
    CMTimeRange audioTimeRange = videoTimeRange;
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    // 音频采集通道
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    // 加入合成轨道之中
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:nextClistartTime error:nil];
    // 创建一个输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:AVAssetExportPresetMediumQuality];
    // 输出类型
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    
    // 输出地址
    assetExport.outputURL = outputFileUrl;
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        // 回到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // 调用播放方法  outputFileUrl 这个就是合成视频跟音频的视频
            
            //[self playWithUrl:outputFileUrl];
            
        });
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

