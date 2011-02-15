#version 110

attribute vec3			aPosition;


void main(void)
{
	gl_Position = gl_ModelViewProjectionMatrix * vec4(aPosition, 1.0);
}
