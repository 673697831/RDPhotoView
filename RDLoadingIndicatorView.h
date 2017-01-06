//
//  RDLoadingIndicatorView.h
//  RiceDonate
//
//  Created by ozr on 16/11/18.
//  Copyright © 2016年 ricedonate. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDLoadingIndicatorView : UIView

- (void)startAnimating;
- (void)stopAnimating;
- (void)resetCircleShapeWithPercent:(CGFloat)percent;

@end
