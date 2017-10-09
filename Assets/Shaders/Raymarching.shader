Shader "Raymarching/Raymarching"
{
	Properties
	{
		_Diffuse("Diffuse (RGB) Occlusion (A)", COLOR) = (0.5, 0.5, 0.5, 1)
		_Specular("Specular (RGB) Smoothness (A)", COLOR) = (0.5, 0.5, 0.5, 1)
		_Emission("Emission (RGB) NoUse(A)",COLOR) = (0.5 ,0.5 ,0.5 ,1)

		_Position("Position (XYZ) Axis (W) no use", Vector) = (0, 0, 0, 0)
		_Rotation("Rotate (XYZ) Axis (W) no use", Vector) = (0, 0, 0, 0)
		_Scale("Scale (XYZ) Axis (W) no use", Vector) = (1, 1, 1, 0)

		//_ObjectSpaceRaymarch("Object Space Raymarch", Float) = 0
	}

	CGINCLUDE
#include "Libs/RaymarchingPreDefine.cginc"

	float4 _Position;
	float4 _Rotation;
	float4 _Scale;

	float4 _Diffuse;
	float4 _Specular;
	float4 _Emission;

	float CustomDistanceFunction(float3 pos) 
	{
		const float repeatSize = 5;
		const float gridSize = 5;
		const float rotSpeed = _Time.y * 5.5;
		const float smoothPower = 20;

		float3 pq = floor(pos / gridSize);
		float3 axis = normalize(hash(pq));
		pq.x += _Time.y * 1;
		float h = noise(pq);

		pos = repeat(pos, float3(repeatSize, repeatSize, repeatSize));
		//pos = twistY(pos, sin(_Time.y));
		float3 posY = rotateY(pos, rotSpeed);
		float3 posX = rotateY(rotateX(pos, PI * 0.5), rotSpeed);
		float3 posZ = rotateY(rotateX(rotateY(pos, PI * 0.5), PI * 0.5), rotSpeed);
		//pos = rotate(pos, cos(_Time.y * 1.5), axis);

		//float2 hexParams = float2(0.5, 0.5 + h * 2.5);
		float2 hexParams = float2(0.5, 0.5 + h*2.0);

		float hexY = hexagonalPrismY(posY, hexParams);
		float hexX = hexagonalPrismY(posX, hexParams);
		float hexZ = hexagonalPrismY(posZ, hexParams);

		return smoothMin(smoothMin(hexY, hexZ, smoothPower), hexX, smoothPower);

	}

	gbuffer CustomGBufferOutPut(float3 normal, float depth, raymarchOut rayOut)
	{
		half4 col = half4(normal * 0.5 + 0.5, 1);
		float fog = min(1.0, (1.0 / 100)) * float(rayOut.count) * 1.5;
		return InitGBuffer(col, _Specular, normal, _Emission * fog, depth);
	}

#define CUSTOM_DISTANCE_FUNCTION(p) CustomDistanceFunction(p)
#define CUSTOM_GBUFFER_OUTPUT(diff, spec, norm, emit, dep) CustomGBufferOutPut(normal, depth, rayOut)
#define CUSTOM_TRANSFORM(p, r, s) InitTransform(_Position, _Rotation, _Scale)


#include "Libs/Raymarching.cginc"
	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Off
		Stencil
		{
			Comp Always
			Pass Replace
			Ref 128
		}
		Pass
		{
			Tags{ "LightMode" = "Deferred" }
			CGPROGRAM
			#pragma vertex raymarch_vert
			#pragma fragment raymarch_frag
			#pragma target 3.0			
			ENDCG
		}
	}
}
