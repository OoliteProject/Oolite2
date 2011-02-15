#version 110

varying vec4			vPosition;
varying vec3			vLightVector;
varying vec4			vEyeVector;
varying vec3			vNormal;

const vec4				kAmbient = vec4(0.1, 0.1, 0.1, 1.0);
const vec4				kMainLight = vec4(0.8, 0.8, 0.78, 1.0);
const vec4				kFillLight = vec4(0.0, 0.0, 0.15, 1.0);


void main(void)
{
	vec3 eyeVector = normalize(-vPosition).xyz;
	vec3 lightVector = normalize(vLightVector);
	vec3 normal = normalize(vNormal);
	
	vec4 totalColor = kAmbient;
	
	// Lambertian diffuse light, plus fill light from opposite direction.
	float intensity = dot(normal, lightVector);
	totalColor += max(intensity, 0.0) * kMainLight;
	totalColor += max(-intensity, 0.0) * kFillLight;
	
	totalColor.a = 1.0;
	gl_FragColor = totalColor;
}
