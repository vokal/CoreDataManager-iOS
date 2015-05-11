//
//  VITableViewPagingManager.m
//  SkillzSDK-iOS
//
//  Created by TJ Fallon on 3/19/15.
//  Copyright (c) 2015 Skillz. All rights reserved.
//

#import "VITableViewPagingManager.h"
#import "VIDefaultPagingAccessory.h"

#pragma mark Delegate Interceptor

@interface VIDelegateMessageInterceptor : NSObject

@property (nonatomic, assign) id initialReceiver;
@property (nonatomic, assign) id insertedMiddleMan;

@end

@implementation VIDelegateMessageInterceptor

- (id)initWithInitialReceiver:(id)receiver andNewMiddleMan:(id)middleMan
{
    self = [super init];

    if (self) {
        _initialReceiver = receiver;
        _insertedMiddleMan = middleMan;
    }

    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.insertedMiddleMan respondsToSelector:aSelector]) { return self.insertedMiddleMan; }
    if ([self.initialReceiver respondsToSelector:aSelector]) { return self.initialReceiver; }

    return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector {

    if ([self.insertedMiddleMan respondsToSelector:aSelector]) { return YES; }
    if ([self.initialReceiver respondsToSelector:aSelector]) { return YES; }

    return [super respondsToSelector:aSelector];
}

@end

#pragma mark Paging Manager

@interface VITableViewPagingManager () <UIScrollViewDelegate>

@property (strong) UITableView *tableView;

@property (copy) VIPagingResultsAction upAction;
@property (copy) VIPagingResultsAction downAction;

@property UIView<VIPagingAccessory> *headerView;
@property UIView<VIPagingAccessory> *footerView;

@property VIDelegateMessageInterceptor *delegateInterceptor;

@property BOOL isLoading;
@property CGFloat triggerDistance;
@property UIEdgeInsets orginalInsets;

@end

@implementation VITableViewPagingManager

- (id)initWithTableView:(UITableView *)tableView
{
    self = [super init];

    if (self) {
        _tableView = tableView;
        _delegateInterceptor = [[VIDelegateMessageInterceptor alloc] initWithInitialReceiver:tableView.delegate
                                                                             andNewMiddleMan:self];
        [tableView setDelegate:(id<UITableViewDelegate>)_delegateInterceptor];
    }

    return self;
}

#pragma mark Setup
- (void)setupForTriggerDistance:(CGFloat)overscrollTriggerDistance
                       upAction:(VIPagingResultsAction)upPageActionOrNil
                     headerView:(UIView<VIPagingAccessory> *)headerViewOrNil
                     downAction:(VIPagingResultsAction)downPageActionOrNil
                     footerView:(UIView<VIPagingAccessory> *)footerViewOrNil;
{
    [self cleanUpPagingManager];

    self.upAction = upPageActionOrNil;
    self.downAction = downPageActionOrNil;

    self.headerView = headerViewOrNil;
    self.footerView = footerViewOrNil;

    self.isLoading = NO;

    self.triggerDistance = overscrollTriggerDistance;
    self.orginalInsets = self.tableView.contentInset;

    [self setupAccessoryViews];
}

- (void)setupAccessoryViews
{
    //Attach given views, or generate default views.
    if (!self.headerView && self.upAction) {
        self.headerView = [[VIDefaultPagingAccessory alloc] initWithFrame:(CGRect){0, -30, self.tableView.frame.size.width, 30}];
    }

    [self.headerView setFrame:(CGRect){0, -self.headerView.frame.size.height, self.headerView.frame.size}];
    [self.tableView addSubview:self.headerView];

    if (!self.footerView && self.downAction) {
        self.footerView = [[VIDefaultPagingAccessory alloc] initWithFrame:(CGRect){0,
            MAX(self.tableView.contentSize.height, self.tableView.bounds.size.height),
            self.tableView.frame.size.width, 30}];
    }

    [self.tableView addSubview:self.footerView];

    [self.tableView addObserver:self
                     forKeyPath:@"contentSize"
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior
                        context:NULL];
}

- (void)cleanUpPagingManager
{
    if (self.headerView || self.footerView) {
        [self.headerView removeFromSuperview];
        [self.footerView removeFromSuperview];

        self.headerView = nil;
        self.footerView = nil;
    }
}

#pragma mark Scrollview Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"]) {
        [self.footerView setFrame:(CGRect){0, MAX(self.tableView.contentSize.height,
                                                  self.tableView.bounds.size.height),
            self.footerView.frame.size}];
    }
}

#pragma mark Scrollview Delegates

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!self.isLoading) {
        //Calculate scrollable height
        CGFloat contentHeight = scrollView.contentSize.height;
        CGFloat scrollableHeight = contentHeight - CGRectGetHeight(scrollView.bounds);

        if (scrollView.contentOffset.y > (scrollableHeight + self.triggerDistance) &&
            contentHeight > CGRectGetHeight(scrollView.bounds) &&
            self.downAction)
        {

            UIEdgeInsets newInsets = self.orginalInsets;
            newInsets.bottom += self.footerView.frame.size.height;

            [self triggerAction:self.downAction forAccessoryView:self.footerView withInsets:newInsets];
        }

        CGFloat topOffset = scrollView.contentOffset.y - scrollView.contentInset.top;
        if (topOffset < (-self.triggerDistance) && self.upAction) {

            UIEdgeInsets newInsets = self.orginalInsets;
            newInsets.top += CGRectGetHeight(self.headerView.frame);

            [self triggerAction:self.upAction forAccessoryView:self.headerView withInsets:newInsets];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.isLoading) {
        //Calculate scrollable height
        CGFloat contentHeight = scrollView.contentSize.height;
        CGFloat scrollableHeight = contentHeight - scrollView.bounds.size.height;

        CGFloat topOffset = scrollView.contentOffset.y + scrollView.contentInset.top;

        if (topOffset > scrollableHeight) {
            CGFloat distanceOverscrolled = topOffset - scrollableHeight;
            [self.footerView hasOverScrolled:(distanceOverscrolled/self.triggerDistance)];
        } else {
            [self.footerView hasOverScrolled:0.0];
        }

        if (topOffset < 0) {
            [self.headerView hasOverScrolled:(fabsf(topOffset)/self.triggerDistance)];
        } else {
            [self.headerView hasOverScrolled:0.0];
        }
    }
}

#pragma mark Trigger Calls

- (void)triggerAction:(VIPagingResultsAction)action
     forAccessoryView:(UIView<VIPagingAccessory> *)accessory
           withInsets:(UIEdgeInsets)insets
{
    self.isLoading = YES;
    [self.tableView setUserInteractionEnabled:NO];

    [accessory loadingWillBegin];

    [UIView animateWithDuration:.3 animations:^{
        [self.tableView setContentInset:insets];
    } completion:^(BOOL finished) {
        VICompletionAction completionAction = ^void (void)
        {
            self.isLoading = NO;
            [accessory loadingHasFinished];

            [self.tableView setUserInteractionEnabled:YES];
            [UIView animateWithDuration:.3 animations:^{
                [self.tableView setContentInset:self.orginalInsets];
            }];
        };

        action(self.tableView, completionAction);
    }];
}

- (void)dealloc
{
    if (self.upAction || self.downAction) {
        self.upAction = nil;
        self.downAction = nil;
    }

    if (self.tableView) {
        [self.tableView removeObserver:self forKeyPath:@"contentSize"];
        self.tableView = nil;
    }

    CDLog(@"Paging manager dealloc'd %@", self);
}
@end
