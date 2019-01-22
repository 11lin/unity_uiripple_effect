// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "CloudShadow/UIMaskNoise"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0

		_Refraction("Refraction", float) = 1.0        //折射值
		_DistortionMap("Distortion Map", 2D) = "" {}    //扭曲
		_DistortionScrollX("X Offset", float) = 0
		_DistortionScrollY("Y Offset", float) = 0
		_DistortionScaleX("X Scale", float) = 1.0
		_DistortionScaleY("Y Scale", float) = 1.0


		_DistortionPower("Distortion Power", float) = 0.08

		_MaskTex("_MaskTex", 2D) = "" {}
	}

		SubShader
		{
			Tags
			{
				"Queue" = "Transparent"
				"IgnoreProjector" = "True"
				"RenderType" = "Transparent"
				"PreviewType" = "Plane"
				"CanUseSpriteAtlas" = "True"
			}

			Stencil
			{
				Ref[_Stencil]
				Comp[_StencilComp]
				Pass[_StencilOp]
				ReadMask[_StencilReadMask]
				WriteMask[_StencilWriteMask]
			}

			Cull Off
			Lighting Off
			ZWrite Off
			ZTest[unity_GUIZTestMode]
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask[_ColorMask]

			Pass
			{
				Name "Default"
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 2.0

				#include "UnityCG.cginc"
				#include "UnityUI.cginc"

				#pragma multi_compile __ UNITY_UI_ALPHACLIP

				struct appdata_t
				{
					float4 vertex   : POSITION;
					float4 color    : COLOR;
					float2 texcoord : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					float4 vertex   : SV_POSITION;
					fixed4 color : COLOR;
					float2 texcoord  : TEXCOORD0;
					float4 worldPosition : TEXCOORD1;
					UNITY_VERTEX_OUTPUT_STEREO
				};

				fixed4 _Color;
				fixed4 _TextureSampleAdd;
				float4 _ClipRect;

				uniform sampler2D _DistortionMap;
				uniform sampler2D _MaskTex;
				uniform float _BackgroundScrollX;
				uniform float _BackgroundScrollY;
				uniform float _DistortionScrollX;
				uniform float _DistortionScrollY;
				uniform float _DistortionScaleX;
				uniform float _DistortionScaleY;

				uniform float _DistortionPower;

				uniform float _Refraction;

				v2f vert(appdata_t IN)
				{
					v2f OUT;
					UNITY_SETUP_INSTANCE_ID(IN);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
					OUT.worldPosition = IN.vertex;
					OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

					OUT.texcoord = IN.texcoord;

					OUT.color = IN.color * _Color;
					return OUT;
				}

				sampler2D _MainTex;

				fixed4 frag(v2f IN) : SV_Target
				{
					float2 disScale = float2(_DistortionScaleX,_DistortionScaleY);

					float2 disOffset = float2(_DistortionScrollX,_DistortionScrollY);
					float4 mask = tex2D(_MaskTex, IN.texcoord);
					float2 timer = float2(_Time.x, _Time.x);
					float4 disTex = tex2D(_DistortionMap, disScale * IN.texcoord + disOffset * timer);

					float2 offsetUV = (-_Refraction * (disTex * _DistortionPower - (_DistortionPower*0.5)));

					//return tex2D(_Background, i.uv + offsetUV * (1 - mask.r));

					half4 color = (tex2D(_MainTex, IN.texcoord + offsetUV * (1 - mask.r)) + _TextureSampleAdd) * IN.color;

					color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);

					#ifdef UNITY_UI_ALPHACLIP
					clip(color.a - 0.001);
					#endif

					

					

					return color;
				}
			ENDCG
			}
		}
}
