//
//  planeManager.m
//  Plane
//
//  Created by Peng, Yan on 3/19/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "planeManager.h"
#import "EaseFunction.h"

#define ZOOM_FACTOR_FOR_SELECT 2
#define PHI_COMPUTE(i) (M_PI_2 - M_PI * (i + SPHERE_GAP_FACTOR) / (rowCount - 1 + 2 * SPHERE_GAP_FACTOR)) * SPHERE_Y_AXIS_SCALE_FACTOR

static GLfloat halfSize = (PLANE_SIZE * 1.0) / 2;
static GLfloat planeLenth = PLANE_SIZE + PLANE_GAP;

@implementation PlaneManager
{
    size_t sizeofVertices;
    size_t sizeofTextureCoordinates;
    size_t sizeofIndices;
    size_t sizeofColors;
    
    GLKVector3* vertices;
    GLKVector2* textureCoordinates;
    GLushort* indices;
    GLKVector4* colors;
    
    NSUInteger rowCount;
    NSUInteger colCount;
    NSUInteger numOfPlanes;
    
    NSMutableArray *planes;
    
    //help data
    GLfloat xStart;
    GLfloat yStart;
    GLfloat sphereRoundFactor;
    GLfloat radius;
    BOOL    shapeSwitchAnimation;
    BOOL    selectPlaneAnimation;
    
    NSInteger selectAnimationTime;
    EaseFunction* easeFunction;
}


@synthesize sizeofVertices;
@synthesize sizeofTextureCoordinates;
@synthesize sizeofIndices;
@synthesize sizeofColors;
@synthesize shouldDrawPlane;
@synthesize shapeSwitchAnimation;
@synthesize selectPlaneAnimation;
@synthesize selectAnimationTime;
@synthesize easeFunction;

int planeIndexVector[6] = {0, 1, 2, 2, 3, 0};

#pragma mark -

- (id) initWithRowCount:(NSUInteger)row ColumnCount:(NSUInteger)column{
    NSAssert(row >=0 && column >=0, @"Invalid Argument, row and column should be non-negative number, row = %lu, col = %lu", (unsigned long)row, (unsigned long)column);
    self = [super init];
    if (self) {
        rowCount = row;
        colCount = column;
        numOfPlanes = rowCount * colCount;
        shouldDrawPlane = YES;
        [self initData];
        shapeSwitchAnimation = NO;
        selectPlaneAnimation = NO;
    }
    return self;
}

- (void) initData{
    [self initHelpData];
    [self initBuffer];
    [self initPlanes];
    [self updatePlanes];
}

#pragma mark - public help function

- (void) updatePlanes{
    for (PhotoPlane* photoPlane in planes){
        [self updateSpecifiedPlane:photoPlane];
        [self updateTCI:photoPlane];
    }
}

- (void) initEaseFunction{
    if (!easeFunction) {
        easeFunction = [[EaseFunction alloc] init];
        easeFunction.tag = Linear;
    }
}

#pragma mark - internal help function

//update texture, false color, indice
- (void) updateTCI:(PhotoPlane*) photoPlane{
    if (!photoPlane) {
        return;
    }

    NSUInteger index = photoPlane.index * NUM_OF_VERTICES;
    NSUInteger row = photoPlane.row;
    NSUInteger column = photoPlane.col;
    
    //update texture&false color
    for (NSUInteger i = 0; i < NUM_OF_VERTICES; ++i){
        switch (i) {
            case LEFT_BOTTOM:{
                textureCoordinates[index + i].s = (column+1)*1.0f/colCount;
                textureCoordinates[index + i].t = (row+1)*1.0f/rowCount;
                break;
            }
            case RIGHT_BOTTOM:{
                textureCoordinates[index+i].s = column*1.0f/colCount;
                textureCoordinates[index+i].t = (row+1)*1.0f/rowCount;
                break;
            }
            case RIGHT_TOP:{
                textureCoordinates[index+i].s = column*1.0f/colCount;
                textureCoordinates[index+i].t = row*1.0f/rowCount;
                break;
            }
            case LEFT_TOP:{
                textureCoordinates[index+i].s = (column+1)*1.0f/colCount;
                textureCoordinates[index+i].t= row*1.0f/rowCount;
                break;
            }
                
            default:
                assert(0);
        }

        colors[index+i] = GLKVector4AddScalar(photoPlane.color, 0.0);
    }
    
    //update indices
    NSUInteger indice = photoPlane.index * NUM_OF_INDICES;
    for (int j=0; j<NUM_OF_INDICES; j++) {
        indices[indice + j] = index + planeIndexVector[j];
    }
}

- (GLKVector3)getVetexFromPosition:(EnumPointPosition)position{
    switch (position) {
        case LEFT_BOTTOM:{
            return GLKVector3Make(-halfSize, -halfSize, 0.0);
        }
        case RIGHT_BOTTOM:{
            return GLKVector3Make(halfSize, -halfSize, 0.0);
        }
        case RIGHT_TOP:{
            return GLKVector3Make(halfSize, halfSize, 0.0);
        }
        case LEFT_TOP:{
            return GLKVector3Make(-halfSize, halfSize, 0.0);
        }
            
        default:
            assert(0);
    }
}

- (void)updateSpecifiedPlane:(PhotoPlane*)plane{
    if (!plane) {
        return;
    }
    
    plane.shouldDrawPlane = shouldDrawPlane;
    if (shouldDrawPlane) {
        [self updatePositonAndRotationForPlaneOf:plane];
    }else{
        [self updatePositonAndRotationForSphereOf:plane];
    }
    if (!shapeSwitchAnimation) {
        [self updateVerticesFor:plane];
    }
}

- (void)updateVerticesFor:(PhotoPlane*) photoPlane{
    GLKVector3 rotation = photoPlane.rotation;
    NSUInteger index = photoPlane.index * NUM_OF_VERTICES;
    
    for (NSUInteger i = 0; i < NUM_OF_VERTICES; ++i){
        GLKVector3 newVertex = [self getVetexFromPosition:(EnumPointPosition)i];
        newVertex = GLKVector3MultiplyScalar(newVertex, (1.0 + ZOOM_FACTOR_FOR_SELECT * photoPlane.selectOffset));
        if (rotation.x || rotation.y || rotation.z) {
            GLKMatrix3 rotationMatrix;
            rotationMatrix = GLKMatrix3Multiply(GLKMatrix3MakeZRotation(rotation.z), GLKMatrix3Multiply(GLKMatrix3MakeYRotation(rotation.y), GLKMatrix3MakeXRotation(rotation.x)));
            newVertex = GLKMatrix3MultiplyVector3(rotationMatrix, newVertex);
        }
        newVertex = GLKVector3Add(newVertex, photoPlane.position);
        vertices[index+i] = newVertex;
    }
}

- (void)updatePlane:(PhotoPlane*) photoPlane
           position:(GLKVector3)position
           rotation:(GLKVector3)rotation{
    if (shapeSwitchAnimation) {
        photoPlane.startPosition = photoPlane.position;
        photoPlane.startRotation = photoPlane.rotation;
        
        photoPlane.endPosition = position;
        photoPlane.endRotation = rotation;
    }else{
        photoPlane.position = position;
        photoPlane.rotation = rotation;
    }
}

#pragma mark - switch shape

- (void) updatePlanesForSwitchShapeAnimation{
    shapeSwitchAnimation = YES;
    selectPlaneAnimation = NO;
    for (PhotoPlane* photoPlane in planes){
        [photoPlane resetSelectInfo];
        [self updateSpecifiedPlane:photoPlane];
    }
}

- (void) updatePlanesAnimationPostion:(NSTimeInterval)ratio{
    for (PhotoPlane* photoPlane in planes){
        
        photoPlane.position = GLKVector3Add(photoPlane.startPosition, GLKVector3MultiplyScalar(GLKVector3Subtract(photoPlane.endPosition, photoPlane.startPosition), ratio));
        photoPlane.rotation = GLKVector3Add(photoPlane.startRotation, GLKVector3MultiplyScalar(GLKVector3Subtract(photoPlane.endRotation, photoPlane.startRotation), ratio));
        
        [self updateVerticesFor:photoPlane];
    }
}

#pragma mark - select plane

- (PhotoPlane*) findPhotoPlaneByFalseColor:(GLKVector4)falseColor{
    NSInteger index = [PhotoPlane getIndexFromColor:falseColor];
    if (index < 0) {
        return nil;
    }
    
    return [planes objectAtIndex:index];
}

- (void) updateSelectedPlaneWithFalseColor:(GLKVector4)falseColor{
    PhotoPlane* plane = [self findPhotoPlaneByFalseColor:falseColor];
    
    if (plane) {
        plane.selected = !plane.selected;
        plane.selectAnimation = YES;
        selectPlaneAnimation = YES;
    }
    
}

- (void) updateSelectPlanesAnimation{
    BOOL selectAnimationEnd = YES;
    for (PhotoPlane* photoPlane in planes){
        if (photoPlane.selectAnimation) {
            if ([photoPlane updateSelectOffsetShouldContinue]) {
                selectAnimationEnd = NO;
            }
        }
        [self updateSpecifiedPlane:photoPlane];
    }
    selectPlaneAnimation = !selectAnimationEnd;
}

#pragma mark - plane

- (void) updatePositonAndRotationForPlaneOf:(PhotoPlane*) photoPlane{
    float x = xStart + photoPlane.row * planeLenth;
    float y = yStart + photoPlane.col * planeLenth;
    
    [self updatePlane:photoPlane position:GLKVector3Make(x, y, 0.0) rotation:GLKVector3Make(0.0, 0.0, 0.0)];
    
    [photoPlane updateSelectedInfo];
}

#pragma mark - sphere

- (void) updatePositonAndRotationForSphereOf:(PhotoPlane*) photoPlane{
    photoPlane.radius = radius;
    [photoPlane updateSelectedInfo];
    
    //theta should be in the range of [0,2PI)
    float theta = 2 *  M_PI * photoPlane.col / colCount;
    
    //phi should be in the range of (-PI/2,PI/2), add gap at bottom and top to make top of the planes not overlapped, add scale to make the gap between plane not too large
    float phi = PHI_COMPUTE(photoPlane.row);
    
    float x = photoPlane.radius * cosf(theta) * cosf(phi);
    float y = photoPlane.radius * sinf(phi);
    float z = photoPlane.radius * sinf(theta) * cosf(phi);
    
    [self updatePlane:photoPlane position:GLKVector3Make(x, y, z) rotation:GLKVector3Make(-phi, M_PI_2 - theta, 0.0)];
}

#pragma mark - resources manage

- (void) initHelpData{
    xStart = -planeLenth * (rowCount - 1) / 2;
    yStart = -planeLenth * (colCount - 1) / 2;
    
    //make top of the plane not overlapped, the circumference of the top planes should be the sum of plane size
    sphereRoundFactor = 1 / (2 * cosf( PHI_COMPUTE(0)));
    radius = PLANE_SIZE * M_1_PI * colCount * sphereRoundFactor;

}

- (void) initBuffer{
    //init size and allocate buffer
    sizeofVertices = NUM_OF_VERTICES * numOfPlanes * sizeof(GLKVector3);
    sizeofTextureCoordinates = NUM_OF_VERTICES * numOfPlanes * sizeof(GLKVector2);
    sizeofIndices = NUM_OF_INDICES * numOfPlanes * sizeof(GLushort);
    sizeofColors = NUM_OF_VERTICES * numOfPlanes * sizeof(GLKVector4);
    
    vertices = (GLKVector3*)malloc(sizeofVertices);
    textureCoordinates = (GLKVector2*)malloc(sizeofTextureCoordinates);
    indices = (GLushort*)malloc(sizeofIndices);
    colors = (GLKVector4*)malloc(sizeofColors);
}

- (void) initPlanes{
    planes = [[NSMutableArray alloc] initWithCapacity:numOfPlanes];
    
    NSUInteger count = 0;
    for (NSUInteger row = 0; row < rowCount; ++row) {
        for (NSUInteger col = 0; col < colCount; ++col) {
            PhotoPlane* photoPlane = [[PhotoPlane alloc] initWithIndex:count row:row col:col];
            photoPlane.delegate = self;
            [planes addObject:photoPlane];
            ++count;
        }
    }
}

- (GLKVector3*) managerVertices
{
    return vertices;
}
- (GLKVector2*) managerTextureCoordinates
{
    return textureCoordinates;
}
- (GLushort*) managerIndices
{
    return indices;
}
- (GLKVector4*) managerColors
{
    return colors;
}

- (void) dealloc {
    [self freeResources];
}

- (void)freeResources
{
    free(vertices);
    vertices = nil;
    free(textureCoordinates);
    textureCoordinates = nil;
    free(indices);
    indices = nil;
    free(colors);
    colors = nil;
}

#pragma mark - planeDataSourceDelegate

- (GLfloat)getSelectOffsetWithCurrentTIme:(GLfloat)currentTime
                               startValue:(GLfloat)startValue
                                 endValue:(GLfloat)endValue{
    return [easeFunction getOffsetFromEaseFunctionWithCurrentTIme:currentTime
                                                       startValue:startValue
                                                         endValue:endValue];
}

@end
