attribute vec4 av_Position;//顶点坐标
attribute vec2 af_Position;//纹理坐标
varying vec2 v_texPo;//用于把纹理坐标传到fragment
uniform mat4 u_Matrix;
uniform mat4 u_FlipMatrix;
void main(){
    gl_Position = av_Position * u_Matrix * u_FlipMatrix;
    v_texPo = af_Position;
}