//
//  VIDefaultPagingAccessory.m
//  PagingCoreData
//
//  Created by teejay on 1/21/14.
//
//

#import "VIDefaultPagingAccessory.h"

@interface VIDefaultPagingAccessory ()

@property UIActivityIndicatorView *indicator;

@end

@implementation VIDefaultPagingAccessory

- (void)didMoveToSuperview
{
    if (self.superview) {
        self.clipsToBounds = YES;
        [self setBackgroundColor:[UIColor clearColor]];
        
        UILabel *label = [[UILabel alloc] initWithFrame:(CGRect){CGPointZero, self.frame.size}];
        [label setText:@"Pull To Load"];
        [label setFont:[UIFont boldSystemFontOfSize:20]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:label];
        [label sizeToFit];
        [label setCenter:CGPointMake(self.frame.size.width/2, self.frame.size.height/2)];
        
        self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.indicator setTintColor:[UIColor blackColor]];
        [self.indicator setHidesWhenStopped:NO];
        
        [self.indicator setCenter:CGPointMake(label.frame.origin.x - self.indicator.frame.size.width, self.frame.size.height/2)];
        [self addSubview:self.indicator];
    } else {
        [self cleanUp];
    }
}

- (void)cleanUp
{
    [self.indicator stopAnimating];
    [self.indicator removeFromSuperview];
    
    self.indicator = nil;
}


- (void)loadingHasFinished
{
    [self.indicator stopAnimating];
}

- (void)loadingWillBegin
{
    [self.indicator startAnimating];
}

- (void)hasOverScrolled:(CGFloat)overScrollPercent
{
    [self.indicator setAlpha:overScrollPercent];
}

@end
