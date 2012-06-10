/* pmd/zplot.vsh */
uniform mat4 modelViewProjectionMatrix;
attribute vec3 inPosition;
const float kOne = 1.0;

void main() {
    vec4 position = modelViewProjectionMatrix * vec4(inPosition, kOne);
    gl_Position = position;
}

