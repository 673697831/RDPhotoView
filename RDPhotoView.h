//
//  RDPhotoView.h
//  RiceDonate
//
//  Created by ozr on 15/12/14.
//  Copyright © 2015年 ricedonate. All rights reserved.
//

#import "RDCustomAlertView.h"


@interface RDPhotoView : RDCustomAlertView

- (instancetype)initWithImageUrlList:(NSArray *)imageUrlList//要显示放大的远程图片url
                          imageViews:(NSArray *)imageViews//缩略图所在窗口 数组里面类型是UIImageView *
                               index:(NSInteger)index;//一开始点击的是第几个窗口

@end
