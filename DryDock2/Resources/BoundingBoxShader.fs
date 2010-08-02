#version 110


void main(void)
{
	gl_FragColor = vec4(0.7, 0.7, 0.7, 1.0);
	gl_FragDepth = gl_FragCoord.z * (1.0 - 1e-5);	// Offset slightly toward camera to avoid Z-fighting.
}
