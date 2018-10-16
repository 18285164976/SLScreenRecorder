//
//  SLVideoPLayView.m
//  DB20
//
//  Created by SunLu on 2018/3/22.
//  Copyright © 2018年 DreamCatcher. All rights reserved.
//

#import "SLVideoPLayerView.h"
#import <Masonry.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetImageGenerator.h>
#import <AVFoundation/AVTime.h>



@implementation SLVideoPLayerView
{
    UIButton *_tempStartPlayBtn;
    
    CGFloat _currentTime;
    CGFloat duration;
    
    UIActivityIndicatorView *_indicationView;
    UIView *_controlBackgroundView;
    UIButton *_playBtn;
    UISlider *_timeSlider;
    UILabel *_currentTimeLab;
    UILabel *_totalTimeLab;
    NSTimer *_timerForCheckProgress;
    
    BOOL _isPlaying;
    BOOL _isPause;
}

-(void)dealloc
{
    [self removeObserver];
    [self cleanPlayer];
}
- (instancetype)init
{
    self = [self initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth*9.0/16.0)];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:frame];
        self.imageView.backgroundColor = [UIColor blackColor];
        [self addSubview:self.imageView];
    }
    return self;
}


/** 播放视频 */
- (void)playWithPath:(NSString *) path {
    
    if (path == nil) {
        return;
    }
    //self.videoPath = path;
    
    //获取文件的路径
    //    NSLog(@"path=%@",path);
    NSURL * sourceMovieURL = nil;
    if ([path hasPrefix:@"http"]) { //如果是本地视频,文件名请不要以http||https开头
        sourceMovieURL = [NSURL URLWithString:path];
    } else {
        sourceMovieURL = [NSURL fileURLWithPath:path];
    }
    //创建视频资源
    _movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
    //创建播放项
    _playerItem = [AVPlayerItem playerItemWithAsset:_movieAsset];
    //创建播放器
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    //要显示AVPlayer,需要先将它放在一个AVPlayerLayer中,绘制出区域
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.backgroundColor = [[UIColor clearColor] CGColor];
    //初始化frame
    _playerLayer.frame = self.bounds;
    
    //添加输出流
    _videoOutput = [[AVPlayerItemVideoOutput alloc] init];
    [_playerItem addOutput:_videoOutput];
    
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer addSublayer:_playerLayer];
    
    [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    
    //播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEndPlay:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [self buildControllView];
}

-(void)buildControllView
{
    _indicationView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:_indicationView];
    [_indicationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    _indicationView .hidesWhenStopped = YES;
    
    _controlBackgroundView = [[UIView alloc] init];
    [self addSubview:_controlBackgroundView];
    _controlBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    [_controlBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    self.userInteractionEnabled = YES;
    _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_controlBackgroundView addSubview:_playBtn];
    //_playBtn.backgroundColor = [UIColor redColor];
    [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self->_controlBackgroundView);
        make.size.mas_equalTo(CGSizeMake(45, 45));
    }];
    [_playBtn setImage:PNGIMAGE(@"de20_live_play") forState:UIControlStateNormal];
    [_playBtn setImage:PNGIMAGE(@"wdb700_live_stop") forState:UIControlStateSelected];
    [_playBtn addTarget:self action:@selector(startOrPausePlayAction:) forControlEvents:UIControlEventTouchUpInside];
    
    _timeSlider = [[UISlider alloc] init];
    [_controlBackgroundView addSubview:_timeSlider];
    [_timeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self->_controlBackgroundView);
        make.bottom.equalTo(self->_controlBackgroundView).offset(-5);
        make.size.mas_equalTo(CGSizeMake(200, 5));
    }];
    _timeSlider.minimumTrackTintColor = [UIColor blueColor];
    UIImage *thumbImage = [UIImage imageWithColor:[UIColor blueColor] image:[UIImage imageWithColor:[UIColor redColor]] alpha:1.0];
    [_timeSlider setThumbImage:thumbImage forState:UIControlStateNormal];
    [_timeSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];
    [_timeSlider addTarget:self action:@selector(timeSliderAction:) forControlEvents:UIControlEventValueChanged];
    [_timeSlider setValue:0.0];
    _timeSlider.hidden = YES;
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPlayerAction:)];
    [self addGestureRecognizer:tap];
    
    
}
-(void)setVideoPath:(NSString *)videoPath
{
    _videoPath = videoPath;
    [self playWithPath:_videoPath];
    
    //    if (_tempStartPlayBtn) {
    //        [_tempStartPlayBtn removeFromSuperview];
    //        _tempStartPlayBtn = nil;
    //    }
    //
    //    _tempStartPlayBtn = [[UIButton alloc] init];
    //    _tempStartPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [self addSubview:_tempStartPlayBtn];
    //    [_tempStartPlayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.center.equalTo(self);
    //        make.size.mas_equalTo(CGSizeMake(45, 45));
    //    }];
    //    [_tempStartPlayBtn setImage:PNGIMAGE(@"icon_play") forState:UIControlStateNormal];
    //    [_tempStartPlayBtn addTarget:self action:@selector(tempStartPlayButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
}

#pragma mark --- action -----
-(void)tempStartPlayButtonAction:(UIButton *)sender
{
    [_tempStartPlayBtn removeFromSuperview];
    [self playWithPath:self.videoPath];
    [self performSelector:@selector(startOrPausePlayAction:) withObject:_playBtn afterDelay:1.0];
}

-(void)tapPlayerAction:(UIGestureRecognizer *)sender
{
    _controlBackgroundView.hidden = !_controlBackgroundView.hidden;
    if (_isPlaying) {
        _timeSlider.hidden = NO;
    }
}
-(void)startOrPausePlayAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        if (!_playerLayer) {
            [self playWithPath:self.videoPath];
        }
        [self startPlay];
    }else{
        [_player pause];
        [_timerForCheckProgress invalidate];
        _isPause = YES;
    }
}

-(void)timeSliderAction:(UISlider *)sender
{
    _currentTime = sender.value;
    CMTime cmTime = CMTimeMake(sender.value, 1);
    [_player seekToTime:cmTime];
}



-(void)didEndPlay:(NSNotification *)sender
{
    if (_isPlaying) {
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    }
    _isPlaying = NO;
    _isPause = YES;
    [_controlBackgroundView setHidden:NO];
    [_player seekToTime:kCMTimeZero];
    _currentTime = 0.0f;
    [_timeSlider setValue:0.0];
    [_timerForCheckProgress invalidate];
    _timerForCheckProgress = nil;
    _timeSlider.hidden = YES;
    [_indicationView stopAnimating];
    _indicationView.hidden = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusFailed) {//准备失败
            [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
            return;
        }
        if (_player.status == AVPlayerStatusReadyToPlay) {//准备成功
            //[_player play];
            return;
        }
    }else if ([keyPath isEqualToString:@"duration"]) {//加载完成
        if ((CGFloat)CMTimeGetSeconds(_playerItem.duration) != duration) {
            duration = (CGFloat)CMTimeGetSeconds(_playerItem.duration);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"startPlay" object:nil];
            if (duration>0) {
                [_timeSlider setMaximumValue:duration];
                [_timeSlider setMinimumValue:0.0];
            }
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        float currentTime = (CGFloat)CMTimeGetSeconds(_playerItem.currentTime);
        [_timeSlider setValue:currentTime];
        
        if (_currentTime < currentTime) {
            _currentTime = currentTime;
            [_indicationView stopAnimating];
        }else if (_currentTime == currentTime ){//处理等待加载
            [_indicationView startAnimating];
        }
        
        if (duration == currentTime || currentTime < _currentTime) {
            _controlBackgroundView.hidden = NO;
            [_indicationView stopAnimating];
        }
        
        NSLog(@">>>>>>>>>>>>>>>>>>>>>>>> currentTime:%f",(CGFloat)CMTimeGetSeconds(_playerItem.currentTime));
    }
    
    //NSLog(@"*****************keypath:%@",keyPath);
}

-(UIImage *)getCurrentVideoSnapshot
{
    CMTime itemTime = _player.currentItem.currentTime;
    CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];

    //当前帧的画面
    UIImage *currentImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    
    
    return currentImage;
}

- (void)removeObserver {
    [_player removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"duration"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




- (void)startPlay
{
    //添加在线视频缓冲通知
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    _controlBackgroundView.hidden = YES;
    [_indicationView startAnimating];
    [_player play];
    _timerForCheckProgress = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProgessTimerAction:) userInfo:nil repeats:YES];
    _isPlaying = YES;
    _isPause = NO;
}
- (void)cleanPlayer
{
    if (_isPlaying) {
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    }
    [self removeObserver];
    _isPlaying = NO;
    _isPause = YES;
    CMTime cmTime = CMTimeMake(duration, 1);
    [_player seekToTime:cmTime];
    _movieAsset = nil;
    _playerItem = nil;
    _player = nil;
    _videoOutput = nil;
    _playerLayer = nil;
    [_indicationView stopAnimating];
    duration = 0.0;
}

-(void)pauseVideoPlay;
{
    [_player pause];
    [_timerForCheckProgress invalidate];
    _isPause = YES;
}
-(void)checkProgessTimerAction:(NSTimer *)sender
{
    float currentTime = (CGFloat)CMTimeGetSeconds(_playerItem.currentTime);
    //[_timeSlider setValue:currentTime];
    
    if (_currentTime < currentTime) {
        _currentTime = currentTime;
        [_indicationView stopAnimating];
    }else if (_currentTime == currentTime){//处理等待加载
        [_indicationView startAnimating];
    }
    
    if (duration == currentTime) {
        _controlBackgroundView.hidden = NO;
        [_indicationView stopAnimating];
    }
}



- (UIImage *)imageFromMovie:(NSString *)path local:(BOOL)bIsLocal {
    // set up the movie player
    
    UIImage *img = nil;
    if (bIsLocal) {
        
        /* quicker */
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:nil];
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        CMTime time = CMTimeMakeWithSeconds(0.0, 600);
        NSError *error = nil;
        CMTime actualTime;
        CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
        img = [[UIImage alloc] initWithCGImage:image];
        CGImageRelease(image);
    }else{
        MPMoviePlayerController *MPMovie = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:path]];
        MPMovie.shouldAutoplay = NO;
        img = [MPMovie thumbnailImageAtTime:0.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
    }
    return img;
}
@end






@implementation UIImage (ColorImage)

+ (UIImage*)imageWithColor:(UIColor*)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

//设置图片透明度
+ (UIImage *)imageByApplyingAlpha:(CGFloat)alpha image:(UIImage*)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    
    CGContextSetAlpha(ctx, alpha);
    
    CGContextDrawImage(ctx, area, image.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *) imageWithTintColor:(UIColor *)tintColor
{
    return [self imageWithTintColor:tintColor blendMode:kCGBlendModeDestinationIn];
}

- (UIImage *) imageWithGradientTintColor:(UIColor *)tintColor
{
    return [self imageWithTintColor:tintColor blendMode:kCGBlendModeOverlay];
}

- (UIImage *) imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode
{
    //We want to keep alpha, set opaque to NO; Use 0.0f for scale to use the scale factor of the device’s main screen.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    
    //Draw the tinted image in context
    [self drawInRect:bounds blendMode:blendMode alpha:1.0f];
    
    if (blendMode != kCGBlendModeDestinationIn) {
        [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    }
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}
-(UIImage*)scaleToSize:(CGSize)size
{
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    //Determine whether the screen is retina
    if([[UIScreen mainScreen] scale] == 2.0)
    {
        UIGraphicsBeginImageContextWithOptions(size, NO, 2.0);
    }else{
        UIGraphicsBeginImageContext(size);
    }
    // 绘制改变大小的图片
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}

//改变图片颜色
+ (UIImage *)imageWithColor:(UIColor *)color image:(UIImage *)image alpha:(CGFloat)alpha
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetAlpha(context, alpha);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextClipToMask(context, rect, image.CGImage);
    [color setFill];
    CGContextFillRect(context, rect);
    UIImage*newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end
