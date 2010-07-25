#version 110

attribute vec3			aPosition;
attribute vec3			aNormal;

varying vec3			vNormal;


void main(void)
{
	vNormal = normalize(gl_NormalMatrix * aNormal);
	gl_Position = gl_ModelViewProjectionMatrix * vec4(aPosition, 1.0);
}
