attribute vec3 aPosition;
/*
uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;
*/
void main(void)
{
	gl_Position =/* uPMatrix * uMVMatrix*/ gl_ModelViewProjectionMatrix * vec4(aPosition, 1.0);
}
