/* This file is written in GLSL. We are creating our simple Vertex shader here. */

// Declare a variable of name Position and type vec4 (a vector with 4 components)
attribute vec4 Position;
// Declare a vec4 variable named SourceColor
attribute vec4 SourceColor;

// The lack of the attribute keyword means this is an output variable that will be
// passed to our fragment shader. The varying keyword means it will have to figure
// out the values for any given 'pixel' by extrapolating from the vertices nearby.
// As you can imagine this will create gradients between vertices if the vertices
// are different colors.
varying vec4 DestinationColor;

// This new attribute is uniform, meaning it will be the same value for all vertices.
// mat4 type is a 4 x 4 matrix.
uniform mat4 Projection;

// This will be our transform/scale/rotation matrix.
uniform mat4 Modelview;

// Shader begins with a main function
void main(void) {
    
    // Set destination color to be the same as the source color so OpenGL can
    // interpolate the values from source color.
    DestinationColor = SourceColor;
    
    // gl_Position is a built-in variable that we have to set to the final position
    // of the vertex. We set it to this value to apply a matrix transform (give 3d look).
    gl_Position = Projection * Modelview * Position;
    
    // Now we need to make sure we use some fancy linear algebra (which is what all the CC
    // imported files are.
}