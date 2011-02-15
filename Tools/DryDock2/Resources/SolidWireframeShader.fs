#version 110

uniform vec4			uColor;


void main(void)
{
	gl_FragColor = uColor;
	gl_FragDepth = gl_FragCoord.z * (1.0 - 1e-5);	// Offset slightly toward camera to avoid Z-fighting.
}
