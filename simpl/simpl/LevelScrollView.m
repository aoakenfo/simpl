//
//  LevelScrollView.m
//  simpl
//
//  Created by Oakenfold, Ash on 13-03-11.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import "LevelScrollView.h"
#import "LevelView.h"
#import "Level.h"

@interface LevelScrollView()
{
    
}

@end

@implementation LevelScrollView

- (id)init
{
    self = [super init];
    
    if (self)
    {
        CGSize frame = [UIScreen mainScreen].applicationFrame.size;
        
        self.layer.bounds = CGRectMake(0.0, 0.0, 0.0, 0.0);
        self.layer.position = CGPointMake(frame.width / 2.0, frame.height / 2.0);
        self.layer.backgroundColor = [UIColor blackColor].CGColor;
        
        // TODO: move to loadLevels function
        // i don't like doing this kind of work in init method
    }
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    id value = [anim valueForKey:@"animName"];
    if(value != nil)
    {
        if([value isEqualToString:@"scaleAnim1"])
        {
            [self scaleAnim2];
        }
        else if([value isEqualToString:@"scaleAnim2"])
        {
            // TODO: add/layout level launch buttons here or init?
            // TODO: move to loadLevels function
            
            int totalWidth = self.frame.size.width * [Level totalNumberOfLevels];
            
            self.contentSize = CGSizeMake(totalWidth, self.frame.size.height);
            self.showsHorizontalScrollIndicator = NO;
            self.showsVerticalScrollIndicator = NO;
            
            self.pagingEnabled = YES;
            
            float percentage = 1;//0.5;
            for(int i=0; i< [Level totalNumberOfLevels]; ++i)
            {
                LevelView* lv = [[LevelView alloc]init];
                
                lv.levelNumber = [NSNumber numberWithInt:i];
                
                // scroll width is 176
                // does 14 divide into 176 evenly?
                // if remainder, find nearest multiple down
                // 14*12=168
                // 176-168 = 8 px left over, so offset by 4px
                // make sure scoll width is going to always be an even number and not something like 177
                    // TODO: increase width of scroll area a bit?
                
                int numCols = -1;
                int numRows = -1;
                
                // TODO: when scroll view is refactored, you can probably delete this static method
                [Level numCols:&numCols andRows:&numRows forLevel:i];
                
                int w = ((int)((self.frame.size.width*percentage) / numCols)) * numCols; // 168
                int h = (int)((self.frame.size.width*percentage) * (numRows/(float)numCols) / numRows) * numRows; // 120
                
                [lv setFrame:CGRectMake(
                                        (self.frame.size.width*(i+1)-(self.frame.size.width/2) - (w/2)),
                                        (self.frame.size.height/2)-(h/2),
                                             w,
                                             h)];
                
                [self addSubview:lv];
            }
            
            [self setContentOffset:CGPointMake(-self.frame.size.width, 0) animated:NO];
            [self setContentOffset:CGPointMake(0, 0) animated:YES];
        }
    }
}

- (void)animateIn
{
    [self scaleAnim1];
}

- (void)scaleAnim1
{
    CGRect toBounds = CGRectMake(0,
                                 0,
                                 [UIScreen mainScreen].applicationFrame.size.width,//rectWidth,
                                 2);
    
    CABasicAnimation* scaleAnim1 = [CABasicAnimation animationWithKeyPath:@"bounds"];
    scaleAnim1.fromValue = [NSValue valueWithCGRect:self.layer.bounds];
    scaleAnim1.toValue = [NSValue valueWithCGRect:toBounds];
    scaleAnim1.duration = 0.125;
    
    scaleAnim1.delegate = self;
    [scaleAnim1 setValue:@"scaleAnim1" forKey:@"animName"];
    [self.layer addAnimation:scaleAnim1 forKey:nil];
    
    // Change the actual data value in the layer to the final value.
    self.layer.bounds = toBounds;
}

- (void)scaleAnim2
{
    CGFloat appWidth = [UIScreen mainScreen].applicationFrame.size.width;
    CGFloat appHeight = [UIScreen mainScreen].applicationFrame.size.height;
    float percentage = 0.0;
    
    int w = appWidth - (appWidth * percentage);
    assert((w % 2) == 0);
    
    CGRect toBounds = CGRectMake(0.0,
                                 (appWidth / 2.0) - (appWidth * (1.0 - percentage)),
                                 w,
                                 appHeight);
    
    CABasicAnimation* scaleAnim2 = [CABasicAnimation animationWithKeyPath:@"bounds"];
    scaleAnim2.fromValue = [NSValue valueWithCGRect:self.layer.bounds];
    scaleAnim2.toValue = [NSValue valueWithCGRect:toBounds];
    scaleAnim2.duration = 0.25;
    
    CFTimeInterval localLayerTime = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.layer.beginTime = localLayerTime + 0.125;
    self.layer.fillMode = kCAFillModeBackwards;
    
    scaleAnim2.delegate = self;
    [scaleAnim2 setValue:@"scaleAnim2" forKey:@"animName"];
    [self.layer addAnimation:scaleAnim2 forKey:nil];
    
    self.layer.bounds = toBounds;
}

@end
