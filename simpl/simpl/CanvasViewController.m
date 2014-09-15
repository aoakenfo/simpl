//
//  CanvasViewController.m
//  simpl
//
//  Created by Clev R. Munke on 13-03-10.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import "CanvasViewController.h"
#import "LevelView.h"
#import "CloseButton.h"
#import "TileLayer.h"

@interface CanvasViewController ()
{
    LevelView* _currentLevel;
    
    UIScrollView* _scrollView;
    NSMutableArray* _visibleLevelViews;
    CloseButton* _closeButton;
    BOOL _unlockNextLevel;
    
    UISwipeGestureRecognizer* _swipeLeft;
    UISwipeGestureRecognizer* _swipeRight;
    UISwipeGestureRecognizer* _swipeUp;
    UISwipeGestureRecognizer* _swipeDown;
}

@end

@implementation CanvasViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self initScrollAndLevelViews];
        [self initCloseButton];
        [self registerNotifications];
        [self initSwipeGestures];
    }
    
    return self;
}

- (void)initCloseButton {
    _closeButton = [[CloseButton alloc]initWithFrame:CGRectMake(0, 0, 44, 44)];
    [self.view addSubview:_closeButton];
    [_closeButton setHidden:YES];
}

- (void)initSwipeGestures {
    _swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGesture:)];
    _swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    _swipeLeft.enabled = NO;
    [self.view addGestureRecognizer:_swipeLeft];
    
    _swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGesture:)];
    _swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    _swipeRight.enabled = NO;
    [self.view addGestureRecognizer:_swipeRight];
    
    _swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGesture:)];
    _swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    _swipeUp.enabled = NO;
    [self.view addGestureRecognizer:_swipeUp];
    
    _swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGesture:)];
    _swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    _swipeDown.enabled = NO;
    [self.view addGestureRecognizer:_swipeDown];
}

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadLevelComplete:) name:kLoadLevelComplete object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(unloadLevelComplete:) name:kUnloadLevelComplete object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(levelSelected:) name:kLevelSelected object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enableInput:) name:kEnableInput object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(disableInput:) name:kDisableInput object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(closeLevel:) name:kCloseButtonTapped object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(unlockNextLevel:) name:kUnlockNextLevel object:nil];
}

- (void)dealloc {
    
    [self.view removeGestureRecognizer:_swipeLeft];
    [self.view removeGestureRecognizer:_swipeRight];
    [self.view removeGestureRecognizer:_swipeDown];
    [self.view removeGestureRecognizer:_swipeDown];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)initScrollAndLevelViews {
    _scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0,
                                                                0,
                                                                [UIScreen mainScreen].applicationFrame.size.width,
                                                                [UIScreen mainScreen].applicationFrame.size.height)];
    [self.view addSubview:_scrollView];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    int numLevels = [Level totalNumberOfLevels];
    float yOffset = 0;
    float y = 0;
    float padding = 20;
    
    for(int i = numLevels-1; i >= 0; --i) {
        
        float w = 5 * [Level numColsForLevelNumber:i];
        float h = 5 * [Level numRowsForLevelNumber:i];
        
        CGRect f = CGRectMake((int)(_scrollView.frame.size.width/2-(w/2)), yOffset, w, h);
        LevelView* levelView = [[LevelView alloc]initWithFrame:f];
        
        levelView.levelNumber = [NSNumber numberWithInt:i];
        
        NSString* key = [NSString stringWithFormat:@"simpl%i", i];
        NSNumber* lockedFlag = [defaults objectForKey:key];
        
        if(lockedFlag == nil) {
            levelView.isLocked =  YES;
        }
        else {
            levelView.isLocked = [lockedFlag boolValue];
        }
        if(i == 0) {
            levelView.isLocked = NO;
            [defaults setObject:@1 forKey:@"simpl0"];
            [defaults synchronize];
        }
        [_scrollView addSubview:levelView];
        
        // TEMP:
        //levelView.isLocked = NO;
        
        ++y;
        yOffset += levelView.frame.size.height + padding;
    }
    
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, yOffset);
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = YES;
    
    // TODO: scroll to last unlocked
    [_scrollView setContentOffset:CGPointMake(0, _scrollView.contentSize.height-_scrollView.frame.size.height) animated:NO];
}

- (void)enableInput:(NSNotification*)note
{
    _swipeLeft.enabled = YES;
    _swipeRight.enabled = YES;
    _swipeUp.enabled = YES;
    _swipeDown.enabled = YES;
}

- (void)disableInput:(NSNotification*)note
{
    _swipeLeft.enabled = NO;
    _swipeRight.enabled = NO;
    _swipeUp.enabled = NO;
    _swipeDown.enabled = NO;
}

- (void)unlockNextLevel:(NSNotification*)note
{
    // flag an unlock and wait for transition animation to complete
    _unlockNextLevel = YES;
    [self closeLevel:nil];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)orientationChanged:(NSNotification*)note {
    static int lastOrientation = UIDeviceOrientationPortrait;
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    void (^setFramesBlock)(void) = NULL;
    
    switch (orientation) {
            
        case UIDeviceOrientationPortrait: {
            if(lastOrientation == UIDeviceOrientationPortrait) { // going from flat to portrait again
                return;
            }
            
            setFramesBlock = ^{
                [_closeButton setFrame:CGRectMake(0, 0, 44, 44)];
            };
            
            lastOrientation = UIDeviceOrientationPortrait;
        } break;
            
        case UIDeviceOrientationPortraitUpsideDown: {
            if(lastOrientation == UIDeviceOrientationPortraitUpsideDown) {
                return;
            }
            
            setFramesBlock = ^{
                [_closeButton setFrame:CGRectMake(self.view.frame.size.width-44, self.view.frame.size.height - 44, 44, 44)];
            };
            
            lastOrientation = UIDeviceOrientationPortraitUpsideDown;
        } break;
            
        case UIDeviceOrientationLandscapeLeft: {
            if(lastOrientation == UIDeviceOrientationLandscapeLeft) {
                return;
            }
            
            setFramesBlock = ^{
                [_closeButton setFrame:CGRectMake(self.view.frame.size.width-44, 0, 44, 44)];
            };
            
            lastOrientation = UIDeviceOrientationLandscapeLeft;
        } break;
            
        case UIDeviceOrientationLandscapeRight: {
            if(lastOrientation == UIDeviceOrientationLandscapeRight) {
                return;
            }
            
            setFramesBlock = ^{
                [_closeButton setFrame:CGRectMake(0, self.view.frame.size.height-44, 44, 44)];
            };
            
            lastOrientation = UIDeviceOrientationLandscapeRight;
        } break;
            
        default: break;
    }
    
    if(setFramesBlock) {
        [UIView animateWithDuration:[TileLayer flipDuration]
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^(void) {
                             _closeButton.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             setFramesBlock();
                             
                             [UIView animateWithDuration:[TileLayer flipDuration]
                                                   delay:0
                                                 options:UIViewAnimationOptionCurveLinear
                                              animations:^(void) {
                                                  _closeButton.alpha = 1.0;
                                              }
                                              completion:nil];
                         }];
    }
}

- (void)closeLevel:(NSNotification*)note
{
    [self disableInput:nil];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
        
    [_closeButton setHidden:YES];
    [_currentLevel unloadLevel];
}

- (void)levelSelected:(NSNotification*)note
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kLevelSelected object:nil];
    
    // first, disable scroll input
    _scrollView.userInteractionEnabled = NO;
    
    // get the selected LevelView
    _currentLevel = [note object];
    
    // fire up orientation notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [self orientationChanged:nil]; // manually refresh to current orientation
    
    // grab all LevelViews visible on screen and store frame information for transition animation
    _visibleLevelViews = [[NSMutableArray alloc]init];
    for(UIView* view in _scrollView.subviews) {
        if([view isKindOfClass:[LevelView class]]) {
            
            CGRect f = self.view.frame;
            f.origin.y = _scrollView.contentOffset.y;
            CGRect r = [self.view convertRect:view.frame toView:self.view];
            
            if(CGRectIntersectsRect(f, r)) {
            
                LevelView* levelView = (LevelView*)view;
                
                // obviously the current level is visible, but we don't add it to the list
                // visible level views array is used to push other level views offscreen
                if(levelView != _currentLevel) {
                    
                    // determine if this level view is above or below the selected level
                    // this will determine the direction it's animated offscreen
                    levelView.isPositionedAboveCurrentLevelView = levelView.frame.origin.y < _currentLevel.frame.origin.y;
                    
                    // store the original frame inside scroll view so we can return it to the appropriate
                    // content offset
                    levelView.originalFrameWithinScrollView = levelView.frame;
                    
                    // now eliminate the content offset by transforming it to canvas coordinate space
                    CGRect frameInCanvas = levelView.frame;
                    frameInCanvas.origin.y = levelView.frame.origin.y - _scrollView.contentOffset.y + _scrollView.frame.origin.y;;
                    levelView.frame = frameInCanvas;
                    
                    // with our frame inside canvas calculated, transfer ownership
                    [self.view insertSubview:levelView aboveSubview:_scrollView];
                    
                    // and store this position so we can return to it on transition back
                    levelView.centerInCanvasViewBeforeAnim = levelView.center;
                    
                    [_visibleLevelViews addObject:levelView];
                }
            }
        }
    }
    
    // similar to above, we store frame information for the selected level view
    _currentLevel.originalFrameWithinScrollView = _currentLevel.frame;
    
    // transform coordinates from scroll view content offset to canvas
    CGRect frameInCanvas = _currentLevel.frame;
    frameInCanvas.origin.y = _currentLevel.frame.origin.y - _scrollView.contentOffset.y + _scrollView.frame.origin.y;
    _currentLevel.frame = frameInCanvas;
    
    // transfer ownership from scroll view to canvas
    [self.view insertSubview:_currentLevel aboveSubview:_scrollView];
    
    // remember this frame before we zoom in
    _currentLevel.centerInCanvasViewBeforeAnim = _currentLevel.center;
    _currentLevel.originalFrameWithinCanvasView = _currentLevel.frame;
    
    // push other level views offscreen
    [UIView animateWithDuration:[TileLayer flipDuration]
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         for(LevelView* levelView in _visibleLevelViews) {
                             levelView.center = CGPointMake(levelView.center.x, levelView.center.y
                                                            + (_scrollView.frame.size.height * (levelView.isPositionedAboveCurrentLevelView ? -1 : 1)));
                         }
                     }
                     completion:nil];
    
    // at the same time, zoom in to selected level
    [UIView animateWithDuration:[TileLayer flipDuration]
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         int numCols = [Level numColsForLevelNumber:[_currentLevel.levelNumber integerValue]];
                         int numRows = [Level numRowsForLevelNumber:[_currentLevel.levelNumber integerValue]];
                         
                         /*
                          // scroll width is 176
                          // do 14 tiles divide into 176 evenly?
                          // no, 12.57 so find the nearest multiple down
                          // 14*12=168
                          // 176-168 = 8 px left over, so offset by 4px
                          // make sure scoll width is always going to be an even number and not something like 177
                          */
                         int w = ((int)(_scrollView.frame.size.width / numCols)) * numCols; // 168
                         int h = (int)(_scrollView.frame.size.width * (numRows/(float)numCols) / numRows) * numRows;
    
                         CGRect svf = _scrollView.frame;
                         _currentLevel.frame = CGRectMake((svf.size.width-(svf.size.width/2) - (w/2)),
                                                          (svf.size.height/2)-(h/2),
                                                          w,
                                                          h);
                     }
                     completion:^(BOOL finished) {
                         if(finished) {
                             [_currentLevel loadLevel];
                         }
                     }];
}

// called after LevelView has compltedted its load level animation (fade in tile colors)
- (void)loadLevelComplete:(NSNotification*)note {
    
    [_closeButton setHidden:NO];
}

// called after LevelView has completed its unload level animation (fade out tile colors)
- (void)unloadLevelComplete:(NSNotification*)note {
    
    [UIView animateWithDuration:[TileLayer flipDuration]
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         // animate surrounding levels back into view, positioning them at their original origin
                         for(LevelView* levelView in _visibleLevelViews) {
                             
                             levelView.center = levelView.centerInCanvasViewBeforeAnim;
                             
                         }
                         
                         // zoom current level back to original size within canvas frame
                         _currentLevel.frame = _currentLevel.originalFrameWithinCanvasView;
                        
                     }
                     completion:^(BOOL finished) {
                         
                         if(finished) {
                             
                             // now that surrounding level views are back in their original position
                             // transfer ownership from canvas back to scroll view, making sure
                             // to set their original frame within the scroll views content offset
                             for(LevelView* levelView in _visibleLevelViews) {
                                 
                                 [_scrollView addSubview:levelView];
                                 levelView.frame = levelView.originalFrameWithinScrollView;
                             }
                             
                             // position current level to original scroll view frame
                             [_scrollView addSubview:_currentLevel];
                             _currentLevel.frame = _currentLevel.originalFrameWithinScrollView;
                             
                             // clean up
                             _visibleLevelViews = nil;
                             
                             // now that scroll view has been restored, enable scrolling again
                             _scrollView.userInteractionEnabled = YES;
                             
                             [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(levelSelected:) name:kLevelSelected object:nil];
                             
                             if(_unlockNextLevel) {
                                 _unlockNextLevel = NO;
                                 NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                                 int nextLevel = [_currentLevel.levelNumber intValue] + 1;
                                 if(nextLevel < [Level totalNumberOfLevels]) {
                                     for(UIView* view in _scrollView.subviews) {
                                         if([view isKindOfClass:[LevelView class]]) {
                                             LevelView* levelView = (LevelView*)view;
                                             if([levelView.levelNumber integerValue] == nextLevel) {
                                                 [defaults setObject:@0 forKey:[NSString stringWithFormat:@"simpl%i", nextLevel]];
                                                 [defaults synchronize];
                                                 levelView.isLocked = NO;
                                                 [self performSelector:@selector(setNeedsDisplayForLevelView:) withObject:levelView afterDelay:0.25];
                                             }
                                         }
                                     }
                                 }
                             }
                         }
                     }
     ];
}

- (void)setNeedsDisplayForLevelView:(LevelView*)levelView {
    
    [levelView setNeedsDisplay];
}

- (void)swipeGesture:(UISwipeGestureRecognizer *)recognizer {
    [_currentLevel swipe:recognizer.direction];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

@end
