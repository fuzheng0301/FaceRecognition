# FaceRecognition

之前公司项目需要，研究了一下人脸识别和活体识别，并运用免费的讯飞人脸识别，在其基础上做了二次开发，添加了活体识别。项目需要就开发了张嘴和摇头两个活体动作的识别。 这里简单介绍一下当时的开发思路和一些个人拙见，欢迎大神指点。
首先说一下讯飞第三方的人脸识别的几个缺点：1.识别不稳定，各点坐标跳动偏差比较大，不容易捕捉；2.CPU使用率比较高，连续识别一会儿手机会明显发烫，手机配置低的，就会反应很慢，本人使用的iPhone 6s，配置还可以，还算比较流畅，但也会发烫。3.屏幕小的手机识别率相对会低一点，当然这也和手机的配置脱不了干系。    

# 目录
1. [确定位置](https://github.com/fuzheng0301/FaceRecognition/blob/master/README.md#确定位置)
2. [张嘴识别](https://github.com/fuzheng0301/FaceRecognition/blob/master/README.md#张嘴识别)
3. [摇头识别](https://github.com/fuzheng0301/FaceRecognition/blob/master/README.md#摇头识别)
4. [其他细节](https://github.com/fuzheng0301/FaceRecognition/blob/master/README.md#其他细节)
5. [尾声](https://github.com/fuzheng0301/FaceRecognition/blob/master/README.md#尾声)

下面开始我们的活体识别开发之路：

## 确定位置

讯飞的人脸识别坐标跳动比较大，如果全屏识别发现很容易出现错误的识别，导致识别错误的被通过，所以为了降低这个可能性，特意加了脸部位置的限制，把识别位置和范围大大缩小，大大提高了识别精度和成功率。
原版的Demo里给出了人脸框的坐标，也显示出了人脸的框，代码如下：
```
-(void)drawPointWithPoints:(NSArray *)arrPersons      
{      
	if (context) {      
		CGContextClearRect(context, self.bounds) ;      
	}      
	context = UIGraphicsGetCurrentContext();      
	for (NSDictionary *dicPerson in arrPersons) {      
		if ([dicPerson objectForKey:POINTS_KEY]) {      
			for (NSString *strPoints in [dicPerson objectForKey:POINTS_KEY]) {      
			CGPoint p = CGPointFromString(strPoints);      
			CGContextAddEllipseInRect(context, CGRectMake(p.x - 1 , p.y - 1 , 2 , 2));      
		}      
	}      
	BOOL isOriRect=NO;      
	if ([dicPerson objectForKey:RECT_ORI]) {      
		isOriRect=[[dicPerson objectForKey:RECT_ORI] boolValue];      
	}      
	if ([dicPerson objectForKey:RECT_KEY]) {      

		CGRect rect=CGRectFromString([dicPerson objectForKey:RECT_KEY]);      
		if(isOriRect){//完整矩形      
			CGContextAddRect(context,rect) ;      
		}      
		else{ //只画四角      
			// 左上      
			CGContextMoveToPoint(context, rect.origin.x, rect.origin.y+rect.size.height/8);      
			CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width/8, rect.origin.y);      

			//右上      
			CGContextMoveToPoint(context, rect.origin.x+rect.size.width*7/8, rect.origin.y);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width, rect.origin.y);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height/8);      

			//左下      
			CGContextMoveToPoint(context, rect.origin.x, rect.origin.y+rect.size.height*7/8);      
			CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y+rect.size.height);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width/8, rect.origin.y+rect.size.height);      

			//右下      
			CGContextMoveToPoint(context, rect.origin.x+rect.size.width*7/8, rect.origin.y+rect.size.height);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height*7/8);    
			}      
		}      
	}      
	[[UIColor greenColor] set];      
	CGContextSetLineWidth(context, 2);      
	CGContextStrokePath(context);      
} 
```

在这段代码的启发下，我对此作了改装，把动态的人脸框，改成了静态的框，这个静态框，就是指示和限定人脸位置的框，根据屏幕大小画出的，代码如下：
```
-(void)drawFixedPointWithPoints:(NSArray *)arrFixed      
{      
	for (NSDictionary *dicPerson in arrFixed) {      
		if ([dicPerson objectForKey:POINTS_KEY]) {      
			for (NSString *strPoints in [dicPerson objectForKey:POINTS_KEY]) {      
				CGPoint p = CGPointFromString(strPoints);      
				CGContextAddEllipseInRect(context, CGRectMake(p.x - 1 , p.y - 1 , 2 , 2));      
			}      
		}      
		if ([dicPerson objectForKey:RECT_KEY]) {      

			CGRect rect=CGRectFromString([dicPerson objectForKey:RECT_KEY]);      
			// 左上      
			CGContextMoveToPoint(context, rect.origin.x, rect.origin.y+rect.size.height/8);      
			CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width/8, rect.origin.y);      

			//右上      
			CGContextMoveToPoint(context, rect.origin.x+rect.size.width*7/8, rect.origin.y);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width, rect.origin.y);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height/8);      

			//左下      
			CGContextMoveToPoint(context, rect.origin.x, rect.origin.y+rect.size.height*7/8);      
			CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y+rect.size.height);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width/8, rect.origin.y+rect.size.height);      

			//右下      
			CGContextMoveToPoint(context, rect.origin.x+rect.size.width*7/8, rect.origin.y+rect.size.height);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);      
			CGContextAddLineToPoint(context, rect.origin.x+rect.size.width, rect.origin.y+rect.size.height*7/8);    
		}      
	}      
	[[UIColor blueColor] set];      
	CGContextSetLineWidth(context, 2);      
	CGContextStrokePath(context);      
} 
```

这里的框是限定脸部位置的，所以脸部位置超出设置的范围的时候，就需要停止人脸识别，停止动作识别，并给出用户提示，提示用户调整位置，或者明确告诉用户，脸部距离屏幕太近了，或者太远了。判定脸部位置的代码如下：
```
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
```

这个方法基于Demo中第三方封装库中给的代理方法-(NSString*)praseDetect:(NSDictionary* )positionDic OrignImage:(IFlyFaceImage*)faceImg;  判断脸部并返回人脸的脸框的坐标，所以利用给的脸部框坐标做判断，超出设置的范围时停止识别。
其中，脸部框两边的坐标左边大于一定值且右边小于一定值的时候，判定为脸部位置“太远了”；同理，脸部框两边的坐标左边小于设定边框点且右边大于设定边框右边点的时候，判定为脸部位置“太近了”；如果位置正确，则脸部位置到达正确位置，这个时候显示脸部各点，并开始活体动作识别：张嘴和摇头。我这里先做张嘴，再做摇头。

## 张嘴识别

张嘴识别，这里的嘴部定点有五个：上、下、左、右、中。这里我取的是上下左右四个点，并判断上下点的距离变化和左右点的距离变化，一开始只判断了上下点距离变化超过设定值得时候就判断为张嘴，后来测试过程中，上下晃动屏幕，会判断失败，直接通过。所以为了解决这个bug，并判断更严谨，加上了左右点的判断，即上下点变化大于设定值并且左右点变化小于设定值的时候判定为张嘴动作识别通过。代码如下：
```
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
```

张嘴动作识别通过后，开始判断摇头动作。

## 摇头识别

摇头识别，这里的摇头动作相比于张嘴动作，摇头动作我没有限制位置，张嘴识别必须在设置的框内完成动作，摇头动作不需要，因为摇头动作幅度大，需要的位置大，如果再限定位置的话，识别要求比较高，不容易识别通过，用户体验差。
摇头识别的思路比较简单，没有做细致的计算分析，仅仅是判断了鼻尖的点的坐标改变大于设定值，即判定为摇头动作通过。代码如下：
```
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
```

其实这样判断摇头是有bug的，左右晃动手机超过一定的距离，也会判定摇头通过，当时时间紧张，没做过多处理，所以就暂时这样判定了。

## 其他细节

判断比较数据，我用了计数法，取得是不同时间点的帧图片上的点的位置并记录下来，然后和初始值做比较，所以如果判断不符合要求，需要清除数据，并重新开始记录并判定。
另外Demo里给出了两种记录动作的方式，一种是有声音的拍照，一种是无声音的截图，可以为人脸的对比做铺垫。

## 尾声

Demo的gitHub地址为：[https://github.com/fuzheng0301/FaceRecognition](https://github.com/fuzheng0301/FaceRecognition)，讲解博客在：[https://www.jianshu.com/p/1b7ae429f14c](https://www.jianshu.com/p/1b7ae429f14c)，如果感觉还可以，感谢点击star，大家的支持是我不断努力源源不断的动力。

