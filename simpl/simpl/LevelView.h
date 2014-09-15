//
//  LevelView.h
//  simpl
//
//  Created by Oakenfold, Ash on 13-03-15.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

NSString* const kDisableInput;
NSString* const kEnableInput;
NSString* const kLevelSelected;
NSString* const kLoadLevelComplete;
NSString* const kUnloadLevelComplete;
NSString* const kUnlockNextLevel;

// Level manages all game logic. LevelView just renders it and responds to events from Level to update rendering
@interface LevelView : UIView

@property (strong, nonatomic) NSNumber* levelNumber;
@property (assign, nonatomic) BOOL isLocked;

- (void)loadLevel;
- (void)unloadLevel;
- (void)swipe:(UISwipeGestureRecognizerDirection)direction;

// these are used by canvas view controller to track level view transitions
// perhaps not an ideal fit in the context of class design, but they offer convenience, working code, and easier to read animation code in canvas view controller (versus tracking these fields in separate frame info objects array associated with level views)
@property (assign, nonatomic) CGRect originalFrameWithinScrollView;
@property (assign, nonatomic) CGRect originalFrameWithinCanvasView;
@property (assign, nonatomic) CGPoint centerInCanvasViewBeforeAnim;
@property (assign, nonatomic) BOOL isPositionedAboveCurrentLevelView;

@end
