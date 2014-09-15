//
//  LevelInfo.h
//  simpl
//
//  Created by Edward Oakenfold on 2013-05-11.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

@interface LevelInfo : NSObject

// of TileType enum, does not include dynamic (moveable) tiles like player and blocks which are overlayed on top of static board
// although trigger couuld be considered dynamic becasuse it causes an unlock event, it is considered static
// only objects that can move around the board are considered dyamic
@property (strong, nonatomic) NSArray* staticTiles;
@property (assign, nonatomic) int cols;
@property (assign, nonatomic) int size;

@end
