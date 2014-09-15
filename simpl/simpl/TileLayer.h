//
//  TileLayer.h
//  simpl
//
//  Created by Edward Oakenfold on 2013-04-21.
//  Copyright (c) 2013 Edward Oakenfold. All rights reserved.
//

#import "Level.h"

@interface TileLayer : CALayer

@property (assign, nonatomic) TileType originalTileType;

- (id)initWithTileType:(TileType)tileType atIndex:(int)index;
- (void)flipToTileType:(TileType)tileType forDirection:(UISwipeGestureRecognizerDirection)direction startDelay:(float)delay completion:(void (^)(void))callback;
- (BOOL)isOnTargetTile;
- (void)fadeIn:(void (^)(void))callback;
- (void)fadeToColor:(UIColor*)color completion:(void (^)(void))callback;

+ (float)flipDuration;
+ (void)setFlipDuration:(float)value;
+ (UIColor*)colorForTileType:(TileType)tileType;

@end
