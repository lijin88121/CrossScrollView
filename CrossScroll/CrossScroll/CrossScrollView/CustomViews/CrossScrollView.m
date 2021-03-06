
//
//  CrossScrollView.m
//  Pr2
//
//  Created by Qingxin Xuan on 9/10/12.
//  Copyright (c) 2012 Qingxin Xuan. All rights reserved.
//

#import "CrossScrollView.h"
#import "ItemView.h"
#import "ScrollableItem.h"
#import "ItemAddNew.h"
#import "UIView+Capture.h"

#define SUBVIEW_TAGBASE                     100

#define MIN_HORZGAP                         40.0f
#define MIN_VERTGAP                         40

#define TAG_ADD_NEW                         10000

@implementation CrossScrollView
@synthesize items;

@synthesize horzScrollView;
@synthesize vertScrollView;
@synthesize activeScrollView;
@synthesize activeItemView;
@synthesize inActiveScrollView;

@synthesize shadowView;

@synthesize horzGap;
@synthesize vertGap;

@synthesize horzCount;
@synthesize vertCount;

@synthesize curPage;
@synthesize numberOfPages;

@synthesize isEditing;

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];        
        [self initSubViews];
        [self initGestures];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self initSubViews];
        [self initGestures];        
    }
    return self;
}
    
- (void) initSubViews
{
    if (self.horzScrollView != nil) {
        [self.horzScrollView removeFromSuperview];
        self.horzScrollView = nil;
    }
    
    if (self.vertScrollView != nil) {
        [self.vertScrollView removeFromSuperview];
        self.vertScrollView = nil;
    }   
    
    self.horzScrollView = [[UIScrollView alloc] initWithFrame: self.bounds];
    self.horzScrollView.scrollEnabled = NO;
    self.horzScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview: self.horzScrollView];
    self.vertScrollView = [[UIScrollView alloc] initWithFrame: self.bounds];
    self.vertScrollView.scrollEnabled = NO;    
    self.vertScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;    
    [self addSubview: self.vertScrollView];
}

- (void) initGestures
{
    UISwipeGestureRecognizer* gestureLeft = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(onNext:)]; 
    gestureLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer* gestureUp = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(onNext:)];
    gestureUp.direction = UISwipeGestureRecognizerDirectionUp;
    UISwipeGestureRecognizer* gestureRight = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(onPrev:)];
    gestureRight.direction = UISwipeGestureRecognizerDirectionRight;
    UISwipeGestureRecognizer* gestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget: self action: @selector(onPrev:)];
    gestureDown.direction = UISwipeGestureRecognizerDirectionDown;   
    
    [self addGestureRecognizer: gestureLeft];
    [self addGestureRecognizer: gestureUp];
    [self addGestureRecognizer: gestureRight];
    [self addGestureRecognizer: gestureDown]; 
}

- (void) removeGestures
{
    for (UIGestureRecognizer* gesture in self.gestureRecognizers) {
        [self removeGestureRecognizer: gesture];
    }
}

- (void) layoutSubviews
{
    CGRect rt = self.bounds;
    self.horzScrollView.frame = rt;
    self.vertScrollView.frame = rt;
    
    self.horzCount = rt.size.width / (ITEM_WIDTH + MIN_HORZGAP);
    self.vertCount = rt.size.height / (ITEM_HEIGHT + MIN_VERTGAP);
    
    self.horzGap = rt.size.width / self.horzCount - ITEM_WIDTH;
    self.vertGap = rt.size.height / self.vertCount - ITEM_HEIGHT;    
    
   [self resetLayout];
}

- (void) addItem: (ScrollableItem*) item
{
    if (self.items == nil) {
        self.items = [NSMutableArray array];
    }
    
    NSInteger tag;
    if (![item isKindOfClass: [ItemAddNew class]]) {
        [self.items addObject: item];
        tag = SUBVIEW_TAGBASE + [self.items count] - 1;
    }
    else {
        tag = TAG_ADD_NEW;
    }
    
    ItemView* itemView = [[[NSBundle mainBundle] loadNibNamed: @"ItemView" owner: nil options: nil] objectAtIndex: 0];
    if (itemView) {
        [itemView resetWithItem: item];
        itemView.tag = tag;
    }    
    [self.horzScrollView addSubview: itemView];
    
    UITapGestureRecognizer* gesture = [[UITapGestureRecognizer alloc] initWithTarget:self  action: @selector(onItemSelected:)];
    gesture.numberOfTapsRequired = 1;
    [itemView addGestureRecognizer: gesture];

        
    itemView = [[[NSBundle mainBundle] loadNibNamed: @"ItemView" owner: nil options: nil] objectAtIndex: 0];
    if (itemView) {
        [itemView resetWithItem: item];
        itemView.tag = tag;
    }
    [self.vertScrollView addSubview: itemView];
    gesture = [[UITapGestureRecognizer alloc] initWithTarget:self  action: @selector(onItemSelected:)];
    gesture.numberOfTapsRequired = 1;
    [itemView addGestureRecognizer: gesture];
    
    [NSThread detachNewThreadSelector: @selector(loadImageForIndex:) toTarget: self withObject: [NSNumber numberWithInt: tag]];
}

- (void) loadImageForIndex: (NSNumber*) numberIndex
{
    @autoreleasepool {
        NSInteger tag = [numberIndex intValue];        
        
        ItemView* hItemView = (ItemView*)[self.horzScrollView viewWithTag: tag];
        ItemView* vItemView = (ItemView*)[self.vertScrollView viewWithTag: tag];        

        ScrollableItem* item = hItemView.item;
        if (tag != TAG_ADD_NEW) {
            item = [self.items objectAtIndex: tag - SUBVIEW_TAGBASE];
        }
        
        if (item.thumbnail) {
            [hItemView.imgThumbnail performSelectorOnMainThread: @selector(setImage:) withObject:item.thumbnail waitUntilDone: NO];
            [vItemView.imgThumbnail performSelectorOnMainThread: @selector(setImage:) withObject:item.thumbnail waitUntilDone: NO];
            return;
        }
        
        if (item.thumbnailURL == nil || [item.thumbnailURL length] == 0) {
            item.thumbnail = [UIImage imageNamed: @"no_image.png"];
            [hItemView.imgThumbnail performSelectorOnMainThread: @selector(setImage:) withObject:item.thumbnail waitUntilDone: NO];
            [vItemView.imgThumbnail performSelectorOnMainThread: @selector(setImage:) withObject:item.thumbnail waitUntilDone: NO];
            return;
        }
                
        [hItemView.activity performSelectorOnMainThread: @selector(startAnimating) withObject:nil waitUntilDone: NO];
        [vItemView.activity performSelectorOnMainThread: @selector(startAnimating) withObject:nil waitUntilDone: NO];                
        
        NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: item.thumbnailURL]];
        UIImage* image = [UIImage imageWithData: data];
        if (image == nil) {
            image = [UIImage imageNamed: @"no_image.png"];
        }
        item.thumbnail = image;
        
        [hItemView.imgThumbnail performSelectorOnMainThread: @selector(setImage:) withObject:image waitUntilDone: YES];
        [vItemView.imgThumbnail performSelectorOnMainThread: @selector(setImage:) withObject:image waitUntilDone: YES];

        [hItemView.activity performSelectorOnMainThread: @selector(stopAnimating) withObject:nil waitUntilDone: NO];
        [vItemView.activity performSelectorOnMainThread: @selector(stopAnimating) withObject:nil waitUntilDone: NO];
    }
}

- (void) resetWithItems: (NSMutableArray*) aItems
{
    if ( self.items )
    {
        [self.items removeAllObjects];
    }
    else {
        self.items = [NSMutableArray array];
    }
    
    [self initSubViews];
    for (ScrollableItem* item in aItems) {
        [self addItem: item];
        [NSThread sleepForTimeInterval: 0.01f];
    }
    [self addItem: [ItemAddNew new]];
    
    [self setNeedsLayout];
}

- (void) resetLayout
{
    CGRect rt = self.bounds;
    
    int startX = self.horzGap / 2;
    int startY = self.vertGap / 2;
    
    int count = [self.items count];
    int x=0, y=0;
    int pageItemCount = self.horzCount * self.vertCount;
    self.numberOfPages = (count+1) / pageItemCount + ((count+1)%pageItemCount == 0?0:1);
    
    [self.horzScrollView setContentSize: CGSizeMake(self.numberOfPages * rt.size.width, rt.size.height)];
    [self.horzScrollView setContentOffset: CGPointMake(self.curPage * rt.size.width, 0)];    
    [self.vertScrollView setContentSize: CGSizeMake(rt.size.width, self.numberOfPages * rt.size.height)];
    [self.vertScrollView setContentOffset: CGPointMake(0, self.curPage * rt.size.height)];
    
    for (int i=0; i<count; i++) {
        ItemView* view = (ItemView*)[self.horzScrollView viewWithTag: SUBVIEW_TAGBASE + i];
        if (![view isKindOfClass: [ItemView class]]) {
            continue;
        }
        x = startX + (i%self.horzCount) * (ITEM_WIDTH+self.horzGap) + (i/pageItemCount)* self.horzScrollView.bounds.size.width;
        y = startY + ((i%pageItemCount)/self.horzCount) * (ITEM_HEIGHT+self.vertGap);
        view.frame = CGRectMake(x, y, ITEM_WIDTH, ITEM_HEIGHT);
        
        view = (ItemView*)[self.vertScrollView viewWithTag: SUBVIEW_TAGBASE + i];
        if (![view isKindOfClass: [ItemView class]]) {
            continue;
        }
        x = startX + (i%self.horzCount) * (ITEM_WIDTH+self.horzGap);
        y = startY + (i/self.horzCount) * (ITEM_HEIGHT+self.vertGap);
        view.frame = CGRectMake(x, y, ITEM_WIDTH, ITEM_HEIGHT);
    }
    
    ItemView* view = (ItemView*)[self.horzScrollView viewWithTag: TAG_ADD_NEW];
    if (![view isKindOfClass: [ItemView class]]) {
        return;
    }
    x = startX + (count%self.horzCount) * (ITEM_WIDTH+self.horzGap) + (count/pageItemCount)* self.horzScrollView.bounds.size.width;
    y = startY + ((count%pageItemCount)/self.horzCount) * (ITEM_HEIGHT+self.vertGap);
    view.frame = CGRectMake(x, y, ITEM_WIDTH, ITEM_HEIGHT);

    view = (ItemView*)[self.vertScrollView viewWithTag: TAG_ADD_NEW];
    if (![view isKindOfClass: [ItemView class]]) {
        return;
    }
    x = startX + (count%self.horzCount) * (ITEM_WIDTH+self.horzGap);
    y = startY + (count/self.horzCount) * (ITEM_HEIGHT+self.vertGap);
    view.frame = CGRectMake(x, y, ITEM_WIDTH, ITEM_HEIGHT);
}

- (void) onNext: (UISwipeGestureRecognizer*) gesture
{
    if (self.horzScrollView == nil || self.vertScrollView == nil) {
        return;
    }
    
    if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
        self.vertScrollView.hidden = YES;
        self.horzScrollView.hidden = NO;
    }
    else {
        self.vertScrollView.hidden = NO;
        self.horzScrollView.hidden = YES;
    }
    
    if (self.curPage >= self.numberOfPages - 1) {
        self.curPage = self.numberOfPages - 1;
        return;
    }
    
    self.curPage += 1;
    CGRect rt = self.bounds;
    [self.horzScrollView setContentOffset: CGPointMake(self.curPage * rt.size.width, 0) animated: YES];    
    [self.vertScrollView setContentOffset: CGPointMake(0, self.curPage * rt.size.height) animated: YES];
}

- (void) onPrev: (UISwipeGestureRecognizer*) gesture
{
    if (self.horzScrollView == nil || self.vertScrollView == nil) {
        return;
    }

    if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
        self.vertScrollView.hidden = YES;
        self.horzScrollView.hidden = NO;
    }
    else {
        self.vertScrollView.hidden = NO;
        self.horzScrollView.hidden = YES;
    }
    
    if (self.curPage <= 0) {
        self.curPage = 0;
        return;
    }
    
    self.curPage -= 1;
    CGRect rt = self.bounds;
    [self.horzScrollView setContentOffset: CGPointMake(self.curPage * rt.size.width, 0) animated: YES];
    [self.vertScrollView setContentOffset: CGPointMake(0, self.curPage * rt.size.height) animated: YES];
}

- (void) onItemSelected: (UITapGestureRecognizer*) gesture
{
    ItemView* itemView = (ItemView*)gesture.view;
    if (self.delegate && [self.delegate respondsToSelector: @selector(itemSelected:)]) {
        [self.delegate itemSelected: itemView.item];
    }
    NSLog( @"%d selected", itemView.tag);
}

- (void) setIsEditing:(BOOL) bIsEditing
{
    isEditing = bIsEditing;
    if (isEditing) {
        self.horzScrollView.userInteractionEnabled = NO;
        self.vertScrollView.userInteractionEnabled = NO;
        [self removeGestures];
    }
    else {
        [self initGestures];
        self.horzScrollView.userInteractionEnabled = YES;
        self.vertScrollView.userInteractionEnabled = YES;        
    }
}

- (ItemView*) itemViewAtPoint: (CGPoint) pt inView: (UIView*) view
{
    for (UIView* subView in view.subviews) 
    {
        if ([subView isKindOfClass: [ItemView class]]) {
            if (CGRectContainsPoint(subView.frame, pt)) {
                return (id)subView;
            }
        }
    }
    return nil;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.isEditing == NO) 
    {
        return;
    }
        
    if (self.horzScrollView.hidden == NO) {
        self.activeScrollView = self.horzScrollView;
        self.inActiveScrollView = self.vertScrollView;
    }    
    else {
        self.activeScrollView = self.vertScrollView;
        self.inActiveScrollView = self.horzScrollView;
    }
 
    UITouch* touch = [touches anyObject];
    CGPoint pt = [touch locationInView: self];
    pt.x += self.activeScrollView.contentOffset.x;
    pt.y += self.activeScrollView.contentOffset.y;
    self.activeItemView = [self itemViewAtPoint: pt inView: self.activeScrollView];
    
    if (self.activeItemView == nil || [self.activeItemView.item isKindOfClass: [ItemAddNew class]]) {
        self.activeItemView = nil;
        return;
    }

    if (self.shadowView == nil) {        
        self.shadowView = [[UIImageView alloc] initWithImage: [self.activeItemView captureImage]];
        self.shadowView.alpha = 0.7f;
        [self addSubview: self.shadowView];
    }
    else {
        self.shadowView.image = [self.activeItemView captureImage];
        self.shadowView.hidden = NO;
        [self bringSubviewToFront: self.shadowView];
    }
    
    CGRect rt = self.activeItemView.frame;
    rt.origin = CGPointMake(rt.origin.x - self.activeScrollView.contentOffset.x, rt.origin.y - self.activeScrollView.contentOffset.y);
    self.shadowView.frame = rt;
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.isEditing == NO) {
        return;
    }
    
    if (self.activeItemView == nil) {
        return;
    }
    
    UITouch* touch = [touches anyObject];
    CGPoint pt = [touch locationInView: self];    
    CGPoint ptPrev = [touch previousLocationInView: self];
    CGRect rt = self.shadowView.frame;
    rt.origin = CGPointMake(rt.origin.x + pt.x - ptPrev.x, rt.origin.y + pt.y - ptPrev.y);
    self.shadowView.frame = rt;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.isEditing == NO) {
        return;
    }
    
    if (self.activeItemView == nil) {
        return;
    }

    UITouch* touch = [touches anyObject];
    CGPoint pt = [touch locationInView: self];
    pt.x += self.activeScrollView.contentOffset.x;
    pt.y += self.activeScrollView.contentOffset.y;
    ItemView* targetView = [self itemViewAtPoint: pt inView: self.activeScrollView];  

    if (targetView != nil &&  ![targetView.item isKindOfClass: [ItemAddNew class]]) {
        [self.activeScrollView bringSubviewToFront: targetView];
        CGRect sourceRect = self.activeItemView.frame;
        self.activeItemView.frame = targetView.frame;
        [UIView beginAnimations: @"SWAP" context: nil];
        [UIView setAnimationDuration: 0.3f];
        targetView.frame = sourceRect;
        [UIView commitAnimations];
        int targetTag = targetView.tag;
        int sourceTag = self.activeItemView.tag;
        [self swapItemViewsWithTags: sourceTag : targetTag inView: self.inActiveScrollView];
        self.activeItemView.tag = targetTag;
        targetView.tag = sourceTag;
    }
    
    self.activeItemView = nil;
    self.shadowView.hidden = YES;
}

- (void) swapItemViewsWithTags: (int) sourceTag: (int) targetTag inView: (UIView*) container
{
    ItemView* srcView = (id)[container viewWithTag: sourceTag];
    ItemView* dstView = (id)[container viewWithTag: targetTag];
    CGRect rt = srcView.frame;
    srcView.frame = dstView.frame;
    dstView.frame = rt;
    
    srcView.tag = targetTag;
    dstView.tag = sourceTag;
}

@end
