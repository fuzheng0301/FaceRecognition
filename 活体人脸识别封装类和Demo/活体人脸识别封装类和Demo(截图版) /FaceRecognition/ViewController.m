//
//  ViewController.m
//  FaceRecognition
//
//  Created by 聚财通 on 16/3/1.
//  Copyright © 2016年 付正. All rights reserved.
//

#import "ViewController.h"
#import "FaceStreamDetectorViewController.h"

@interface ViewController ()<FaceDetectorDelegate>
{
    UIImageView *imgView;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self buttonWithTitle:@"人脸识别" frame:CGRectMake(100, 50, 150, 30) action:@selector(pushToFaceStreamDetectorVC) AddView:self.view];
    
    imgView = [[UIImageView alloc]initWithFrame:CGRectMake(50, 150, self.view.frame.size.width-100, 300)];
    imgView.backgroundColor = [UIColor purpleColor];
    [self.view addSubview:imgView];
    
}

-(void)sendFaceImage:(UIImage *)faceImage
{
    imgView.frame = CGRectMake(50, 150, self.view.frame.size.width-100, (self.view.frame.size.width-100)/faceImage.size.width*faceImage.size.height);
    imgView.image = faceImage;
}

-(void)pushToFaceStreamDetectorVC
{
    FaceStreamDetectorViewController *faceVC = [[FaceStreamDetectorViewController alloc]init];
    faceVC.faceDelegate = self;
    [self.navigationController pushViewController:faceVC animated:YES];
}

#pragma mark --- 创建button公共方法
/**使用示例:[self buttonWithTitle:@"点 击" frame:CGRectMake((self.view.frame.size.width - 150)/2, (self.view.frame.size.height - 40)/3, 150, 40) action:@selector(didClickButton) AddView:self.view];*/
-(UIButton *)buttonWithTitle:(NSString *)title frame:(CGRect)frame action:(SEL)action AddView:(id)view
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    button.backgroundColor = [UIColor colorWithRed:0.601 green:0.596 blue:0.906 alpha:1.000];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchDown];
    [view addSubview:button];
    return button;
}

@end
