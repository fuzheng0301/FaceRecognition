//
//  FaceStreamDetectorViewController.h
//  IFlyFaceDemo
//
//  Created by 付正 on 16/3/1.
//  Copyright (c) 2016年 fuzheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@protocol FaceDetectorDelegate <NSObject>

-(void)sendFaceImage:(UIImage *)faceImage; //上传图片成功
-(void)sendFaceImageError; //上传图片失败

@end

@interface FaceStreamDetectorViewController : UIViewController

@property (assign,nonatomic) id<FaceDetectorDelegate> faceDelegate;

@end
