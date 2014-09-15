//
//  Level.h
//  simpl
//
//  Created by Edward Oakenfold on 2013-03-13.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

@class LevelInfo;

// so my algo shouldn't care what it's pushing, only that it's not empty
// could check if block moveable is within a range
// if it's an even number it's a block, +1 to get it's trigger
// you can move kBlockTile1..kBlockTileN to end of enum, accomodating any # after that

typedef enum
{
    kNullTile            = -1,
    kEmptyTile           = 10,
    kOpenTile            = 11,
    kPlayerTile          = 12,
    kWinTile             = 13,
    kWinTileLocked       = 14,
    kBreakableTile       = 22,
    kOutOfBoundsTile     = 30,
    kOriginalTile        = 31,
    kLockedTile          = 32,
    kUnlockedTile        = 33,
    
    kBlockTile1          = 50,
    kBlockTriggerTile1   = 51,
    kBlockTile2          = 52,
    kBlockTriggerTile2   = 53,
    kBlockTile3          = 54,
    kBlockTriggerTile3   = 55,
    kBlockTile4          = 56,
    kBlockTriggerTile4   = 57,
    
    // # of supported blocks designed to be open-ended
    // code assumes:
    //  - anything greater than kBlockTile1 is a block
    //  - all blocks are paired with a trigger
    //  - blocks are even numbers, triggers odd
    
} TileType;

@interface Level : NSObject

+ (uint)numColsForLevelNumber:(NSUInteger)number;
+ (uint)numRowsForLevelNumber:(NSUInteger)number;
+ (uint)sizeForLevelNumber:(NSUInteger)number;
+ (unsigned char*)tilesForLevelNumber:(NSUInteger)number;
+ (int)totalNumberOfLevels;
+ (int)moveCounterForLevelNumber:(NSUInteger)number;

- (LevelInfo*)loadLevel:(NSUInteger)number;
- (void)movePlayer:(UISwipeGestureRecognizerDirection)direction;
- (void)restart;
- (NSMutableDictionary*)winChainMultipliers;

@end
