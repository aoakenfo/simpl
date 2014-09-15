//
//  LevelView.m
//  simpl
//
//  Created by Oakenfold, Ash on 13-03-15.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import "LevelView.h"
#import "Level.h"
#import "LevelEvent.h"
#import "LevelInfo.h"
#import "PlayerMovedEvent.h"
#import "BlockMovedEvent.h"
#import "WinTileUnlockedEvent.h"
#import "TileLayer.h"

NSString* const kDisableInput = @"kDisableInput";
NSString* const kEnableInput = @"kEnableInput";
NSString* const kLevelSelected = @"kLevelSelected";
NSString* const kLoadLevelComplete = @"kLoadLevelComplete";
NSString* const kUnloadLevelComplete = @"kUnloadLevelComplete";
NSString* const kUnlockNextLevel = @"kUnlockNextLevel";

@interface LevelView() {
    
    Level* _level;
    UISwipeGestureRecognizerDirection _gestureDirection;
    LevelInfo* _levelInfo;
    BOOL _shortCircuitDrawRect;
}

@end

@implementation LevelView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        _shortCircuitDrawRect = NO;
        self.layer.magnificationFilter = kCAFilterNearest;
    }
    
    return self;
}

- (void)setLevelNumber:(NSNumber*)number {
    _levelNumber = number;
    
    self.backgroundColor = [UIColor blackColor];
}

- (void)unloadLevel {
    for(TileLayer* tileLayer in self.layer.sublayers) {
        [tileLayer removeAllAnimations];
    }
    
    BOOL callbackSet = NO;
    for(TileLayer* tileLayer in self.layer.sublayers) {
        if(tileLayer.originalTileType != kEmptyTile) {
            if(!callbackSet) {
                callbackSet = YES;
                [tileLayer fadeToColor:[UIColor whiteColor] completion:^ {
                    _shortCircuitDrawRect = NO;
                    [self setNeedsDisplay];
                    self.layer.sublayers = nil;
                    _level = nil;
                    [[NSNotificationCenter defaultCenter]removeObserver:self];
                    [[NSNotificationCenter defaultCenter]postNotificationName:kUnloadLevelComplete object:nil];
                }];
            }
            else
                [tileLayer fadeToColor:[UIColor whiteColor] completion:nil];
        }
    }
}

- (void)loadLevel {
    // disable input until level is fully loaded
    // input will be re-enabled after all level events have been processed and animations finished
    [[NSNotificationCenter defaultCenter]postNotificationName:kDisableInput object:nil];
    //textLayer.opacity = 0.0;
    
    _level = [[Level alloc]init];
    _levelInfo = [_level loadLevel:[_levelNumber intValue]];
    
    // subdivide shortest dimension (width) of screen into squares
    float w = self.frame.size.width/_levelInfo.cols;
    float h = w; // make square
    
    // used to offset the anchor during x,y positioning
    // we don't want to adjust the anchor, because tile flipping animations should still occur around center
    float offset = w / 2;
    // reduce the size of the tile slightly, to create padding between tiles
    //  this is done as a percentage and not a pixel value to keep it resolution independent
    float padding = w * .4;
    
    // with the level information returned from load level, layout the board for all static tiles
    // static tiles will be flipped to moveable tiles once level events are processed
    // we will trigger level events by calling level restart at the end of this function
    for(int i = 0; i < _levelInfo.size; ++i) {
        float x = (i % _levelInfo.cols)*w + offset;
        float y = (i / _levelInfo.cols)*h + offset;
        
        // initialize and position the static tile
        int tt = [[_levelInfo.staticTiles objectAtIndex:i] intValue];
        TileLayer* tile = [[TileLayer alloc]initWithTileType:tt
                            atIndex:i];
        tile.bounds = CGRectMake(x, y, w-padding, h-padding);
        tile.position = CGPointMake(x, y);
        tile.opacity = 0;
        tile.opaque = NO;
        
        if(tt >= kBlockTile1 && tt % 2 != 0)
            tile.borderWidth = w * 0.1;
        
        [self.layer addSublayer:tile];
    }
    
    [TileLayer setFlipDuration:0.25f];
    _gestureDirection = UISwipeGestureRecognizerDirectionLeft;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(levelEvents:) name:@"levelEvents" object:nil];
    
    // animate moveable tiles onto the board by triggering a restart of the level
    // seems like a redundant initialization on the part of level, but the alternative is to track a restart in level and create new "position tile" events
    // with this one line we can maintain our existing list of tile events and reduce code
    [_level restart];
    
    // empty tiles become visible when player/blocks go out of bounds
    // immediately snap the opacity for empty tiles, avoiding implicit animation
    [CATransaction begin];
    [CATransaction disableActions];
    for(TileLayer* tileLayer in self.layer.sublayers) {
        if(tileLayer.originalTileType == kEmptyTile) {
            tileLayer.opacity = 1.0;
        }
    }
    [CATransaction commit];
    
    // fade-in the remaining tile types, attaching the callback to one instance only
    BOOL callbackSet = NO;
    for(TileLayer* tileLayer in self.layer.sublayers) {
        if(tileLayer.originalTileType != kEmptyTile) {
            if(!callbackSet) {
                callbackSet = YES;
                [tileLayer fadeIn:^ {
                    _shortCircuitDrawRect = YES;
                    [self setNeedsDisplay];
                    [[NSNotificationCenter defaultCenter]postNotificationName:kLoadLevelComplete object:nil];
                }];
            }
            else
                [tileLayer fadeIn:nil];
        }
    }
}

#pragma mark -

- (void)flipCurrentPlayerTilesToOriginal:(PlayerMovedEvent*)pme
                               direction:(UISwipeGestureRecognizerDirection)direction
                              startDelay:(float)delay
                              completion:(void (^)(void))callback {
    // flip the current player indices to their original tiles
    TileLayer* playerLayer1 = [self.layer.sublayers objectAtIndex:pme.curPlayerIndex1];
    [playerLayer1 flipToTileType:playerLayer1.originalTileType forDirection:direction startDelay:delay completion:callback];
    
    if(pme.curPlayerIndex2 != kNullTile) {
        TileLayer* playerLayer2 = [self.layer.sublayers objectAtIndex:pme.curPlayerIndex2];
        // we only need one completion callback, and that defaults to ever-present playerIndex1
        [playerLayer2 flipToTileType:playerLayer2.originalTileType forDirection:direction startDelay:delay completion:nil];
    }
}

- (void)flipPreviousPlayerTilesToOriginal:(PlayerMovedEvent*)pme
                                direction:(UISwipeGestureRecognizerDirection)direction
                               completion:(void (^)(void))callback {
    // this happens only on a level reset, nothing to flip so ignore
    if(pme.prevPlayerIndex1 == -1) {
        return;
    }
    
    TileLayer* playerLayer1 = [self.layer.sublayers objectAtIndex:pme.prevPlayerIndex1];
    [playerLayer1 flipToTileType:playerLayer1.originalTileType forDirection:direction startDelay:([TileLayer flipDuration] / 2)*pme.prevChainMultiplier1 completion:callback];
    if(pme.prevPlayerIndex2 != kNullTile) {
        TileLayer* playerLayer2 = [self.layer.sublayers objectAtIndex:pme.prevPlayerIndex2];
        [playerLayer2 flipToTileType:playerLayer2.originalTileType forDirection:direction startDelay:([TileLayer flipDuration] / 2)*pme.prevChainMultiplier2 completion:nil];
    }
}

- (void)flipCurrentPlayerTiles:(PlayerMovedEvent*)pme
                     direction:(UISwipeGestureRecognizerDirection)direction
                    completion:(void (^)(void))callback {
    // now flip current player tiles
    TileLayer* playerLayer1 = [self.layer.sublayers objectAtIndex:pme.curPlayerIndex1];
    [playerLayer1 flipToTileType:pme.tileType forDirection:direction startDelay:([TileLayer flipDuration] / 2)*pme.curChainMultiplier1 completion:callback];
    if(pme.curPlayerIndex2 != kNullTile) {
        TileLayer* playerLayer2 = [self.layer.sublayers objectAtIndex:pme.curPlayerIndex2];
        // we only need one completion callback, and that defaults to ever-present playerIndex1
        [playerLayer2 flipToTileType:pme.tileType forDirection:direction startDelay:([TileLayer flipDuration] / 2)*pme.curChainMultiplier2 completion:nil];
    }
}

- (void)flipCurrentPlayerTilesToOutOfBounds:(PlayerMovedEvent*)pme
                                  direction:(UISwipeGestureRecognizerDirection)direction
                                 startDelay:(float)delay
                                 completion:(void (^)(void))callback {
    TileLayer* playerLayer1 = [self.layer.sublayers objectAtIndex:pme.curPlayerIndex1];
    [playerLayer1 flipToTileType:kOutOfBoundsTile forDirection:_gestureDirection startDelay:delay completion:callback];
    if(pme.curPlayerIndex2 != kNullTile) {
        TileLayer* playerLayer2 = [self.layer.sublayers objectAtIndex:pme.curPlayerIndex2];
        // we only need one completion callback, and that defaults to ever-present playerIndex1
        [playerLayer2 flipToTileType:kOutOfBoundsTile forDirection:_gestureDirection startDelay:delay completion:nil];
    }
}

#pragma mark -

- (void)unlockWinTile:(WinTileUnlockedEvent*)wtue completion:(void (^)(void))callback {
    TileLayer* winLayer = [self.layer.sublayers objectAtIndex:wtue.index];
    // flip to win tile
    [winLayer flipToTileType:kWinTile forDirection:_gestureDirection startDelay:0 completion:^{
        // now flip to open tile
        [winLayer flipToTileType:kOpenTile forDirection:_gestureDirection startDelay:0 completion:^{
            // finally, flip back to win tile
           [winLayer flipToTileType:kWinTile forDirection:_gestureDirection startDelay:0 completion:^{
               // it's necessary to change original tile types as moveables will flip to target rolling on, and flip to original rolling off
               // unless of course, i implement a stack of targets that are pushed then popped.
               // i could then eliminate keeping _levelInfo around and resetting tiles would work proper
               // but stack could introduce whole new class of bugs
               winLayer.originalTileType = kWinTile;
               if(callback) {
                   callback();
               }
           }];
        }];
    }];
}

- (void)updateBlockTile:(BlockMovedEvent*)bme completion:(void (^)(void))callback {
    switch (bme.secondaryEventType) {
        case kLevelEventBlockUnlocked: {
            // flip to block
            TileLayer* blockLayer = [self.layer.sublayers objectAtIndex:bme.curIndex];
            [blockLayer flipToTileType:bme.tileType forDirection:_gestureDirection startDelay:([TileLayer flipDuration]/2)*bme.chainMultiplier completion:^{
                
                // now flip block back to original trigger
                TileLayer* blockLayer = [self.layer.sublayers objectAtIndex:bme.curIndex];
                [blockLayer flipToTileType:blockLayer.originalTileType forDirection:_gestureDirection startDelay:0 completion:^{
                    
                    // flip to an open tile
                    TileLayer* trigger = [self.layer.sublayers objectAtIndex:bme.curIndex];
                    // after an unlocked event, the trigger now has a new tile type
                    // it's pretty safe to assume that type is an open tile, but we use the
                    // new original tile type given by the level
                    trigger.originalTileType = bme.newOriginalTileType;
                    [trigger flipToTileType:kOpenTile forDirection:_gestureDirection startDelay:0 completion:^{
                        
                        if(callback) {
                            callback();
                        }
                    }];
                }];
            }];
            
        } break;
            
        case kLevelEventOutOfBounds: {
            // we want to flip the previous block index
            // however, if it's not empty our flip animation will soon get stomped, leading to glitches
            // I've tried combinations of removing animation keys in TileLayer, but this seems to work best
            if(bme.isPrevIndexEmpty) {
                // flip previous block to original
                if(bme.prevIndex != kNullTile) {
                    TileLayer* blockLayer = [self.layer.sublayers objectAtIndex:bme.prevIndex];
                    [blockLayer flipToTileType:blockLayer.originalTileType forDirection:_gestureDirection startDelay:0 completion:nil];
                }
            }
            // flip to block
            TileLayer* blockLayer = [self.layer.sublayers objectAtIndex:bme.curIndex];
            [blockLayer flipToTileType:bme.tileType forDirection:_gestureDirection startDelay:([TileLayer flipDuration]/2)*bme.chainMultiplier completion:^{
            
                // now flip to out of bounds
                TileLayer* blockLayer = [self.layer.sublayers objectAtIndex:bme.curIndex];
                [blockLayer flipToTileType:kOutOfBoundsTile forDirection:_gestureDirection startDelay:0 completion:^{
                    
                    if(callback) {
                        callback();
                    }
                }];
                
            }];
            
        } break;
            
        // if no significant block event occurred, default handles an uneventful block movement
        default: {
            // if the previous index of block1 is now empty we can flip it, no other moveable is going to stomp our animation
            if(bme.isPrevIndexEmpty) {
                if(bme.prevIndex != kNullTile) {
                    // flip previous block to original
                    TileLayer* blockLayer = [self.layer.sublayers objectAtIndex:bme.prevIndex];
                    [blockLayer flipToTileType:blockLayer.originalTileType forDirection:_gestureDirection startDelay:([TileLayer flipDuration]/2)*bme.chainMultiplier completion:nil];
                }
            }
            // flip to block
            TileLayer* blockLayer = [self.layer.sublayers objectAtIndex:bme.curIndex];
            [blockLayer flipToTileType:bme.tileType forDirection:_gestureDirection startDelay:([TileLayer flipDuration]/2)*bme.chainMultiplier completion:^{
                
                if(callback) {
                    callback();
                }
            }];
            
        } break;
    }
}

- (void)updatePlayerTiles:(PlayerMovedEvent*)pme completion:(void (^)(void))callback {
    switch (pme.secondaryEventType) {
            // TEMP: do something with more jazz
        case kLevelEventPlayerWon: {
            [self flipPreviousPlayerTilesToOriginal:pme direction:_gestureDirection completion:nil];
            
            // flip win tile to player tlie
            [self flipCurrentPlayerTiles:pme direction:_gestureDirection completion:^{
                
                // now flip player tile back to win tile
                [self flipCurrentPlayerTilesToOriginal:pme direction:_gestureDirection startDelay:0 completion:^{
                    if(callback) {
                        callback();
                    }
                }];
            }];
        } break;
            
        case kLevelEventBrokeTile:
        case kLevelEventOutOfBounds: {
            [self flipPreviousPlayerTilesToOriginal:pme direction:_gestureDirection completion:nil];
            
            // flip empty/breakable tile to player tile
            [self flipCurrentPlayerTiles:pme direction:_gestureDirection completion:^{
                
                // flip player to out of bounds (red) tile
                [self flipCurrentPlayerTilesToOutOfBounds:pme direction:_gestureDirection startDelay:0 completion:^{
                    
                    if(callback) {
                        callback();
                    }
                }];
            }];
        } break;
            
        default: { // no significant interactions, handle player movement on board
            [self flipPreviousPlayerTilesToOriginal:pme direction:_gestureDirection completion:nil];
            [self flipCurrentPlayerTiles:pme direction:_gestureDirection completion:^{
                
                if(callback) {
                    callback();
                }
            
            }];
        } break;
    }
}

#pragma mark -

// process the events dictionary dispatched from level
- (void)levelEvents:(NSNotification*)note {
    NSMutableDictionary* events = [note object];
    
    // we use a dispatch group to wait for all asynchronous animations to complete
    dispatch_group_t group = dispatch_group_create();
    
    PlayerMovedEvent* pme = [events objectForKey:kPlayerMovedEventKey];
    dispatch_group_enter(group);
    [self updatePlayerTiles:pme completion:^{
        
        // flag group that we're done
        dispatch_group_leave(group);
    }];
    
    NSArray* blockMovements = [events objectForKey:kBlockMovementsEventKey];
    if(blockMovements != nil)
    {
        for(BlockMovedEvent* bme in blockMovements) {
            
            dispatch_group_enter(group);
            [self updateBlockTile:bme completion:^{
            
                // flag group that we're done
                dispatch_group_leave(group);
            }];
        }
    }
    
    // wait on a background thread for all entered groups to flag us
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        // wait forever for all leave group flags
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        // all asynch animations have completed, return to the main thread for further event processing
        dispatch_async(dispatch_get_main_queue(), ^{
            // does the level need to be restarted?
            BOOL restartFlag = NO;
            
            // first check the player for events that would restart the level
            if(pme.secondaryEventType == kLevelEventOutOfBounds ||
               pme.secondaryEventType == kLevelEventBrokeTile ||
               pme.secondaryEventType == kLevelEventPlayerWon) { // TEMP: player won
                restartFlag = YES;
            }
            
            // if nothing was found, check the block movements for events that would trigger a restart
            if(!restartFlag && blockMovements != nil) {
                for(BlockMovedEvent* bme in blockMovements) {
                    if(bme.secondaryEventType == kLevelEventOutOfBounds) {
                        restartFlag = YES;
                        break;
                    }
                }
            }
            
            if(restartFlag) {
                if(pme.secondaryEventType == kLevelEventPlayerWon) {
                    
                    float flipDuration = 0.025f;
                    float largestMultiplier = 0;
                    NSDictionary* winAnim = [_level winChainMultipliers];
                    for(NSNumber* index in winAnim.allKeys) {
                        
                        NSNumber* multiplier = [winAnim objectForKey:index];
                        
                        if([multiplier intValue] > largestMultiplier)
                            largestMultiplier = [multiplier intValue];
                        
                        TileLayer* tileLayer = [self.layer.sublayers objectAtIndex:[index intValue]];
                        [tileLayer flipToTileType:kWinTile forDirection:UISwipeGestureRecognizerDirectionLeft startDelay:[multiplier intValue]*flipDuration completion:nil];
                    }
                    
                    // flip empty tile
                    TileLayer* emptyTile = [self.layer.sublayers objectAtIndex:0];
                    [emptyTile flipToTileType:kEmptyTile forDirection:UISwipeGestureRecognizerDirectionLeft startDelay: ++largestMultiplier * flipDuration completion:^{
                        [[NSNotificationCenter defaultCenter]postNotificationName:kUnlockNextLevel object:nil];
                    }];
                    
                }
                else {
                    int i = 0;
                    for(TileLayer* tileLayer in self.layer.sublayers) {
                        // grab the original tile from the list of static tiles returned on load level
                        TileType tt = [[_levelInfo.staticTiles objectAtIndex:i] integerValue];
                        // flip all layers that that are not their original type (less common), or are on a target type that equals their orignal type (more common)
                        if(tt != tileLayer.originalTileType || ![tileLayer isOnTargetTile]) {
                            tileLayer.originalTileType = tt;
                            // now flip this layer to its original type
                            // here again, we're using dispatch group to wait for the completion of
                            // potentially several asynchronous animations
                            dispatch_group_enter(group);
                            [tileLayer flipToTileType:tileLayer.originalTileType forDirection:_gestureDirection startDelay:0 completion:^{
                                dispatch_group_leave(group);
                            }];
                        }
                        ++i;
                    }
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
                        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // level restart will be called, causing another send level events notification
                            // once original tiles are flipped, enable input will be called below
                            [_level restart];
                        });
                    });
                }
            }
            else {
                
                // no restart event has been detected
                // our last check is for a win tile unlocked event
                WinTileUnlockedEvent* wtue = [events objectForKey:kWinTileUnlockedEventKey];
                if(wtue != nil) {
                    [self unlockWinTile:wtue completion:^{
                        
                        // once the win unlock animation is complete, we've reached the end of
                        // this event processing path and can re-enable user input
                        [[NSNotificationCenter defaultCenter]postNotificationName:kEnableInput object:nil];
                    }];
                }
                else {
                    // finally, we've reached the end of event processing
                    // now that all animations are complete, we enable user input
                    [[NSNotificationCenter defaultCenter]postNotificationName:kEnableInput object:nil];
                }
            }
        });
    });
}

- (void)swipe:(UISwipeGestureRecognizerDirection)direction {
    [[NSNotificationCenter defaultCenter]postNotificationName:kDisableInput object:nil];
    
    _gestureDirection = direction;
    [_level movePlayer:direction];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!_isLocked)
        [[NSNotificationCenter defaultCenter]postNotificationName:kLevelSelected object:self];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextSetAllowsAntialiasing(context, false);
    
    CGContextSetFillColorWithColor(context, [TileLayer colorForTileType:kEmptyTile].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    
    if(_shortCircuitDrawRect) {
        CGContextRestoreGState(context);
        return;
    }
    
    // draw rect is used for drawing mini level in scroll view
    // upon level load, layers are used
    
    uint size = [Level sizeForLevelNumber:[_levelNumber integerValue]];
    uint cols = [Level numColsForLevelNumber:[_levelNumber integerValue]];
    unsigned char* tiles = [Level tilesForLevelNumber:[_levelNumber integerValue]];
    
    float w = self.frame.size.width/cols;
    float h = w; // make square
    float padding = w * .4;
    
    float offset = padding/2;
    
    for(int i = 0; i < size; ++i) {
        
        float x = (i % cols)*w + offset;
        float y = (i / cols)*h + offset;
        
        TileType tt = tiles[i];
        
        if(tt == kEmptyTile)
            continue;
        
        CGContextSetFillColorWithColor(context, [TileLayer colorForTileType:_isLocked ? kLockedTile : kUnlockedTile].CGColor);
        
        CGContextFillRect(context, CGRectMake(x, y, w-padding, h-padding));
    }

    CGContextRestoreGState(context);
}

@end
