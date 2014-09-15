//
//  TileLayer.m
//  simpl
//
//  Created by Edward Oakenfold on 2013-04-21.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import "TileLayer.h"

NSString* const kFadeInAnimKey = @"fi";
NSString* const kFadeToColorAnimKey = @"ftc";
NSString* const kFlip1AnimKey = @"f1";
NSString* const kFlip2AnimKey = @"f2";

static float _duration = 0.25f;

@interface TileLayer()
{
    TileType _targetTileType;
    void (^_flipCallback)(void);
    void (^_fadeInCallback)(void);
    void (^_fadeToColorCallback)(void);
    int _index;
    UIColor* _targetFadeToColor;
}

@end

@implementation TileLayer

+ (float)flipDuration {
    return _duration;
}

+ (void)setFlipDuration:(float)value {
    _duration = value;
}

- (id)initWithTileType:(TileType)tileType atIndex:(int)index {
    self = [super init];
    
    if(self) {
        
        _index = index;
        
        _originalTileType = tileType;
        _targetTileType = kNullTile;
        
        self.opaque = YES;
        self.doubleSided = YES;
        self.backgroundColor = [TileLayer colorForTileType:tileType].CGColor;
        
        if(_originalTileType >= kBlockTile1) {
            
            if(_originalTileType % 2 != 0) {
                self.backgroundColor = [TileLayer colorForTileType:kOpenTile].CGColor;
                self.borderColor = [TileLayer colorForTileType:tileType].CGColor;
            }
        }
    }
    
    return self;
}

- (BOOL)isOnTargetTile {
    
    return _targetTileType == -1;
}

#define RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
+ (UIColor*)colorForTileType:(TileType)tileType {
    
    switch (tileType) {
        case kLockedTile:       return RGB(102, 102, 102); // dark gray
        case kUnlockedTile:     return RGB(255, 255, 255);
        case kEmptyTile:        return RGB(0, 0, 0);
        case kPlayerTile:       return RGB(65, 180, 255); // blue
        case kWinTile:          return RGB(175, 255, 0); // green
        case kOutOfBoundsTile:  return RGB(255, 89, 61); // red
        case kBreakableTile:    return RGB(132, 132, 132); // light gray
        case kOpenTile:
        case kWinTileLocked:
            return RGB(255, 255, 255);
        case kBlockTile1:
        case kBlockTriggerTile1:
            return RGB(255, 164, 73); // orange
        case kBlockTile2:
        case kBlockTriggerTile2:
            return RGB(255, 220, 69); // yellow
        default: break;
    }
    
    return [UIColor yellowColor];
}

- (void)flipToTileType:(TileType)tileType
          forDirection:(UISwipeGestureRecognizerDirection)direction
            startDelay:(float)delay
            completion:(void (^)(void))callback {
    
    _flipCallback = callback;
    _targetTileType = tileType;
    
    CABasicAnimation *flipAnim1 = nil;
    CABasicAnimation *flipAnim2 = nil;
    CGFloat startValue = 0;
	CGFloat endValue = M_PI/2;
    
    switch(direction) {
        case UISwipeGestureRecognizerDirectionLeft:
        case UISwipeGestureRecognizerDirectionRight:
            flipAnim1 = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
            flipAnim2 = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
            break;
            
        case UISwipeGestureRecognizerDirectionUp:
        case UISwipeGestureRecognizerDirectionDown:
            flipAnim1 = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
            flipAnim2 = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
            break;
    }
    
	flipAnim1.fromValue = [NSNumber numberWithDouble:startValue];
	flipAnim1.toValue = [NSNumber numberWithDouble:endValue];
    flipAnim1.duration = _duration/2;
    flipAnim1.removedOnCompletion = NO;
    flipAnim1.fillMode = kCAFillModeForwards;
    CFTimeInterval localLayerTime = [self convertTime:CACurrentMediaTime() fromLayer:nil] + delay;
    flipAnim1.beginTime = localLayerTime;
    flipAnim1.delegate = self;
    flipAnim1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    flipAnim2.fromValue = [NSNumber numberWithDouble:endValue];
    flipAnim2.toValue = [NSNumber numberWithDouble:startValue];
    flipAnim2.duration = _duration/2;
    flipAnim2.removedOnCompletion = NO;
    flipAnim2.fillMode = kCAFillModeForwards;
    flipAnim2.beginTime = localLayerTime + (_duration/2);
    flipAnim2.delegate = self;
    flipAnim2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    [self addAnimation:flipAnim1 forKey:kFlip1AnimKey];
    [self addAnimation:flipAnim2 forKey:kFlip2AnimKey];
}

- (void)fadeToColor:(UIColor*)color completion:(void (^)(void))callback; {
    
    _fadeToColorCallback = callback;
    _targetFadeToColor = color;

    CABasicAnimation* colorAnim = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    
    colorAnim.fromValue = (id)self.backgroundColor;
    colorAnim.toValue = (id)color.CGColor;
    colorAnim.duration = 0.25f;
    colorAnim.delegate = self;
    colorAnim.removedOnCompletion = NO;
    colorAnim.fillMode = kCAFillModeForwards;
    
    [self addAnimation:colorAnim forKey:kFadeToColorAnimKey];
}

- (void)fadeIn:(void (^)(void))callback; {
    
    _fadeInCallback = callback;
    
    CABasicAnimation* fadeInAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    fadeInAnim.duration = 0.25f;
    fadeInAnim.fromValue = @0;
    fadeInAnim.toValue = @1;
    fadeInAnim.delegate = self;
    fadeInAnim.removedOnCompletion = NO;
    fadeInAnim.fillMode = kCAFillModeForwards;
    
    [self addAnimation:fadeInAnim forKey:kFadeInAnimKey];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    
    if(theAnimation == [self animationForKey:kFlip1AnimKey]) {
        
        [self removeAnimationForKey:kFlip1AnimKey];
        
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        
        self.backgroundColor = [TileLayer colorForTileType:_targetTileType].CGColor;
        
        if(self.borderWidth > 0)
            self.borderColor = [TileLayer colorForTileType:_targetTileType].CGColor;
        
        if(_targetTileType >= kBlockTile1) {
            
            if(_targetTileType % 2 != 0) {
                self.backgroundColor = [TileLayer colorForTileType:kOpenTile].CGColor;
            }
        }
        
        [CATransaction commit];
    }
    else if(theAnimation == [self animationForKey:kFlip2AnimKey]) {
        if(flag) {
            
            [self removeAnimationForKey:kFlip2AnimKey];
            
            if(_targetTileType == _originalTileType)
                _targetTileType = -1;
        
            if(_flipCallback != nil)
                _flipCallback();
        }
    }
    else if(theAnimation == [self animationForKey:kFadeInAnimKey]) {
        if(flag) {
            
            self.opacity = 1.0;
            [self removeAnimationForKey:kFadeInAnimKey];
            
            if(_fadeInCallback) {
                _fadeInCallback();
            }
        }
    }
    else if(theAnimation == [self animationForKey:kFadeToColorAnimKey]) {
        if(flag) {
            
            self.backgroundColor = _targetFadeToColor.CGColor;
            [self removeAnimationForKey:kFadeToColorAnimKey];
            
            if(_fadeToColorCallback) {
                _fadeToColorCallback();
            }
        }
    }
}

@end
