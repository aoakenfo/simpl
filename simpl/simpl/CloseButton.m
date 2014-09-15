//
//  CloseButton.m
//  simpl
//
//  Created by Edward Oakenfold on 2013-03-26.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import "CloseButton.h"

NSString* const kCloseButtonTapped = @"kCloseButtonTapped";

@interface CloseButton()
{
    UITapGestureRecognizer* singleTap;
}

@end

@implementation CloseButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        singleTap.numberOfTapsRequired = 1;
        singleTap.numberOfTouchesRequired = 1;
        
        self.backgroundColor = [UIColor clearColor];
        
        [self addGestureRecognizer:singleTap];
    }
    return self;
}

- (void)dealloc
{
    [self removeGestureRecognizer:singleTap];
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
    singleTap.enabled = !hidden;
}

- (void)tapped:(UIGestureRecognizer *)gestureRecognizer
{
    [[NSNotificationCenter defaultCenter]postNotificationName:kCloseButtonTapped object:nil];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    CGContextSetRGBStrokeColor(context, 0.75, 0.75, 0.75, 1.0);
    
    float percentage = .33;
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetLineWidth(context, 1.0);
    float w = rect.size.width*percentage;
    float h = rect.size.height*percentage;
    
    CGContextMoveToPoint(context, w, h);
    CGContextAddLineToPoint(context, rect.size.width-w, rect.size.height-h);
    
    CGContextMoveToPoint(context, w, rect.size.height-h);
    CGContextAddLineToPoint(context, rect.size.width-w, h);
    
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

@end
