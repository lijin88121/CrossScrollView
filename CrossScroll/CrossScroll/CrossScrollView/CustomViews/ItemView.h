//
//  ItemView.h
//  Pr2
//
//  Created by Qingxin Xuan on 9/10/12.
//  Copyright (c) 2012 Qingxin Xuan. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ITEM_WIDTH                      200
#define ITEM_HEIGHT                     280

@class ScrollableItem;
@interface ItemView : UIView
@property (nonatomic, strong) IBOutlet UIImageView*                 imgThumbnail;
@property (nonatomic, strong) IBOutlet UILabel*                     lblTitle;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView*     activity;
@property (nonatomic, strong) ScrollableItem*                       item;

- (void) resetWithItem: (ScrollableItem*) sItem;
@end
