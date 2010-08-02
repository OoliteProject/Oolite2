#version 110

varying vec3			vNormal;

uniform vec4			uColor;

const float				kLightFactor = 0.15;
const float				kAmbientFactor = 1.0 - kLightFactor;


void main(void)
{
	// Darken back-facing wires - like diffuse lighting, but with no clamping to 0.
	float intensity = kLightFactor * normalize(vNormal).z + kAmbientFactor;
	
	gl_FragColor = uColor * intensity;
	gl_FragDepth = gl_FragCoord.z * (1.0 - 1e-5);	// Offset slightly toward camera to avoid Z-fighting.
}
