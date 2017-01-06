//
//  RDPhotoView.h
//  RiceDonate
//
//  Created by ozr on 15/12/14.
//  Copyright © 2015年 ricedonate. All rights reserved.
//

#import "RDCustomAlertView.h"

@interface RDPhotoView : RDCustomAlertView

- (instancetype)initWithImageUrlList:(NSArray *)imageUrlList imageViews:(NSArray *)imageViews index:(NSInteger)index;

@end
