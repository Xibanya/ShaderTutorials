//Adapted from https://unitycoder.com/blog/2015/12/21/matrix-playground-shader/
// Matrix PlayGround Shader - UnityCoder.com
// References:
// Matrices http://www.codinglabs.net/article_world_view_projection_matrix.aspx
// Rotation: http://www.gamedev.net/topic/610115-solved-rotation-deforming-mesh-opengl-es-20/#entry4859756
#ifndef MATRIX_TRANSFORM_LIBRARY_INCLUDED
#define MATRIX_TRANSFORM_LIBRARY_INCLUDED

float4x4 TranslateMatrix(float3 t)
{
	return float4x4(1, 0, 0, t.x,
		0, 1, 0, t.y,
		0, 0, 1, t.z,
		0, 0, 0, 1);
}
float4x4 ScaleMatrix(float3 scale)
{
	return float4x4(scale.x, 0, 0, 0,
		0, scale.y, 0, 0,
		0, 0, scale.z, 0,
		0, 0, 0, 1);
}
float4x4 YRotationMatrix(float degrees)
{
	float angleY = radians(degrees);
	float c = cos(angleY);
	float s = sin(angleY);
	float4x4 rotateYMatrix = float4x4(c, 0, s, 0,
		0, 1, 0, 0,
		-s, 0, c, 0,
		0, 0, 0, 1);
	return rotateYMatrix;
}
float4x4 XRotationMatrix(float degrees)
{
	float angleX = radians(degrees);
	float c = cos(angleX);
	float s = sin(angleX);
	float4x4 rotateXMatrix = float4x4(1, 0, 0, 0,
		0, c, -s, 0,
		0, s, c, 0,
		0, 0, 0, 1);
	return rotateXMatrix;
}
float4x4 ZRotationMatrix(float degrees)
{
	float angleZ = radians(degrees);
	float c = cos(angleZ);
	float s = sin(angleZ);
	float4x4 rotateZMatrix = float4x4(c, -s, 0, 0,
		s, c, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1);
	return rotateZMatrix;
}
void DoRotate(inout float4 o, float3 rotateAmount)
{
	float4 localScaledTranslatedRotX = mul(o, XRotationMatrix(rotateAmount.x));
	float4 localScaledTranslatedRotXY = mul(localScaledTranslatedRotX, YRotationMatrix(rotateAmount.y));
	o = mul(localScaledTranslatedRotXY, ZRotationMatrix(rotateAmount.z));
}
void DoTransform(inout float4 o, float3 translateAmount, float3 scaleAmount, float3 rotateAmount)
{
	float4 localTranslated = mul(TranslateMatrix(translateAmount), o);
	float4 localScaledTranslated = mul(localTranslated, ScaleMatrix(scaleAmount));
	float4 localScaledTranslatedRotX = mul(localScaledTranslated, XRotationMatrix(rotateAmount.x));
	float4 localScaledTranslatedRotXY = mul(localScaledTranslatedRotX, YRotationMatrix(rotateAmount.y));
	o = mul(localScaledTranslatedRotXY, ZRotationMatrix(rotateAmount.z));
}
#endif