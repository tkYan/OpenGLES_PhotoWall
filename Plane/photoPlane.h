//
//  photoPlane.h
//  Plane
//
//  Created by Peng, Yan on 3/19/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@protocol planeDataSourceDelegate <NSObject>

-(GLfloat)getSelectOffsetWithCurrentTIme:(GLfloat)currentTime
                              startValue:(GLfloat)startValue
                                endValue:(GLfloat)endValue;

@end

@interface PhotoPlane : NSObject

@property (nonatomic) NSUInteger index;
@property (nonatomic) NSUInteger row;
@property (nonatomic) NSUInteger col;
@property (nonatomic) CGSize    size;

@property (nonatomic) GLKVector3 position;
@property (nonatomic) GLKVector3 rotation;
@property (nonatomic) GLKVector4 color;
@property (nonatomic) BOOL selected;
@property (nonatomic) GLfloat radius;
@property (nonatomic) BOOL shouldDrawPlane;

@property (nonatomic) GLKVector3 startPosition;
@property (nonatomic) GLKVector3 startRotation;
@property (nonatomic) GLKVector3 endPosition;
@property (nonatomic) GLKVector3 endRotation;

@property (nonatomic) GLfloat selectOffset;
@property (nonatomic) BOOL selectAnimation;

@property (nonatomic, unsafe_unretained) id<planeDataSourceDelegate> delegate;

- (id)initWithIndex:(NSUInteger) Index
                row:(NSUInteger) Row
                col:(NSUInteger) Col;

- (void)updateSelectedInfo;
- (BOOL)updateSelectOffsetShouldContinue;
- (void)resetSelectInfo;

//return -1 for pure black color (0,0,0,0~1), alpha channel is ignored
+ (NSInteger)getIndexFromColor:(GLKVector4)color;

@end
