//
//  planeManager.h
//  Plane
//
//  Created by Peng, Yan on 3/19/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "photoPlane.h"

#define NUM_OF_VERTICES 4
#define NUM_OF_INDICES 6
#define PLANE_SIZE 0.2
#define PLANE_GAP  0.1
#define SPHERE_GAP_FACTOR 1
#define SPHERE_Y_AXIS_SCALE_FACTOR 0.9

@class EaseFunction;

typedef enum EnumPointPosition{
    LEFT_BOTTOM = 0,
    RIGHT_BOTTOM,
    RIGHT_TOP,
    LEFT_TOP
}EnumPointPosition;

@interface PlaneManager : NSObject<planeDataSourceDelegate>

@property (nonatomic) size_t sizeofVertices;
@property (nonatomic) size_t sizeofTextureCoordinates;
@property (nonatomic) size_t sizeofIndices;
@property (nonatomic) size_t sizeofColors;
@property (nonatomic) BOOL shouldDrawPlane;
@property (nonatomic) BOOL shapeSwitchAnimation;
@property (nonatomic) BOOL selectPlaneAnimation;
@property (nonatomic) NSInteger selectAnimationTime;
@property (nonatomic) EaseFunction* easeFunction;

- (id) initWithRowCount:(NSUInteger)row ColumnCount:(NSUInteger)column;
- (void) updatePlanes;
- (void) updatePlanesForSwitchShapeAnimation;
- (void) updatePlanesAnimationPostion:(NSTimeInterval)ratio;

- (PhotoPlane*) findPhotoPlaneByFalseColor:(GLKVector4)falseColor;
- (void) updateSelectedPlaneWithFalseColor:(GLKVector4)falseColor;
- (void) updateSelectPlanesAnimation;

- (GLKVector3*) managerVertices;
- (GLKVector2*) managerTextureCoordinates;
- (GLushort*) managerIndices;
- (GLKVector4*) managerColors;

- (void)freeResources;

- (void)initEaseFunction;

@end
