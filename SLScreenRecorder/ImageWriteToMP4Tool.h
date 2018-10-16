//
//  ImageWriteToMP4Tool.h
//  SLScreenRecorder
//
//  Created by SunLu on 2018/10/16.
//  Copyright © 2018年 Sl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface ImageWriteToMP4Tool : NSObject
@property(nonatomic, strong) AVAssetWriter *videoWriter;
@property(nonatomic, strong) AVAssetWriterInput* videoWriterInput;
@property(nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;

@property(nonatomic, strong) NSString *writePath;
@property(nonatomic, assign) CGSize size;
@property(nonatomic, assign) int frameCount;
@property(nonatomic, assign) int32_t fps;



- (instancetype)initWriterWithMoviePath:(NSString *)path withSize:(CGSize)size byFPS:(int32_t)fps;
- (BOOL)writeImage:(UIImage *)image;
- (void)writeimages:(NSArray *)imageArr;
- (void)stopWrite;
@end
