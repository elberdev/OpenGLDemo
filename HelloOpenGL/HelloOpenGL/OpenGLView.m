//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by Elber Carneiro on 8/24/15.
//  Copyright (c) 2015 Elber Carneiro. All rights reserved.
//

// Tutorial is at: http://www.raywenderlich.com/3664/opengl-tutorial-for-ios-opengl-es-2-0#comments

#import "OpenGLView.h"
#import "CC3GLMatrix.h"

// Define the struct to hold our position and color info
typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

// CUBE VERTICES
const Vertex Vertices[] = {
    {{1, -1, 0}, {0, 76.0/255.0, 76.0/255.0, 1}},
    {{1, 1, 0}, {0, 76.0/255.0, 76.0/255.0, 1}},
    {{-1, 1, 0}, {74.0/255.0, 195.0/255.0, 247.0/255.0, 1}},
    {{-1, -1, 0}, {74.0/255.0, 195.0/255.0, 247.0/255.0, 1}},
    {{1, -1, -1}, {0, 76.0/255.0, 76.0/255.0, 1}},
    {{1, 1, -1}, {0, 76.0/255.0, 76.0/255.0, 1}},
    {{-1, 1, -1}, {74.0/255.0, 195.0/255.0, 247.0/255.0, 1}},
    {{-1, -1, -1}, {74.0/255.0, 195.0/255.0, 247.0/255.0, 1}}
};

// CUBE INDICES
const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 7, 6,
    // Left
    2, 7, 3,
    7, 6, 2,
    // Right
    0, 4, 1,
    4, 1, 5,
    // Top
    6, 2, 1,
    1, 6, 5,
    // Bottom
    0, 3, 7,
    0, 7, 4
};

//// SQUARE VERTICES
//// Instantiate our struct as a constant
//const Vertex Vertices[] = {
//    {{1, -1, 0}, {1, 0, 0, 1}},
//    {{1, 1, 0}, {0, 1, 0, 1}},
//    {{-1, 1, 0}, {0, 0, 1, 1}},
//    {{-1, -1, 0}, {0, 0, 0, 1}}
//};

//// SQUARE INDICES
//// Tells OpenGL what triangles to create. OpenGL thinks in triangles...
//const GLubyte Indices[] = {
//    0, 1, 2,
//    2, 3, 0
//};

@implementation OpenGLView

+ (Class)layerClass {
    // For the view to display OpenGL content we need to set its layer's class to
    // an OpenGL-type layer.
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    // Initialize the layer and make sure we set it to opaque for performance
    // reasons. Default is transparent.
    _eaglLayer = (CAEAGLLayer *) self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    // To do anything in OpenGL you first need to setup a context.
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context.");
        exit(1);
    }
    
    // Set current context to the context we just created.
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context.");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    // Creates a new render buffer object.
    glGenRenderbuffers(1, &_colorRenderBuffer);
    // Whenever I refer to GL_RENDERBUFFER I reallu mean _colorRenderBuffer.
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    // Allocate some storage for the render buffer using a method from the context.
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupDepthBuffer {
    // Creates new depth buffer. This will make it so OpenGL does not render vertices which
    // are behind other vertices, it will make your object look opaque rather than transparent.
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

- (void)setupFrameBuffer {
    // The frame buffer contains the render buffer and other necessary buffers.
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    // Here we attach our previously-created color and depth render buffers to our
    // frame buffer's appropriate slots.
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

// This method is necessary to compile our shaders at runtime. We compile at runtime
// because OpenGL is supposed to be platform independent, not to run on any
// specific architecture.
- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    
    /* I: Get an NSString with the contents of the shader file. */
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    /* II: Create the shader object of the appropriate type passed in as a parameter. */
    GLuint shaderHandle = glCreateShader(shaderType);
    
    /* III: Connect the new shader object to our shader source code, converting the
    NSString to a C string first. */
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int) [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    /* IV: Now that our shader has the source code to go with it, we compile the shader
    at runtime with this function. */
    glCompileShader(shaderHandle);
    
    /* V: If our shader compilation fails we want to make sure that we log a useful
    message and quit the program. */
    GLint compileSuccess;
    // This method gets the compile status parameter from our shader object and
    // assigns it to compileSuccess.
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    // If we did not get a successful compilation we get our shader log and print
    // its messages as an error, then exit the program.
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    /* VI: If everything went well, we return our compiled shader object */
    return shaderHandle;
    
}

// This method will link our fragment and vertex shaders together and finish any
// remaining setup that OpenGL needs to have in order to render our object properly.
- (void)compileShaders {
    
    // Instantiate our shaders.
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    // Instantiate our program.
    GLuint programHandle = glCreateProgram();
    // Attach our shaders to our program.
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    // Links our shaders into a complete program.
    glLinkProgram(programHandle);
    
    // Checks to make sure our link was successful, if not: print error message and
    // exit program
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // If linking was successful, tell OpenGL to use our program when given
    // vertex info.
    glUseProgram(programHandle);
    
    // Get pointers to our vertex shader attributes so we can set them in code.
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    // Enable use of those attribute arrays (which are disabled by default).
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    // Get pointer to our Projection and Modelview attributes.
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
}

// We pass the vertex info to OpenGL in the form of Vertex Buffer Object.
// One to keep track of per-vertex data, the other to keep track of which
// indices make up triangles.
- (void)setupVBOs {
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

- (void)render:(CADisplayLink *)displayLink {
    // Pick a color to display on the screen.
    glClearColor(206.0/255.0, 229.0/255.0, 237.0/255.0, 1.0);

    // Clear the current render / color buffer.
    
//// This is how it would look without the depth buffer.
//    glClear(GL_COLOR_BUFFER_BIT);
    
    // This is what it looks like with the depth buffer included.
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    // Create our projection matrix, with left/right, top/bottom, and near/far coordinates
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    // Pass our newly created matrix into the Projection attribute.
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    // The sine of the current time will give a value between -1 and 1. If we call render every frame,
    // it will cycle between those two values every pi seconds. The -7 sets the square a bit farther
    // back from the near plane, so it does not take up the whole screen.
    // The formula is (x, y, z) for the transform.
    [modelView populateFromTranslation:CC3VectorMake(sin(CACurrentMediaTime()), 0, -7)];
    // Increments rotation 90 degrees every second.
    _currentRotation += displayLink.duration * 180;
    // We add the rotation to the matrix along the x and y axes.
    [modelView rotateBy:CC3VectorMake(0, _currentRotation, _currentRotation)];
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    // Sets the portion of the view to use for rendering.
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    /* Feeds the correct values to the two input variables, onr for position, the other for color.
    parameter formula : 
        
        (attributeName, howManyValuesForEachVertex, typeOfEachValue, alwaysFalse, sizeOfTheDataStructure, offsetToBeginningOfData)
     
    The position info is in the beginning so offset is 0.
    The color info is farther in, 3 times size of a float past the beginning. */
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *) (sizeof(float) * 3));
    
    /* This is the method that calls the vertex shader and the fragment shader to do the drawing.
     formula:
     (methodOfDrawing, numberOfVerticesToRender, dataTypeOfEachIndexInTheIndicesArray, usesTheArrayWePassedWithVBOs)
    */
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    // Present our own render / color buffer.
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setupDisplayLink {
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setupVBOs];
        [self setupDisplayLink];
    }
    return self;
}

@end
