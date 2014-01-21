//
//  VIDefaultPagingAccessoryView.m
//  SkillzSDK-iOS
//
//  Created by teejay on 1/21/14.
//  Copyright (c) 2014 Skillz. All rights reserved.
//

#import "VIDefaultPagingAccessoryView.h"

#define REFRESH_CONTROL_HEIGHT 65.0f

#define HALF_REFRESH_CONTROL_HEIGHT (REFRESH_CONTROL_HEIGHT / 2.0f)

#define DEFAULT_FOREGROUND_COLOR [UIColor whiteColor]
#define DEFAULT_BACKGROUND_COLOR [UIColor colorWithWhite:0.10f alpha:1.0f]

#define DEFAULT_TOTAL_HORIZONTAL_TRAVEL_TIME_FOR_BALL 0.75f

typedef enum {
    BOZPongRefreshControlStateIdle = 0,
    BOZPongRefreshControlStateRefreshing = 1,
    BOZPongRefreshControlStateResetting = 2
} BOZPongRefreshControlState;

@interface VIDefaultPagingAccessoryView ()


@property UIView *leftPaddleView;
@property UIView *rightPaddleView;
@property UIView *ballView;
@property UIView *coverView;
@property UIView *gameView;

@property (nonatomic) UIColor *foregroundColor;

@property CGPoint leftPaddleIdleOrigin;
@property CGPoint rightPaddleIdleOrigin;
@property CGPoint ballIdleOrigin;

@property CGPoint ballOrigin;
@property CGPoint ballDestination;
@property CGPoint ballDirection;

@property CGFloat leftPaddleDestination;
@property CGFloat rightPaddleDestination;

@property CGFloat totalHorizontalTravelTimeForBall;

@end

@implementation VIDefaultPagingAccessoryView

- (void)didMoveToSuperview
{
    if (self.superview) {
        self.clipsToBounds = YES;
        self.foregroundColor = DEFAULT_FOREGROUND_COLOR;
        self.backgroundColor = DEFAULT_BACKGROUND_COLOR;
        [self setUpCoverViewAndGameView];
        [self setUpPaddles];
        [self setUpBall];
    }
}

- (void)loadingHasFinished
{
    [UIView animateWithDuration:0.2f animations:^(void) {
        self.coverView.center = CGPointMake(self.gameView.frame.size.width / 2.0f, (self.gameView.frame.size.height / 2.0f));
    } completion:^(BOOL finished) {
        [self resetPaddlesAndBall];
    }];
    
}

- (void)loadingWillBegin
{
    [self startPong];
}

- (void)hasOverScrolled:(CGFloat)overScrollPercent
{
    CGFloat rawOffset = -(overScrollPercent * REFRESH_CONTROL_HEIGHT);
    if (rawOffset == 0) {
        
        [self loadingHasFinished];
        
    } else if (overScrollPercent <= 1){
        
        [self offsetCoverAndGameViewBy:rawOffset];
        
        CGFloat ballAndPaddlesOffset = MIN(rawOffset / 2.0f, HALF_REFRESH_CONTROL_HEIGHT);
        [self offsetBallAndPaddlesBy:ballAndPaddlesOffset];
        [self rotatePaddlesAccordingToOffset:ballAndPaddlesOffset];
    }
}


#pragma mark PONG STUFF BELOW

- (void)setIsFooter:(BOOL)isFooter
{
    if (isFooter) {
        [self setTransform:CGAffineTransformMakeRotation(M_PI)];
    } else {
        [self setTransform:CGAffineTransformIdentity];
    }
}

- (void)setUpCoverViewAndGameView
{
    self.gameView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    self.gameView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.gameView];
    
    self.coverView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    self.coverView.backgroundColor = self.superview.backgroundColor;
    [self.gameView addSubview:self.coverView];
}

- (void)setUpPaddles
{
    self.leftPaddleIdleOrigin = CGPointMake(self.gameView.frame.size.width * 0.25f, self.gameView.frame.size.height);
    self.leftPaddleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, 15.0f)];
    self.leftPaddleView.center = self.leftPaddleIdleOrigin;
    self.leftPaddleView.backgroundColor = self.foregroundColor;
    
    self.rightPaddleIdleOrigin = CGPointMake(self.gameView.frame.size.width * 0.75f, self.gameView.frame.size.height);
    self.rightPaddleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, 15.0f)];
    self.rightPaddleView.center = self.rightPaddleIdleOrigin;
    self.rightPaddleView.backgroundColor = self.foregroundColor;
    
    [self.gameView addSubview:self.leftPaddleView];
    [self.gameView addSubview:self.rightPaddleView];
}

- (void)setUpBall
{
    self.ballIdleOrigin = CGPointMake(self.gameView.frame.size.width * 0.50f, 0.0f);
    self.ballView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 3.0f, 3.0f)];
    self.ballView.center = self.ballIdleOrigin;
    self.ballView.backgroundColor = self.foregroundColor;
    
    self.totalHorizontalTravelTimeForBall = DEFAULT_TOTAL_HORIZONTAL_TRAVEL_TIME_FOR_BALL;
    
    [self.gameView addSubview:self.ballView];
}

- (void)setForegroundColor:(UIColor*)foregroundColor
{
    _foregroundColor = foregroundColor;
    
    self.leftPaddleView.backgroundColor = foregroundColor;
    self.rightPaddleView.backgroundColor = foregroundColor;
    self.ballView.backgroundColor = foregroundColor;
}

- (void)resetPaddlesAndBall
{
    [self.leftPaddleView.layer removeAllAnimations];
    [self.rightPaddleView.layer removeAllAnimations];
    [self.ballView.layer removeAllAnimations];
    
    self.leftPaddleView.center = self.leftPaddleIdleOrigin;
    self.rightPaddleView.center = self.rightPaddleIdleOrigin;
    self.ballView.center = self.ballIdleOrigin;
}


- (void)offsetCoverAndGameViewBy:(CGFloat)offset
{
    CGFloat offsetConsideringState = offset;
    
    //[self updateHeightOfRefreshControl:offsetConsideringState];
    [self stickGameViewToBottomOfRefreshControl];
    
    self.coverView.center = CGPointMake(self.gameView.frame.size.width / 2.0f, (self.gameView.frame.size.height / 2.0f) - offsetConsideringState);
}

- (void)updateHeightOfRefreshControl:(CGFloat)offset
{
    CGRect newFrame = self.frame;
    newFrame.size.height = offset;
    newFrame.origin.y = -offset;
    self.frame = newFrame;
}

- (void)stickGameViewToBottomOfRefreshControl
{
    CGRect newGameViewFrame = self.gameView.frame;
    newGameViewFrame.origin.y = self.frame.size.height - self.gameView.frame.size.height;
    self.gameView.frame = newGameViewFrame;
}

- (void)offsetBallAndPaddlesBy:(CGFloat)offset
{
    self.ballView.center = CGPointMake(self.ballIdleOrigin.x, self.ballIdleOrigin.y + offset);
    self.leftPaddleView.center = CGPointMake(self.leftPaddleIdleOrigin.x, self.leftPaddleIdleOrigin.y - offset);
    self.rightPaddleView.center = CGPointMake(self.rightPaddleIdleOrigin.x, self.rightPaddleIdleOrigin.y - offset);
}

- (void)rotatePaddlesAccordingToOffset:(CGFloat)offset
{
    CGFloat proportionOfMaxOffset = (offset / HALF_REFRESH_CONTROL_HEIGHT);
    CGFloat angleToRotate = M_PI * proportionOfMaxOffset;
    
    self.leftPaddleView.transform = CGAffineTransformMakeRotation(angleToRotate);
    self.rightPaddleView.transform = CGAffineTransformMakeRotation(-angleToRotate);
}


#pragma mark - Playing pong

#pragma mark Starting the game

- (void)startPong
{
    self.ballOrigin = self.ballView.center;
    [self pickRandomStartingBallDestination];
    [self determineNextPaddleDestinations];
    [self animateBallAndPaddlesToDestinations];
}

- (void)pickRandomStartingBallDestination
{
    CGFloat destinationX = [self leftPaddleContactX];
    if(arc4random() % 2 == 1) {
        destinationX = [self rightPaddleContactX];
    }
    CGFloat destinationY = (float)(arc4random() % (int)self.gameView.frame.size.height);
    
    self.ballDestination = CGPointMake(destinationX, destinationY);
    self.ballDirection = CGPointMake((self.ballDestination.x - self.ballOrigin.x), (self.ballDestination.y - self.ballOrigin.y));
    self.ballDirection = [self normalizeVector:self.ballDirection];
}

#pragma mark Playing the game

#pragma mark Ball behavior

- (void)determineNextBallDestination
{
    CGFloat newBallDestinationX;
    CGFloat newBallDestinationY;
    
    self.ballDirection = [self determineReflectedDirectionOfBall];
    
    CGFloat verticalDistanceToNextWall = [self calculateVerticalDistanceFromBallToNextWall];
    CGFloat distanceToNextWall = verticalDistanceToNextWall / self.ballDirection.y;
    CGFloat horizontalDistanceToNextWall = distanceToNextWall * self.ballDirection.x;
    
    CGFloat horizontalDistanceToNextPaddle = [self calculateHorizontalDistanceFromBallToNextPaddle];
    
    if(fabs(horizontalDistanceToNextPaddle) < fabs(horizontalDistanceToNextWall)) {
        newBallDestinationX = self.ballDestination.x + horizontalDistanceToNextPaddle;
        
        CGFloat verticalDistanceToNextPaddle = fabs(horizontalDistanceToNextPaddle) * self.ballDirection.y;
        newBallDestinationY = self.ballDestination.y + verticalDistanceToNextPaddle;
    } else {
        newBallDestinationX = self.ballDestination.x + horizontalDistanceToNextWall;
        newBallDestinationY = self.ballDestination.y + verticalDistanceToNextWall;
    }
    
    self.ballOrigin = self.ballDestination;
    self.ballDestination = CGPointMake(newBallDestinationX, newBallDestinationY);
}

- (CGPoint)determineReflectedDirectionOfBall
{
    CGPoint reflectedBallDirection = self.ballDirection;
    
    if([self didBallHitWall]) {
        reflectedBallDirection =  CGPointMake(self.ballDirection.x, -self.ballDirection.y);
    } else if([self didBallHitPaddle]) {
        reflectedBallDirection =  CGPointMake(-self.ballDirection.x, self.ballDirection.y);
    }
    
    return reflectedBallDirection;
}

- (BOOL)didBallHitWall
{
    return ([self isFloat:self.ballDestination.y equalToFloat:[self ceilingContactY]] || [self isFloat:self.ballDestination.y equalToFloat:[self floorContactY]]);
}

- (BOOL)didBallHitPaddle
{
    return ([self isFloat:self.ballDestination.x equalToFloat:[self leftPaddleContactX]] || [self isFloat:self.ballDestination.x equalToFloat:[self rightPaddleContactX]]);
}

- (CGFloat)calculateVerticalDistanceFromBallToNextWall
{
    if(self.ballDirection.y > 0.0f) {
        return [self floorContactY] - self.ballDestination.y;
    } else {
        return [self ceilingContactY] - self.ballDestination.y;
    }
}

- (CGFloat)calculateHorizontalDistanceFromBallToNextPaddle
{
    if(self.ballDirection.x < 0.0f) {
        return [self leftPaddleContactX] - self.ballDestination.x;
    } else {
        return [self rightPaddleContactX] - self.ballDestination.x;
    }
}

#pragma mark Paddle behavior

- (void)determineNextPaddleDestinations
{
    static CGFloat lazySpeedFactor = 0.25f;
    static CGFloat normalSpeedFactor = 0.5f;
    static CGFloat holyCrapSpeedFactor = 1.0f;
    
    CGFloat leftPaddleVerticalDistanceToBallDestination = self.ballDestination.y - self.leftPaddleView.center.y;
    CGFloat rightPaddleVerticalDistanceToBallDestination = self.ballDestination.y - self.rightPaddleView.center.y;
    
    CGFloat leftPaddleOffset;
    CGFloat rightPaddleOffset;
    
    //Determining how far each paddle will mode
    if(self.ballDirection.x < 0.0f) {
        //Ball is going toward the left paddle
        
        if([self isBallDestinationIsTheLeftPaddle]) {
            leftPaddleOffset = (leftPaddleVerticalDistanceToBallDestination * holyCrapSpeedFactor);
            rightPaddleOffset = (rightPaddleVerticalDistanceToBallDestination * lazySpeedFactor);
        } else {
            //Destination is a wall
            leftPaddleOffset = (leftPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
            rightPaddleOffset = -(rightPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
        }
    } else {
        //Ball is going toward the right paddle
        
        if([self isBallDestinationIsTheRightPaddle]) {
            leftPaddleOffset = (leftPaddleVerticalDistanceToBallDestination * lazySpeedFactor);
            rightPaddleOffset = (rightPaddleVerticalDistanceToBallDestination * holyCrapSpeedFactor);
        } else {
            //Destination is a wall
            leftPaddleOffset = -(leftPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
            rightPaddleOffset = (rightPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
        }
    }
    
    self.leftPaddleDestination = self.leftPaddleView.center.y + leftPaddleOffset;
    self.rightPaddleDestination = self.rightPaddleView.center.y + rightPaddleOffset;
    
    [self capPaddleDestinationsToWalls];
}

- (BOOL)isBallDestinationIsTheLeftPaddle
{
    return ([self isFloat:self.ballDestination.x equalToFloat:[self leftPaddleContactX]]);
}

- (BOOL)isBallDestinationIsTheRightPaddle
{
    return ([self isFloat:self.ballDestination.x equalToFloat:[self rightPaddleContactX]]);
}

- (void)capPaddleDestinationsToWalls
{
    if(self.leftPaddleDestination < [self ceilingLeftPaddleContactY]) {
        self.leftPaddleDestination = [self ceilingLeftPaddleContactY];
    } else if(self.leftPaddleDestination > [self floorLeftPaddleContactY]) {
        self.leftPaddleDestination = [self floorLeftPaddleContactY];
    }
    
    if(self.rightPaddleDestination < [self ceilingRightPaddleContactY]) {
        self.rightPaddleDestination = [self ceilingRightPaddleContactY];
    } else if(self.rightPaddleDestination > [self floorRightPaddleContactY]) {
        self.rightPaddleDestination = [self floorRightPaddleContactY];
    }
}

#pragma mark Actually animating the balls and paddles to where they need to go

- (void)animateBallAndPaddlesToDestinations
{
    CGFloat endToEndDistance = [self rightPaddleContactX] - [self leftPaddleContactX];
    CGFloat proportionOfHorizontalDistanceLeftForBallToTravel = fabsf((self.ballDestination.x - self.ballView.center.x) / endToEndDistance);
    CGFloat animationDuration = self.totalHorizontalTravelTimeForBall * proportionOfHorizontalDistanceLeftForBallToTravel;
    
    [UIView animateWithDuration:animationDuration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^(void)
     {
         self.ballView.center = self.ballDestination;
         self.leftPaddleView.center = CGPointMake(self.leftPaddleView.center.x, self.leftPaddleDestination);
         self.rightPaddleView.center = CGPointMake(self.rightPaddleView.center.x, self.rightPaddleDestination);
     }
                     completion:^(BOOL finished)
     {
         if(finished) {
             [self determineNextBallDestination];
             [self determineNextPaddleDestinations];
             [self animateBallAndPaddlesToDestinations];
         }
     }];
}

#pragma mark Helper functions for collision detection

#pragma mark Ball collisions

- (CGFloat)leftPaddleContactX
{
    return self.leftPaddleView.center.x + (self.ballView.frame.size.width / 2.0f);
}

- (CGFloat)rightPaddleContactX
{
    return self.rightPaddleView.center.x - (self.ballView.frame.size.width / 2.0f);
}

- (CGFloat)ceilingContactY
{
    return (self.ballView.frame.size.height / 2.0f);
}

- (CGFloat)floorContactY
{
    return self.gameView.frame.size.height - (self.ballView.frame.size.height / 2.0f);
}

#pragma mark Paddle collisions

- (CGFloat)ceilingLeftPaddleContactY
{
    return (self.leftPaddleView.frame.size.height / 2.0f);
}

- (CGFloat)floorLeftPaddleContactY
{
    return self.gameView.frame.size.height - (self.leftPaddleView.frame.size.height / 2.0f);
}

- (CGFloat)ceilingRightPaddleContactY
{
    return (self.rightPaddleView.frame.size.height / 2.0f);
}

- (CGFloat)floorRightPaddleContactY
{
    return self.gameView.frame.size.height - (self.rightPaddleView.frame.size.height / 2.0f);
}

#pragma mark - Etc, some basic math functions

- (CGPoint)normalizeVector:(CGPoint)vector
{
    CGFloat magnitude = sqrtf(vector.x * vector.x + vector.y * vector.y);
    return CGPointMake(vector.x / magnitude, vector.y / magnitude);
}

- (BOOL)isFloat:(CGFloat)float1 equalToFloat:(CGFloat)float2
{
    static CGFloat ellipsis = 0.01f;
    
    return (fabsf(float1 - float2) < ellipsis);
}


@end
