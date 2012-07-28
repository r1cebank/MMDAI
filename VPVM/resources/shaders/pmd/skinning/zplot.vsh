/* pmd/zplot.vsh */
invariant gl_Position;
uniform mat4 modelViewProjectionMatrix;
attribute vec3 inPosition;
const float kOne = 1.0;

attribute vec3 inBoneIndicesAndWeights;
const int kMaxBones = 128;
uniform mat4 boneMatrices[kMaxBones];

vec4 performLinearBlendSkinning(const vec4 position) {
    mat4 matrix1 = boneMatrices[int(inBoneIndicesAndWeights.x)];
    mat4 matrix2 = boneMatrices[int(inBoneIndicesAndWeights.y)];
    float weight = inBoneIndicesAndWeights.z;
    vec4 p1 = matrix2 * position;
    vec4 p2 = matrix1 * position;
    return p1 + (p2 - p1) * weight;
}

void main() {
    vec4 position = performLinearBlendSkinning(vec4(inPosition, kOne));
    gl_Position = modelViewProjectionMatrix * position;
}
