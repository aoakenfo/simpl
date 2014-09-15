//
//  WinTileUnlockedEvent.h
//  simpl
//
//  Created by Oakenfold, Ash on 13-05-14.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import "LevelEvent.h"

NSString* const kWinTileUnlockedEventKey;

@interface WinTileUnlockedEvent : LevelEvent

@property (assign, nonatomic) int index;

@end
