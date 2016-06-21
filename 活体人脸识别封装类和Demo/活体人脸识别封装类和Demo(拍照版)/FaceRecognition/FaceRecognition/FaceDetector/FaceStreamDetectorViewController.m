//
//  FaceStreamDetectorViewController.m
//  IFlyFaceDemo
//
//  Created by 付正 on 16/3/1.
//  Copyright (c) 2016年 fuzheng. All rights reserved.
//

#import "FaceStreamDetectorViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "PermissionDetector.h"
#import "UIImage+Extensions.h"
#import "UIImage+compress.h"
#import "iflyMSC/IFlyFaceSDK.h"
#import "DemoPreDefine.h"
#import "CaptureManager.h"
#import "CanvasView.h"
#import "CalculatorTools.h"
#import "UIImage+Extensions.h"
#import "IFlyFaceImage.h"
#import "IFlyFaceResultKeys.h"

@interface FaceStreamDetectorViewController ()<CaptureManagerDelegate>
{
    UILabel *alignLabel;
    int number;//
    int takePhotoNumber;
    NSTimer *timer;
    NSInteger timeCount;
    UIImageView *imgView;//动画图片展示
    
    //拍照操作
    AVCaptureStillImageOutput *myStillImageOutput;
    UIView *backView;//照片背景
    UIImageView *imageView;//照片展示
    
    BOOL isCrossBorder;//判断是否越界
    BOOL isJudgeMouth;//判断张嘴操作完成
    BOOL isShakeHead;//判断摇头操作完成
    
    //嘴角坐标
    int leftX;
    int rightX;
    int lowerY;
    int upperY;
    
    //嘴型的宽高（初始的和后来变化的）
    int mouthWidthF;
    int mouthHeightF;
    int mouthWidth;
    int mouthHeight;
    
    //记录摇头嘴中点的数据
    int bigNumber;
    int smallNumber;
    int firstNumber;
}
@property (nonatomic, retain ) UIView         *previewView;
@property (nonatomic, strong ) UILabel        *textLabel;

@property (nonatomic, retain ) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain ) CaptureManager             *captureManager;

@property (nonatomic, retain ) IFlyFaceDetector           *faceDetector;
@property (nonatomic, strong ) CanvasView                 *viewCanvas;
@property (nonatomic, strong ) UITapGestureRecognizer     *tapGesture;

@end

@implementation FaceStreamDetectorViewController
@synthesize captureManager;

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //创建界面
    [self makeUI];
    //创建摄像页面
    [self makeCamera];
    //创建数据
    [self makeNumber];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //停止摄像
    [self.previewLayer.session stopRunning];
    [self.captureManager removeObserver];
}

-(void)makeNumber
{
    //张嘴数据
    number = 0;
    takePhotoNumber = 0;
    
    mouthWidthF = 0;
    mouthHeightF = 0;
    mouthWidth = 0;
    mouthHeight = 0;
    
    //摇头数据
    bigNumber = 0;
    smallNumber = 0;
    firstNumber = 0;
}

#pragma mark --- 创建UI界面
-(void)makeUI
{
    self.previewView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight*2/3)];
    [self.view addSubview:self.previewView];
    
    //提示框
    imgView = [[UIImageView alloc]initWithFrame:CGRectMake((ScreenWidth-ScreenHeight/6+10)/2, CGRectGetMaxY(self.previewView.frame)+15, ScreenHeight/6-10, ScreenHeight/6-10)];
    [self.view addSubview:imgView];
    
    self.textLabel = [[UILabel alloc]initWithFrame:CGRectMake((ScreenWidth-150)/2, CGRectGetMaxY(imgView.frame)+10, 150, 30)];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.layer.cornerRadius = 15;
    self.textLabel.text = @"请按提示做动作";
    self.textLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.textLabel];
    
    //背景View
    backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-64)];
    backView.backgroundColor = [UIColor lightGrayColor];
    
    //图片放置View
    imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 10, ScreenWidth, ScreenWidth*4/3)];
    [backView addSubview:imageView];
    
    //button上传图片
    [self buttonWithTitle:@"上传图片" frame:CGRectMake(ScreenWidth/2-150, CGRectGetMaxY(imageView.frame)+10, 100, 30) action:@selector(didClickUpPhoto) AddView:backView];
    
    //重拍图片按钮
    [self buttonWithTitle:@"重拍" frame:CGRectMake(ScreenWidth/2+50, CGRectGetMaxY(imageView.frame)+10, 100, 30) action:@selector(didClickPhotoAgain) AddView:backView];
}

#pragma mark --- 创建相机
-(void)makeCamera
{
    self.title = @"人脸识别";
    //adjust the UI for iOS 7
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ( IOS7_OR_LATER ){
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
#endif
    
    self.view.backgroundColor=[UIColor blackColor];
    self.previewView.backgroundColor=[UIColor clearColor];
    
    //设置初始化打开识别
    self.faceDetector=[IFlyFaceDetector sharedInstance];
    [self.faceDetector setParameter:@"1" forKey:@"detect"];
    [self.faceDetector setParameter:@"1" forKey:@"align"];
    
    //初始化 CaptureSessionManager
    self.captureManager=[[CaptureManager alloc] init];
    self.captureManager.delegate=self;
    
    self.previewLayer=self.captureManager.previewLayer;
    
    self.captureManager.previewLayer.frame= self.previewView.frame;
    self.captureManager.previewLayer.position=self.previewView.center;
    self.captureManager.previewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    [self.previewView.layer addSublayer:self.captureManager.previewLayer];
    
    self.viewCanvas = [[CanvasView alloc] initWithFrame:self.captureManager.previewLayer.frame] ;
    [self.previewView addSubview:self.viewCanvas] ;
    self.viewCanvas.center=self.captureManager.previewLayer.position;
    self.viewCanvas.backgroundColor = [UIColor clearColor];
    NSString *str = [NSString stringWithFormat:@"{{%f, %f}, {220, 240}}",(ScreenWidth-220)/2,(ScreenWidth-240)/2+15];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setObject:str forKey:@"RECT_KEY"];
    [dic setObject:@"1" forKey:@"RECT_ORI"];
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    [arr addObject:dic];
    self.viewCanvas.arrFixed = arr;
    self.viewCanvas.hidden = NO;
    
    //建立 AVCaptureStillImageOutput
    myStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *myOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [myStillImageOutput setOutputSettings:myOutputSettings];
    [self.captureManager.session addOutput:myStillImageOutput];
    
    //开始摄像
    [self.captureManager setup];
    [self.captureManager addObserver];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    [self.captureManager observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - 开启识别
- (void) showFaceLandmarksAndFaceRectWithPersonsArray:(NSMutableArray *)arrPersons
{
    if (self.viewCanvas.hidden) {
        self.viewCanvas.hidden = NO;
    }
    self.viewCanvas.arrPersons = arrPersons;
    [self.viewCanvas setNeedsDisplay] ;
}

#pragma mark --- 关闭识别
- (void) hideFace
{
    if (!self.viewCanvas.hidden) {
        self.viewCanvas.hidden = YES ;
    }
}

#pragma mark --- 脸部框识别
-(NSString*)praseDetect:(NSDictionary* )positionDic OrignImage:(IFlyFaceImage*)faceImg
{
    if(!positionDic){
        return nil;
    }
    
    // 判断摄像头方向
    BOOL isFrontCamera=self.captureManager.videoDeviceInput.device.position==AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.previewLayer.frame.size.width / faceImg.height;
    CGFloat heightScaleBy = self.previewLayer.frame.size.height / faceImg.width;
    
    CGFloat bottom =[[positionDic objectForKey:KCIFlyFaceResultBottom] floatValue];
    CGFloat top=[[positionDic objectForKey:KCIFlyFaceResultTop] floatValue];
    CGFloat left=[[positionDic objectForKey:KCIFlyFaceResultLeft] floatValue];
    CGFloat right=[[positionDic objectForKey:KCIFlyFaceResultRight] floatValue];
    
    float cx = (left+right)/2;
    float cy = (top + bottom)/2;
    float w = right - left;
    float h = bottom - top;
    
    float ncx = cy ;
    float ncy = cx ;
    
    CGRect rectFace = CGRectMake(ncx-w/2 ,ncy-w/2 , w, h);
    
    if(!isFrontCamera){
        rectFace=rSwap(rectFace);
        rectFace=rRotate90(rectFace, faceImg.height, faceImg.width);
    }
    
    //判断位置
    BOOL isNotLocation = [self identifyYourFaceLeft:left right:right top:top bottom:bottom];
    
    if (isNotLocation==YES) {
        return nil;
    }
    
    NSLog(@"left=%f right=%f top=%f bottom=%f",left,right,top,bottom);
    
    isCrossBorder = NO;
    
    rectFace=rScale(rectFace, widthScaleBy, heightScaleBy);
    
    return NSStringFromCGRect(rectFace);
}

#pragma mark --- 脸部部位识别
-(NSMutableArray*)praseAlign:(NSDictionary* )landmarkDic OrignImage:(IFlyFaceImage*)faceImg
{
    if(!landmarkDic){
        return nil;
    }
    
    // 判断摄像头方向
    BOOL isFrontCamera=self.captureManager.videoDeviceInput.device.position==AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.previewLayer.frame.size.width / faceImg.height;
    CGFloat heightScaleBy = self.previewLayer.frame.size.height / faceImg.width;
    
    NSMutableArray *arrStrPoints = [NSMutableArray array];
    NSEnumerator* keys=[landmarkDic keyEnumerator];
    for(id key in keys){
        id attr=[landmarkDic objectForKey:key];
        if(attr && [attr isKindOfClass:[NSDictionary class]]){
            
            id attr=[landmarkDic objectForKey:key];
            CGFloat x=[[attr objectForKey:KCIFlyFaceResultPointX] floatValue];
            CGFloat y=[[attr objectForKey:KCIFlyFaceResultPointY] floatValue];
            
            CGPoint p = CGPointMake(y,x);
            
            if(!isFrontCamera){
                p=pSwap(p);
                p=pRotate90(p, faceImg.height, faceImg.width);
            }
            
            //判断是否越界
            if (isCrossBorder == YES) {
                [self delateNumber];//清数据
                return nil;
            }
            
            //获取嘴的坐标，判断是否张嘴
            [self identifyYourFaceOpenMouth:key p:p];
            
            //获取鼻尖的坐标，判断是否摇头
            [self identifyYourFaceShakeHead:key p:p];
            
            p=pScale(p, widthScaleBy, heightScaleBy);
            
            [arrStrPoints addObject:NSStringFromCGPoint(p)];
            
        }
    }
    
    return arrStrPoints;
}

#pragma mark --- 脸部识别
-(void)praseTrackResult:(NSString*)result OrignImage:(IFlyFaceImage*)faceImg
{
    if(!result){
        return;
    }
    
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* faceDic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        resultData=nil;
        if(!faceDic){
            return;
        }
        
        NSString* faceRet=[faceDic objectForKey:KCIFlyFaceResultRet];
        NSArray* faceArray=[faceDic objectForKey:KCIFlyFaceResultFace];
        faceDic=nil;
        
        int ret=0;
        if(faceRet){
            ret=[faceRet intValue];
        }
        //没有检测到人脸或发生错误
        if (ret || !faceArray || [faceArray count]<1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideFace];
            }) ;
            return;
        }
        
        //检测到人脸
        NSMutableArray *arrPersons = [NSMutableArray array] ;
        
        for(id faceInArr in faceArray){
            
            if(faceInArr && [faceInArr isKindOfClass:[NSDictionary class]]){
                
                NSDictionary* positionDic=[faceInArr objectForKey:KCIFlyFaceResultPosition];
                NSString* rectString=[self praseDetect:positionDic OrignImage: faceImg];
                positionDic=nil;
                
                NSDictionary* landmarkDic=[faceInArr objectForKey:KCIFlyFaceResultLandmark];
                NSMutableArray* strPoints=[self praseAlign:landmarkDic OrignImage:faceImg];
                landmarkDic=nil;
                
                
                NSMutableDictionary *dicPerson = [NSMutableDictionary dictionary] ;
                if(rectString){
                    [dicPerson setObject:rectString forKey:RECT_KEY];
                }
                if(strPoints){
                    [dicPerson setObject:strPoints forKey:POINTS_KEY];
                }
                
                strPoints=nil;
                
                [dicPerson setObject:@"0" forKey:RECT_ORI];
                [arrPersons addObject:dicPerson] ;
                
                dicPerson=nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showFaceLandmarksAndFaceRectWithPersonsArray:arrPersons];
                });
            }
        }
        faceArray=nil;
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
    }
}

#pragma mark - CaptureManagerDelegate
-(void)onOutputFaceImage:(IFlyFaceImage*)faceImg
{
    NSString* strResult=[self.faceDetector trackFrame:faceImg.data withWidth:faceImg.width height:faceImg.height direction:(int)faceImg.direction];
    NSLog(@"result:%@",strResult);
    
    //此处清理图片数据，以防止因为不必要的图片数据的反复传递造成的内存卷积占用。
    faceImg.data=nil;
    
    NSMethodSignature *sig = [self methodSignatureForSelector:@selector(praseTrackResult:OrignImage:)];
    if (!sig) return;
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:self];
    [invocation setSelector:@selector(praseTrackResult:OrignImage:)];
    [invocation setArgument:&strResult atIndex:2];
    [invocation setArgument:&faceImg atIndex:3];
    [invocation retainArguments];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil  waitUntilDone:NO];
    faceImg=nil;
}

#pragma mark --- 判断位置
-(BOOL)identifyYourFaceLeft:(CGFloat)left right:(CGFloat)right top:(CGFloat)top bottom:(CGFloat)bottom
{
    //判断位置
    if (right - left < 230 || bottom - top < 250) {
        self.textLabel.text = @"太远了...";
        [self delateNumber];//清数据
        isCrossBorder = YES;
        return YES;
    }else if (right - left > 320 || bottom - top > 320) {
        self.textLabel.text = @"太近了...";
        [self delateNumber];//清数据
        isCrossBorder = YES;
        return YES;
    }else{
        if (isJudgeMouth != YES) {
            self.textLabel.text = @"请重复张嘴动作...";
            [self tomAnimationWithName:@"openMouth" count:2];
#pragma mark --- 限定脸部位置为中间位置
            if (left < 100 || top < 100 || right > 460 || bottom > 400) {
                isCrossBorder = YES;
                isJudgeMouth = NO;
                self.textLabel.text = @"调整下位置先...";
                [self delateNumber];//清数据
                return YES;
            }
        }else if (isJudgeMouth == YES && isShakeHead != YES) {
            self.textLabel.text = @"请重复摇头动作...";
            [self tomAnimationWithName:@"shakeHead" count:4];
            number = 0;
        }else{
            takePhotoNumber += 1;
            if (takePhotoNumber == 2) {
                [self timeBegin];
            }
        }
        isCrossBorder = NO;
    }
    return NO;
}

#pragma mark --- 判断是否张嘴
-(void)identifyYourFaceOpenMouth:(NSString *)key p:(CGPoint )p
{
    if ([key isEqualToString:@"mouth_upper_lip_top"]) {
        upperY = p.y;
    }
    if ([key isEqualToString:@"mouth_lower_lip_bottom"]) {
        lowerY = p.y;
    }
    if ([key isEqualToString:@"mouth_left_corner"]) {
        leftX = p.x;
    }
    if ([key isEqualToString:@"mouth_right_corner"]) {
        rightX = p.x;
    }
    if (rightX && leftX && upperY && lowerY && isJudgeMouth != YES) {
        
        number ++;
        if (number == 1 || number == 300 || number == 600 || number ==900) {
            //延时操作
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            mouthWidthF = rightX - leftX < 0 ? abs(rightX - leftX) : rightX - leftX;
            mouthHeightF = lowerY - upperY < 0 ? abs(lowerY - upperY) : lowerY - upperY;
            NSLog(@"%d,%d",mouthWidthF,mouthHeightF);
//            });
        }else if (number > 1200) {
            [self delateNumber];//时间过长时重新清除数据
            [self tomAnimationWithName:@"openMouth" count:2];
        }
        
        mouthWidth = rightX - leftX < 0 ? abs(rightX - leftX) : rightX - leftX;
        mouthHeight = lowerY - upperY < 0 ? abs(lowerY - upperY) : lowerY - upperY;
        NSLog(@"%d,%d",mouthWidth,mouthHeight);
        NSLog(@"张嘴前：width=%d，height=%d",mouthWidthF - mouthWidth,mouthHeight - mouthHeightF);
        if (mouthWidth && mouthWidthF) {
            //张嘴验证完毕
            if (mouthHeight - mouthHeightF >= 20 && mouthWidthF - mouthWidth >= 15) {
                isJudgeMouth = YES;
                imgView.animationImages = nil;
            }
        }
    }
}

#pragma mark --- 判断是否摇头
-(void)identifyYourFaceShakeHead:(NSString *)key p:(CGPoint )p
{
    if ([key isEqualToString:@"mouth_middle"] && isJudgeMouth == YES) {
        
        if (bigNumber == 0 ) {
            firstNumber = p.x;
            bigNumber = p.x;
            smallNumber = p.x;
        }else if (p.x > bigNumber) {
            bigNumber = p.x;
        }else if (p.x < smallNumber) {
            smallNumber = p.x;
        }
        //摇头验证完毕
        if (bigNumber - smallNumber > 60) {
            isShakeHead = YES;
            [self delateNumber];//清数据
        }
    }
}

#pragma mark --- 拍照
-(void)didClickTakePhoto
{
    AVCaptureConnection *myVideoConnection = nil;
    
    //从 AVCaptureStillImageOutput 中取得正确类型的 AVCaptureConnection
    for (AVCaptureConnection *connection in myStillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                
                myVideoConnection = connection;
                break;
            }
        }
    }
    
    //撷取影像（包含拍照音效）
    [myStillImageOutput captureStillImageAsynchronouslyFromConnection:myVideoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        //完成撷取时的处理程序(Block)
        if (imageDataSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            
            //取得的静态影像
            UIImage *myImage = [[UIImage alloc] initWithData:imageData];
            imageView.backgroundColor = [UIColor lightGrayColor];
            imageView.image = myImage;
            
            imageView.frame = CGRectMake(0, 10, ScreenWidth, ScreenWidth*myImage.size.height/myImage.size.width);
            
            [self.view addSubview:backView];
            
            //停止摄像
            [self.previewLayer.session stopRunning];
            
            [self delateNumber];
        }
    }];
}

#pragma mark --- 重拍按钮点击事件
-(void)didClickPhotoAgain
{
    //清数据
    [self delateNumber];
    
    //开始摄像
    [self.previewLayer.session startRunning];
    self.textLabel.text = @"请调整位置...";
    
    [backView removeFromSuperview];
    
    isJudgeMouth = NO;
    isShakeHead = NO;
    
}

#pragma mark --- 上传图片按钮点击事件
-(void)didClickUpPhoto
{
//    UIAlertView *alt = [[UIAlertView alloc]initWithTitle:@"提示" message:@"验证完成" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
//    [alt show];
    
    //上传照片失败
//    [self.faceDelegate sendFaceImageError];
    //上传照片成功
    [self.faceDelegate sendFaceImage:imageView.image];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 点击『验证完成』AlertView
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (imageView.image) {
        //上传照片成功
        [self.faceDelegate sendFaceImage:imageView.image];
        //上传照片失败
    //    [self.faceDelegate sendFaceImageError];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark --- 清掉对应的数
-(void)delateNumber
{
    number = 0;
    takePhotoNumber = 0;
    
    mouthWidthF = 0;
    mouthHeightF = 0;
    mouthWidth = 0;
    mouthHeight = 0;
    
    smallNumber = 0;
    bigNumber = 0;
    firstNumber = 0;
    
    imgView.animationImages = nil;
    imgView.image = [UIImage imageNamed:@"shakeHead0"];
}

#pragma mark --- 计时开始
-(void)timeBegin
{
    timeCount = 3;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
    self.textLabel.text = [NSString stringWithFormat:@"%ld s后拍照...", (long)timeCount];
    
}

#pragma mark --- 时间变为0，拍照
- (void)timerFireMethod:(NSTimer *)theTimer
{
    timeCount --;
    if(timeCount >= 1)
    {
        self.textLabel.text = [NSString  stringWithFormat:@"%ld s后拍照...",(long)timeCount];
    }
    else
    {
        [theTimer invalidate];
        theTimer=nil;
        
        [self didClickTakePhoto];
    }
}

#pragma mark --- 创建button公共方法
/**使用示例:[self buttonWithTitle:@"点 击" frame:CGRectMake((self.view.frame.size.width - 150)/2, (self.view.frame.size.height - 40)/3, 150, 40) action:@selector(didClickButton) AddView:self.view];*/
-(UIButton *)buttonWithTitle:(NSString *)title frame:(CGRect)frame action:(SEL)action AddView:(id)view
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    button.backgroundColor = [UIColor lightGrayColor];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchDown];
    [view addSubview:button];
    return button;
}

#pragma mark --- UIImageView显示gif动画
- (void)tomAnimationWithName:(NSString *)name count:(NSInteger)count
{
    // 如果正在动画，直接退出
    if ([imgView isAnimating]) return;
    
    // 动画图片的数组
    NSMutableArray *arrayM = [NSMutableArray array];
    
    // 添加动画播放的图片
    for (int i = 0; i < count; i++) {
        // 图像名称
        NSString *imageName = [NSString stringWithFormat:@"%@%d.png", name, i];
        //        UIImage *image = [UIImage imageNamed:imageName];
        // ContentsOfFile需要全路径
        NSString *path = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        
        [arrayM addObject:image];
    }
    
    // 设置动画数组
    imgView.animationImages = arrayM;
    // 重复1次
    imgView.animationRepeatCount = 100;
    // 动画时长
    imgView.animationDuration = imgView.animationImages.count * 0.75;
    
    // 开始动画
    [imgView startAnimating];
}

-(void)dealloc
{
    self.captureManager=nil;
    self.viewCanvas=nil;
    [self.previewView removeGestureRecognizer:self.tapGesture];
    self.tapGesture=nil;
}

@end
