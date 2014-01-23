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
        [label setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:18]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setTextColor:[UIColor darkGrayColor]];
        [label setShadowColor:[[UIColor whiteColor] colorWithAlphaComponent:.4]];
        [label setShadowOffset:CGSizeMake(0, 1)];
        [self addSubview:label];
        [label sizeToFit];
        [label setCenter:CGPointMake(self.frame.size.width/2, self.frame.size.height/2)];
        
        self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.indicator setTintColor:[UIColor blackColor]];
        [self.indicator setHidesWhenStopped:NO];
        
        [self.indicator setCenter:CGPointMake(label.frame.origin.x - self.indicator.frame.size.width, self.frame.size.height/2)];
        [self addSubview:self.indicator];
    }
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
