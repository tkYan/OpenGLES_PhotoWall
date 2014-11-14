//
//  photoPlane.m
//  Plane
//
//  Created by Peng, Yan on 3/19/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "photoPlane.h"
#import "EaseFunction.h"

#define SELECT_PLANE_ANIMATION_DURATION 2000

@implementation PhotoPlane{
    GLKVector4 color;
    BOOL selectAnimation;
    GLfloat selectOffset;
    NSDate* selectTime;
    __unsafe_unretained id<planeDataSourceDelegate> delegate;
    GLfloat startSelectOffset;
}

@synthesize index = _index;
@synthesize row;
@synthesize col;
@synthesize size;
@synthesize position;
@synthesize rotation;
@synthesize color;
@synthesize selected = _selected;
@synthesize radius;
@synthesize shouldDrawPlane = _shouldDrawPlane;
@synthesize startPosition;
@synthesize endPosition;
@synthesize startRotation;
@synthesize endRotation;
@synthesize selectOffset;
@synthesize selectAnimation = _selectAnimation;
@synthesize delegate;

- (id)initWithIndex:(NSUInteger) Index
                row:(NSUInteger) Row
                col:(NSUInteger) Col{
    self = [super init];
    if (self) {
        self.index = Index;
        self.row = Row;
        self.col = Col;
        self.selected = NO;
        self.selectAnimation = NO;
        selectOffset = 0;
        selectTime = nil;
//        color = GLKVector4Make(0.0, 0.0, 0.0, 0.0);
    }
    return self;
}

- (void)setIndex:(NSUInteger)index{
    _index = index;
    [self updateColor];
}

- (void)setShouldDrawPlane:(BOOL)shouldDrawPlane{
    if (_shouldDrawPlane != shouldDrawPlane) {
        _selected = NO;
        _shouldDrawPlane = shouldDrawPlane;
    }
}

- (void)setSelectAnimation:(BOOL)iselectAnimation{
        _selectAnimation = iselectAnimation;
        if (_selectAnimation) {
            selectTime = [NSDate date];
            startSelectOffset = selectOffset;
        }
}

- (void)updateSelectedInfo{
    if (_shouldDrawPlane){
        position.z += selectOffset;
    }else{
        radius += selectOffset;
    }
}

- (BOOL)updateSelectOffsetShouldContinue{
    NSTimeInterval diff = -[selectTime timeIntervalSinceNow];
    GLfloat max = SELECTED_MOVE_Z;
    GLfloat min = 0.0;
    if (_selected) {
        selectOffset = [delegate getSelectOffsetWithCurrentTIme:diff
                                                     startValue:startSelectOffset
                                                       endValue:max];
        if (selectOffset > max - 0.001) {
            selectOffset = max;
            _selectAnimation = NO;
            return NO;
        }
    }else{
        selectOffset = [delegate getSelectOffsetWithCurrentTIme:diff
                                                     startValue:startSelectOffset
                                                       endValue:-startSelectOffset];
        if (selectOffset < min + 0.001) {
            selectOffset = min;
            _selectAnimation = NO;
            return NO;
        }
    }
//    NSLog(@"%f",selectOffset);
    return YES;
}

- (void)resetSelectInfo{
    selectOffset = 0.0;
    _selected = NO;
    _selectAnimation = NO;
}

- (void)updateColor{
    NSUInteger colorNum = self.index + 1;
    NSAssert((colorNum >> 24) == 0, @"Index is too large, we only support 2^24 - 1 objects in this demo!");
    
    color.r = (colorNum & 0x000000FF) / 255.0;
    colorNum >>= 8;
    color.g = (colorNum & 0x000000FF) / 255.0;
    colorNum >>= 8;
    color.b = colorNum / 255.0;
}

+ (NSInteger)getIndexFromColor:(GLKVector4)color{
    return (lroundf(color.r * 255) + (lroundf(color.g * 255) << 8) + (lroundf(color.b * 255) << 16) - 1);
}

@end
