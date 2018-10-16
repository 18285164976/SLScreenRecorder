//
//  SLVideoPLayerView.h
//  DB20
//
//  Created by SunLu on 2018/3/22.
//  Copyright © 2018年 DreamCatcher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//屏幕宽高
#define kScreenWidth        [UIScreen mainScreen].bounds.size.width
#define kScreenHeight       [UIScreen mainScreen].bounds.size.height

#define KscreenWidth        [UIScreen mainScreen].bounds.size.width
#define KscreenHeight       [UIScreen mainScreen].bounds.size.height

#define PNGIMAGE(imageName) [UIImage imageNamed:imageName]

@interface SLVideoPLayerView : UIView
@property (strong,nonatomic) UIImageView *imageView;
@property (strong,nonatomic) AVPlayer *player;
@property (strong,nonatomic) AVPlayerItem *playerItem;
@property (strong,nonatomic) AVPlayerLayer *playerLayer;
@property (strong,nonatomic) AVAsset * movieAsset;
@property (strong,nonatomic) AVPlayerItemVideoOutput *videoOutput;
@property (strong,nonatomic) NSString *videoPath;

- (void)playWithPath:(NSString *)path;
- (void)startPlay;
- (void)cleanPlayer;
- (void)pauseVideoPlay;
- (UIImage *)getCurrentVideoSnapshot;
@end


@interface UIImage (ColorImage)
+ (UIImage*)imageWithColor:(UIColor*)color;

//设置图片透明度
+ (UIImage *)imageByApplyingAlpha:(CGFloat)alpha image:(UIImage*)image;

//改变图片尺寸
-(UIImage*)scaleToSize:(CGSize)size;

// 把图片改变颜色
- (UIImage *) imageWithTintColor:(UIColor *)tintColor;

//改变图片颜色
+ (UIImage *)imageWithColor:(UIColor *)color image:(UIImage *)image alpha:(CGFloat)alpha;
@end
