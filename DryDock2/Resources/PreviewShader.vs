#version 110

attribute vec3			aPosition;
attribute vec3			aNormal;
//uniform vec3			uLightPosition;

varying vec4			vPosition;
varying vec3			vLightVector;
varying vec4			vEyeVector;
varying vec3			vNormal;


void main(void)
{
	vec4 position = vec4(aPosition, 1.0);
	vec4 uLightPosition = gl_LightSource[0].position;
	
	vNormal = normalize(gl_NormalMatrix * aNormal);
	vEyeVector = gl_ModelViewMatrix * position;
//	vLightVector = (uLightPosition + vEyeVector).xyz;
	vLightVector = uLightPosition.xyz;
	
	gl_Position = vPosition = gl_ModelViewProjectionMatrix * position;
}
