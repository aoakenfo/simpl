//
//  LevelEvent.h
//  simpl
//
//  Created by Oakenfold, Ash on 13-05-07.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Level.h"

typedef enum
{
    kLevelEventUndefined,
    kLevelEventPlayerWon,
    kLevelEventBrokeTile,
    kLevelEventOutOfBounds,
    kLevelEventBlockUnlocked
    
} LevelEventType;

@interface LevelEvent : NSObject

@property (assign, nonatomic) LevelEventType secondaryEventType;    // ie. kLevelEventOutOfBounds

@property (assign, nonatomic) TileType tileType;

@end
