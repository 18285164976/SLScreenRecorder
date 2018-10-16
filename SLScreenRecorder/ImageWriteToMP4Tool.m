//
//  ImageWriteToMP4Tool.m
//  SLScreenRecorder
//
//  Created by SunLu on 2018/10/16.
//  Copyright © 2018年 Sl. All rights reserved.
//

#import "ImageWriteToMP4Tool.h"

@implementation ImageWriteToMP4Tool

- (instancetype)initWriterWithMoviePath:(NSString *)path withSize:(CGSize)size byFPS:(int32_t)fps
{
    self = [super init];
    if (self) {
        self.writePath = path;
        self.size = size;
        self.fps = fps;
        unlink([self.writePath UTF8String]);
        
        NSError *error =nil;
        self.videoWriter =[[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie error:&error];
        NSParameterAssert(self.videoWriter);
        if(error)
            NSLog(@"error =%@", [error localizedDescription]);
        
        NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:
                                      AVVideoCodecH264,AVVideoCodecKey,
                                      [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                      [NSNumber numberWithInt:size.height],AVVideoHeightKey,nil];
        
        self.videoWriterInput =[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        //实时写入模式开启
        self.videoWriterInput.expectsMediaDataInRealTime = YES;
        
        NSDictionary *sourcePixelBufferAttributesDictionary =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey,nil];
        
        self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
        
        NSParameterAssert(self.videoWriterInput);
        NSParameterAssert([self.videoWriter canAddInput:self.videoWriterInput]);
        [self.videoWriter addInput:self.videoWriterInput];
        //Start a session:
        [self.videoWriter startWriting];
        [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    }
    return self;
}


- (BOOL)writeImage:(UIImage *)image
{
    if (self.adaptor.assetWriterInput.readyForMoreMediaData)
    {
        CVPixelBufferRef buffer =NULL;
        buffer = [self pixelBufferFromCGImage:[image CGImage] size:image.size];
        CMTime frameTime = CMTimeMake(self.frameCount,self.fps);
        float frameSeconds = CMTimeGetSeconds(frameTime);
        
        if(buffer && !(self.frameCount !=0 && frameSeconds == 0) && self.adaptor.assetWriterInput.readyForMoreMediaData){
            if (![self.adaptor appendPixelBuffer:buffer withPresentationTime:frameTime]){
                NSLog(@"error appendingimage %d times frameSeconds:%f\n writerStatus:%ld", self.frameCount,frameSeconds,(long)self.videoWriter.status);
                AVAssetWriterStatus state = self.videoWriter.status;
                if (state == AVAssetWriterStatusFailed) {
                    NSLog(@"writer error:%@",self.videoWriter.error);
                }
                
                if (buffer != NULL) {
                    CVPixelBufferRelease(buffer);
                }
                return NO;
            }else{
                NSLog(@"success appendingimage %d times frameSeconds:%f\n", self.frameCount,frameSeconds);
            }
            self.frameCount += 1;
        }
        
        if (buffer != NULL) {
            CVPixelBufferRelease(buffer);
        }
        return YES;
    }else{
        printf("adaptor not ready %d\n", self.frameCount);
        return NO;
    }
}
- (void)stopWrite
{
    self.adaptor  = nil;
    self.frameCount = 0;
    //Finish the session:
    [self.videoWriterInput markAsFinished];
    //[videoWriter finishWriting];
    [self.videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"finishWriting success");
    }];
}

- (void)writeimages:(NSArray *)imageArr
{
    //合成多张图片为一个视频文件
    dispatch_queue_t dispatchQueue =dispatch_queue_create("mediaInputQueue",NULL);
    [self.videoWriterInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        for (int i = 0; i< imageArr.count; i++) {//一张图片表示一贞
            if (![self writeImage:imageArr[i]]) {
                break;
            }
        }
        [self stopWrite];
    }];
}


- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    CVImageBufferRef imageBuffer =  pixelBufferRef;
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return image;
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer =NULL;
    CVReturn status =CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer !=NULL);
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    void *pxdata =CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context =CGBitmapContextCreate(pxdata,size.width,size.height,8,4*size.width,rgbColorSpace,kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    CGContextDrawImage(context,CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);
    
    return pxbuffer;
}

@end
