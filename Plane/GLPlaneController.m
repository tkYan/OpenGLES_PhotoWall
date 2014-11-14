//
//  GLPlaneController.m
//  Plane
//
//  Created by Peng, Yan on 3/3/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "GLPlaneController.h"

#import "planeManager.h"
#import "EaseFunction.h"

#define STARTING_Z 12
#define RotateFactor 0.01
#define MinScaleFactor 0.5
#define MaxScaleFactor 2
#define MAX_ROW 20
#define MAX_COL 25
#define Sensitivity 0.8
#define VelocityFactor 0.04
#define SWITCH_SHAPE_DURATION 5000
#define DEFAULT_ANIMATION_TIME 2
#define MAX_SELECT_ANIMATION_TIME 5
#define MIN_SELECT_ANIMATION_TIME 1

@interface GLPlaneController ()

@property (strong, nonatomic) EAGLContext* context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation GLPlaneController
{
    GLfloat scaleFactor;
    GLfloat rotateX;
    GLfloat rotateY;
    GLKMatrix4 rotateMatrix;
    
    size_t sizeofVertices;
    size_t sizeofTextureCoordinates;
    size_t sizeofIndices;
    size_t sizeofColors;
    
    GLKVector3* vertices;
    GLKVector2* textureCoordinates;
    GLushort* indices;
    GLKVector4* colors;
    
    GLuint vertexBuffer;
    GLuint textureCoordinateBuffer;
    GLuint indicesBuffer;
    GLuint colorBuffer;
    PlaneManager* planeManager;
    
    BOOL isDragging;
    GLKVector2 velocity;
    NSDate* tapTime;
    
    //UI related
    __weak IBOutlet UIPickerView *pickView;
    NSArray* easeFunctionCollection;
    __weak IBOutlet UISlider *selectAnimationSlider;
    __weak IBOutlet UILabel *selectAnimationTime;
}

@synthesize context = _context;
@synthesize effect = _effect;

#pragma mark - Init&Dealloc

- (void)initParameter{
    scaleFactor = 1.0;
    rotateY = 0.0;
    rotateX = 0.0;
    rotateMatrix = GLKMatrix4Identity;
    
    isDragging = NO;
    tapTime =  nil;
    velocity = GLKVector2Make(0.0, 0.0);
}

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        [self initParameter];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        [self initParameter];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self initParameter];
    }
    return self;
}

- (void)addGesture {
    //add pin gesture as zoom
    UIPinchGestureRecognizer* zoomGesture = [[UIPinchGestureRecognizer alloc]
                                             initWithTarget:self
                                             action:@selector(zoomView:)];
    [self.view addGestureRecognizer:zoomGesture];
  
    //add pan gesture as rotate
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(rotateView:)];
    panGesture.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer* doubletapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
    [doubletapGestureRecognizer setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:doubletapGestureRecognizer];
}

- (void)setUpTexture{
    CGImageRef imageRef =
    [[UIImage imageNamed:@"photo wall.png"] CGImage];
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader
                                   textureWithCGImage:imageRef
                                   options:nil
                                   error:NULL];
    
    self.effect.texture2d0.name = textureInfo.name;
    self.effect.texture2d0.target = textureInfo.target;
}

- (void) initData{
    planeManager = [[PlaneManager alloc] initWithRowCount:MAX_ROW ColumnCount:MAX_COL];
    
    sizeofVertices = planeManager.sizeofVertices;
    sizeofIndices = planeManager.sizeofIndices;
    sizeofTextureCoordinates = planeManager.sizeofTextureCoordinates;
    sizeofColors = planeManager.sizeofColors;
    
    indices = [planeManager managerIndices];
    vertices = [planeManager managerVertices];
    textureCoordinates = [planeManager managerTextureCoordinates];
    colors = [planeManager managerColors];
}

- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    [self setUpTexture];
    
    [self setUpProjectionMatrix];
    [self setUpModelViewMatrix];
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofVertices, vertices, GL_DYNAMIC_DRAW);
    
    glGenBuffers(1, &textureCoordinateBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, textureCoordinateBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofTextureCoordinates, textureCoordinates, GL_STATIC_DRAW);
    
    glGenBuffers(1, &indicesBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeofIndices, indices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &colorBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofColors, colors, GL_STATIC_DRAW);
    
    glEnable(GL_DEPTH_TEST);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    [self initData];
    [self setupGL];
    [self addGesture];
    [self setUpUI];
}

- (void)setUpUI{
    if (planeManager) {
        [planeManager initEaseFunction];
    }
    
    if (!easeFunctionCollection) {
        easeFunctionCollection = [[NSArray alloc] initWithObjects:Linear,Bounce,Expo,Elastic, nil];
    }
    
    pickView.dataSource = self;
    pickView.delegate = self;
    
    selectAnimationSlider.maximumValue = MAX_SELECT_ANIMATION_TIME;
    selectAnimationSlider.minimumValue = MIN_SELECT_ANIMATION_TIME;
    selectAnimationSlider.value = DEFAULT_ANIMATION_TIME;
    
    [self setSelectAnimationTimeLabel];
}

- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteBuffers(1, &textureCoordinateBuffer);
    glDeleteBuffers(1, &indicesBuffer);
    glDeleteBuffers(1, &colorBuffer);

    
    self.effect = nil;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

#pragma mark - HandleGesture

- (void)zoomView:(UIPinchGestureRecognizer *)recognizer
{
    scaleFactor = recognizer.scale;
    if (recognizer.scale < MinScaleFactor) {
        scaleFactor = MinScaleFactor;
    }
    if (recognizer.scale  > MaxScaleFactor) {
        scaleFactor = MaxScaleFactor;
    }
    
    [self setUpModelViewMatrix];
}

- (void)computeRotateMatrix:(CGPoint) point
{
    GLfloat moveX = point.x - rotateX;
    GLfloat moveY = point.y - rotateY;
    GLKVector3 axis = GLKVector3Make(moveX, moveY, 0);
    //normal towards camera
    GLKVector3 normal = GLKVector3Make(0, 0, -1);
    GLKVector3 rotateAxis = GLKVector3Normalize(GLKVector3CrossProduct(normal, axis));
    GLfloat radius = RotateFactor * GLKVector2Length(GLKVector2Make(moveX, moveY));
    
    if (radius) {
        rotateMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(radius, rotateAxis.x, -rotateAxis.y, rotateAxis.z), rotateMatrix);
    }
    [self setUpModelViewMatrix];
}

- (void)rotateView:(UIPanGestureRecognizer *)recongnizer
{
    if ([self isAnimation]) {
        return;
    }
    
    CGPoint point = [recongnizer translationInView:self.view];
    [self computeRotateMatrix:point];
    rotateX = point.x;
    rotateY = point.y;
    if (recongnizer.state == UIGestureRecognizerStateBegan) {
        isDragging = YES;
    }else if (recongnizer.state == UIGestureRecognizerStateEnded) {
        rotateX = 0;
        rotateY = 0;
        isDragging = NO;
        CGPoint velocityPoint = [recongnizer velocityInView:self.view];
        velocity.x = velocityPoint.x * VelocityFactor;
        velocity.y = velocityPoint.y * VelocityFactor;
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    if ([self switchShapeAnimation]) {
        return;
    }
    
    CGPoint p = [recognizer locationInView:self.view];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    
    // Position
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    //Texture
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    // color
    glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    
    // Indices
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    glDrawElements(GL_TRIANGLES, (GLsizei)(NUM_OF_INDICES * MAX_ROW * MAX_COL), GL_UNSIGNED_SHORT, NULL);
    
    Byte pixelColor[4] = {0,};
    CGFloat scale = UIScreen.mainScreen.scale;
    glReadPixels(p.x * scale, (self.view.bounds.size.height - p.y) * scale, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixelColor);
//    NSLog(@"%d %d %d %d", pixelColor[0], pixelColor[1], pixelColor[2], pixelColor[3]);
    
    GLKVector4 falseColor = GLKVector4Make(pixelColor[0] / 255.0, pixelColor[1] / 255.0, pixelColor[2] / 255.0, pixelColor[3] / 255.0);
    [planeManager updateSelectedPlaneWithFalseColor:falseColor];
   
    [self updateVertex];
}

- (void)updateVertex{
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofVertices, vertices, GL_DYNAMIC_DRAW);
}

- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)recognizer{
    if ([self selectPlaneAnimation]) {
        return;
    }
    
    if (planeManager) {
        tapTime = [NSDate date];
        
        planeManager.shouldDrawPlane = !planeManager.shouldDrawPlane;
        [planeManager updatePlanesForSwitchShapeAnimation];
    }
}

#pragma mark - GLKViewDelegate

- (void)setUpProjectionMatrix{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0f), aspect, 1.0f, 20.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    
    // Position
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    // Texture
    glBindBuffer(GL_ARRAY_BUFFER, textureCoordinateBuffer);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    
    // color
    glDisableVertexAttribArray(GLKVertexAttribColor);
    
    // Indices
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    glDrawElements(GL_TRIANGLES, (GLsizei)(NUM_OF_INDICES * MAX_ROW * MAX_COL), GL_UNSIGNED_SHORT, NULL);
}

#pragma mark - GLKViewControllerDelegate

- (void)setUpModelViewMatrix{
    //tanslate
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -STARTING_Z);
    
    //rotate
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotateMatrix);
    
    //scale
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scaleFactor, scaleFactor, scaleFactor);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
}

- (void)update{
    if ([self switchShapeAnimation]) {
        NSTimeInterval diff = -[tapTime timeIntervalSinceNow];
        float ratio = (diff * 1000.0f) / SWITCH_SHAPE_DURATION;
        if (ratio > 1) {
            planeManager.shapeSwitchAnimation = NO;
            ratio = 1;
        }
        
        [planeManager updatePlanesAnimationPostion:ratio];
        [self updateVertex];
    }
    
    if ([self selectPlaneAnimation]) {
        [planeManager updateSelectPlanesAnimation];
        [self updateVertex];
    }
    
    float velocitySize = GLKVector2Length(velocity);
    
    if (!isDragging && velocitySize > 0.0001) {
        CGPoint velocityPoint = CGPointMake(velocity.x, velocity.y);
        [self computeRotateMatrix:velocityPoint];
        
        velocity.x *= Sensitivity;
        velocity.y *= Sensitivity;
    }
    
    if ([self isAnimation]) {
        pickView.userInteractionEnabled = NO;
        selectAnimationSlider.userInteractionEnabled = NO;
    }else{
        pickView.userInteractionEnabled = YES;
        selectAnimationSlider.userInteractionEnabled = YES;
    }
}

#pragma mark - check state

- (BOOL)switchShapeAnimation{
    if (!planeManager) {
        return NO;
    }
    return planeManager.shapeSwitchAnimation;
}

- (BOOL)selectPlaneAnimation{
    if (!planeManager) {
        return NO;
    }
    return planeManager.selectPlaneAnimation;
}

- (BOOL)isAnimation{
    return [self switchShapeAnimation] || [self selectPlaneAnimation];
}

#pragma mark - UIPickerViewDelegate

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = [easeFunctionCollection objectAtIndex:row];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}];
    
    return attString;
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSString* selectedText = [easeFunctionCollection objectAtIndex:row];
    planeManager.easeFunction.tag = selectedText;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [easeFunctionCollection count];
}

#pragma mark - Other UI
- (IBAction)selectAnimationTimeChange:(id)sender {
    UISlider* control = (UISlider*)sender;
    if(control == selectAnimationSlider){
        [self setSelectAnimationTimeLabel];
    }
}

- (void)setSelectAnimationTimeLabel{
    float value = selectAnimationSlider.value;
    selectAnimationTime.text = [NSString stringWithFormat:@"%d",(int)value];
    planeManager.easeFunction.totalTime = (int)value;
}

@end
