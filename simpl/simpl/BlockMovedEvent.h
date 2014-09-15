//
//  BlockMovedEvent.h
//  simpl
//
//  Created by Oakenfold, Ash on 13-05-07.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import "LevelEvent.h"

NSString* const kBlockMovementsEventKey;

@interface BlockMovedEvent : LevelEvent

@property (assign, nonatomic) int curIndex;
@property (assign, nonatomic) int prevIndex;

@property (assign, nonatomic) BOOL isPrevIndexEmpty;

@property (assign, nonatomic) int chainMultiplier;

// used for block unlocked events
// for example, the index once occupied by a trigger should now change it's original type to an open tile
@property (assign, nonatomic) int newOriginalTileType;

@end
