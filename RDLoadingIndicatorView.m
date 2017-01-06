//
//  RDLoadingIndicatorView.m
//  RiceDonate
//
//  Created by ozr on 16/11/18.
//  Copyright © 2016年 ricedonate. All rights reserved.
//

#import "RDLoadingIndicatorView.h"

static NSString* const kRotationKey = @"rotation";
static NSString* const kStrokeEndKey = @"strokeEnd";
static NSString* const kStrokeStartKey = @"strokeStart";
static NSString* const kTransformKey = @"transform";
static NSString* const kStrokeColorKey = @"strokeColor";
static CGFloat const kMinStrokeLength = 0.05;
static CGFloat const kMaxStrokeLength = 0.7;

@interface RDLoadingIndicatorView ()

@property (nonatomic, weak) CAShapeLayer *circleShapeLayer;
@property (nonatomic, weak) CAShapeLayer *presentLayer;

@end

@implementation RDLoadingIndicatorView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        //[self initShapeLayer];
    }
    
    return self;
}

- (void)resetCircleShapeWithPercent:(CGFloat)percent
{
    if (self.presentLayer) {
        [self.presentLayer removeFromSuperlayer];
        self.presentLayer = nil;
    }
    
    CAShapeLayer *layer = [CAShapeLayer new];
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor colorWithHexString:@"c0c4cc"].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.lineWidth = 3;
    layer.lineCap = kCALineCapRound;
    layer.strokeStart = 0;
    layer.strokeEnd = kMaxStrokeLength * percent;
    CGPoint center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    layer.frame = self.bounds;
    layer.path = [UIBezierPath bezierPathWithArcCenter:center
                                                radius:center.x
                                            startAngle:-M_PI/2
                                              endAngle:M_PI + M_PI/2
                                             clockwise:YES].CGPath;
    [self.layer addSublayer:layer];
    self.presentLayer = layer;
}

- (void)initShapeLayer
{
    CAShapeLayer *layer = [CAShapeLayer new];
    layer.actions = @
    {
        kStrokeEndKey:[NSNull null],
        kStrokeStartKey:[NSNull null],
        kTransformKey:[NSNull null],
        kStrokeColorKey:[NSNull null],
    };
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor colorWithHexString:@"c0c4cc"].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.lineWidth = 3;
    layer.lineCap = kCALineCapRound;
    layer.strokeStart = 0;
    layer.strokeEnd = kMinStrokeLength;
    CGPoint center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    layer.frame = self.bounds;
    layer.path = [UIBezierPath bezierPathWithArcCenter:center
                                                radius:center.x
                                            startAngle:-M_PI/2
                                              endAngle:M_PI + M_PI/2
                                             clockwise:YES].CGPath;
    [self.layer addSublayer:layer];
    _circleShapeLayer = layer;
}

- (void)startAnimating
{
    if (self.presentLayer) {
        [self.presentLayer removeFromSuperlayer];
        self.presentLayer = nil;
    }
    
    if (self.circleShapeLayer == nil) {
        [self initShapeLayer];
    }
    
    if ([self.layer animationForKey:kRotationKey] == nil) {
        //[self startColorAnimation];
        [self startStrokeAnimation];
        [self startRotatingAnimation];
    }
}

- (void)startColorAnimation
{
    CAKeyframeAnimation *color = [CAKeyframeAnimation animationWithKeyPath:kStrokeColorKey];
    color.duration = 10;
    color.values = @
    [
        (id)([UIColor colorWithHexString:@"4285F4"].CGColor),
        (id)([UIColor colorWithHexString:@"DE3E35"].CGColor),
        (id)([UIColor colorWithHexString:@"F7C223"].CGColor),
        (id)([UIColor colorWithHexString:@"1B9A59"].CGColor),
        (id)([UIColor colorWithHexString:@"4285F4"].CGColor),
    ];
    
    color.calculationMode = kCAAnimationPaced;
    color.repeatCount = INFINITY;
    [self.circleShapeLayer addAnimation:color
                                 forKey:@"color"];
}

- (void)startStrokeAnimation
{
    CAMediaTimingFunction *easeInOutSineTimingFunc = [CAMediaTimingFunction functionWithControlPoints:0.39 :0.575 :0.565 :1.0];
    CGFloat progress = kMaxStrokeLength;
    CGFloat endFromValue = self.circleShapeLayer.strokeEnd;
    CGFloat endToValue = endFromValue + progress;
    CABasicAnimation *strokeEnd = [CABasicAnimation animationWithKeyPath:kStrokeEndKey];
    strokeEnd.fromValue = @(endFromValue);
    strokeEnd.toValue = @(endToValue);
    strokeEnd.duration = 0.5;
    strokeEnd.fillMode              = kCAFillModeForwards;
    strokeEnd.timingFunction        = easeInOutSineTimingFunc;
    strokeEnd.beginTime             = 0.1;
    strokeEnd.removedOnCompletion   = NO;
    CGFloat startFromValue = self.circleShapeLayer.strokeStart;
    CGFloat startToValue = fabs(endToValue - kMinStrokeLength);
    CABasicAnimation *strokeStart = [CABasicAnimation animationWithKeyPath:kStrokeStartKey];
    strokeStart.fromValue = @(startFromValue);
    strokeStart.toValue = @(startToValue);
    strokeStart.duration = 0.4;
    strokeStart.fillMode            = kCAFillModeForwards;
    strokeStart.timingFunction      = easeInOutSineTimingFunc;
    strokeStart.beginTime           = strokeEnd.beginTime + strokeEnd.duration + 0.2;
    strokeStart.removedOnCompletion = NO;
    
    CAAnimationGroup *pathAnim   = [CAAnimationGroup new];
    pathAnim.animations          = @[strokeEnd, strokeStart];
    pathAnim.duration            = strokeStart.beginTime + strokeStart.duration;
    pathAnim.fillMode            = kCAFillModeForwards;
    pathAnim.removedOnCompletion = NO;
    
    NSLog(@"startStrokeAnimation endFromValue = %f, endToValue = %f, startFromValue = %f, startToValue = %f", endFromValue, endToValue, startFromValue, startToValue);
    
    [CATransaction begin];
    @weakify(self);
    [CATransaction setCompletionBlock:^{
        @strongify(self);
        if ([self.circleShapeLayer animationForKey:@"stroke"]) {
            self.circleShapeLayer.transform = CATransform3DRotate(self.circleShapeLayer.transform, M_PI * 2* progress, 0, 0, 1);
            [self.circleShapeLayer removeAnimationForKey:@"stroke"];
            [self startStrokeAnimation];
        }
    }];
    [self.circleShapeLayer addAnimation:pathAnim
                                 forKey:@"stroke"];
    [CATransaction commit];
}

//- (void)startStrokeAnimation
//{
//    CAMediaTimingFunction *easeInOutSineTimingFunc = [CAMediaTimingFunction functionWithControlPoints:0.39 :0.575 :0.565 :1.0];
//    CGFloat progress = kMaxStrokeLength;
//    CGFloat endFromValue = self.circleShapeLayer.strokeEnd;
//    CGFloat endToValue = endFromValue + progress;
//    CABasicAnimation *strokeEnd = [CABasicAnimation animationWithKeyPath:kStrokeEndKey];
//    strokeEnd.fromValue = @(endToValue);
//    strokeEnd.toValue = @(endToValue);
//    strokeEnd.duration = 0.5;
//    strokeEnd.fillMode              = kCAFillModeForwards;
//    strokeEnd.timingFunction        = easeInOutSineTimingFunc;
//    strokeEnd.beginTime             = .1;
//    strokeEnd.removedOnCompletion   = NO;
//    CGFloat startFromValue = self.circleShapeLayer.strokeStart;
//    CGFloat startToValue = fabs(endToValue - kMinStrokeLength);
//    CABasicAnimation *strokeStart = [CABasicAnimation animationWithKeyPath:kStrokeStartKey];
//    strokeStart.fromValue = @(startFromValue);
//    strokeStart.toValue = @(startToValue);
//    strokeStart.duration = 10;
//    strokeStart.fillMode            = kCAFillModeForwards;
//    strokeStart.timingFunction      = easeInOutSineTimingFunc;
//    strokeStart.beginTime           = strokeEnd.beginTime + strokeEnd.duration + .2;
//    strokeStart.removedOnCompletion = NO;
//    
//    CAAnimationGroup *pathAnim   = [CAAnimationGroup new];
//    pathAnim.animations          = @[strokeStart];
//    pathAnim.duration            = strokeStart.beginTime + strokeStart.duration;
//    pathAnim.fillMode            = kCAFillModeForwards;
//    pathAnim.removedOnCompletion = NO;
//    
//    NSLog(@"startStrokeAnimation endFromValue = %f, endToValue = %f, startFromValue = %f, startToValue = %f", endFromValue, endToValue, startFromValue, startToValue);
//    
//    [CATransaction begin];
//    @weakify(self);
//    [CATransaction setCompletionBlock:^{
//        @strongify(self);
//        if ([self.circleShapeLayer animationForKey:@"stroke"]) {
//            self.circleShapeLayer.transform = CATransform3DRotate(self.circleShapeLayer.transform, M_PI * 2 * progress, 0, 0, 1);
//            [self.circleShapeLayer removeAnimationForKey:@"stroke"];
//            [self startStrokeAnimation];
//        }
//    }];
//    [self.circleShapeLayer addAnimation:pathAnim
//                                 forKey:@"stroke"];
//    [CATransaction commit];
//}

- (void)startRotatingAnimation
{
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI*2);
    rotation.duration = 2.2;
    rotation.cumulative = YES;
    rotation.additive = YES;
    rotation.repeatCount = INFINITY;
    [self.layer addAnimation:rotation
                      forKey:@"rotation"];
}

- (void)stopAnimating
{
    [self.circleShapeLayer removeAllAnimations];
    [self.layer removeAllAnimations];
    self.circleShapeLayer.transform = CATransform3DIdentity;
    self.layer.transform = CATransform3DIdentity;
    [self.circleShapeLayer removeFromSuperlayer];
}

/*

let view      = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
let indicator = MaterialLoadingIndicator(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
indicator.center = CGPoint(x: 320*0.5, y: 568*0.5)
view.addSubview(indicator)
XCPlaygroundPage.currentPage.liveView = view
indicator.startAnimating()
 
*/

@end
