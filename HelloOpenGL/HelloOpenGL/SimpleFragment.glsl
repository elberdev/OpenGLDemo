/* Our simple fragment shader */

// This is the color variable we get from our vertex shader. When you declare variables
// in a fragment shader, unlike in a vertex shader, you need to specify PRECISION.
// lowp is low precision. Try using the lowest precision you can get away with for
// performance reasons.
varying lowp vec4 DestinationColor;

void main(void) {
    
    // Just like you need to set gl_Position in the vertex shader, you need to set
    // gl_FragColor in a fragment shader.
    gl_FragColor = DestinationColor;
}