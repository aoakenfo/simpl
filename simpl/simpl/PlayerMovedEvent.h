//
//  PlayerMovedEvent.h
//  simpl
//
//  Created by Oakenfold, Ash on 13-05-07.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import "LevelEvent.h"

NSString* const kPlayerMovedEventKey;

@interface PlayerMovedEvent : LevelEvent

// player can occupy either 1 or 2 tile positions depending on "orientation"
@property (assign, nonatomic) int curPlayerIndex1;
@property (assign, nonatomic) int curPlayerIndex2;

@property (assign, nonatomic) int curChainMultiplier1;
@property (assign, nonatomic) int curChainMultiplier2;

@property (assign, nonatomic) int prevPlayerIndex1;
@property (assign, nonatomic) int prevPlayerIndex2;

@property (assign, nonatomic) int prevChainMultiplier1;
@property (assign, nonatomic) int prevChainMultiplier2;

@property (assign, nonatomic) BOOL rollingSideways;

@end
