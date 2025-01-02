Shader "HDA/Hologram" {
    
    Properties
    {
        _riffleTexture ("rifflesTxt", 2D) = "white" {}
        _riffleTextureBig ("rifflesBigTxt", 2D) = "white" {}
        _mainColor("Color", Color) = (.2, .2, 1.0, .5)
        _Speckolor("specColor", color) = (1,1,1,1)
        _Shiny("Shininess", float) = 23
        _maxAlpha ("maxAlphaVal", Float) = 0.85
        _emissionIntensity ("Emission Intensity", Float) = 1
        _fresnelAngle ("Fresnel Angle", Float) = 0.12
        _fresnelIntensity ("Fresnel Intensity", Float) = 1
        _interferenceAmplitude ("InterferenceAmp", Float) = 0
        _interferenceFreq ("InterferenceFreq", Float) = 10
    }
    
SubShader 
{
    Tags 
    { 
        "RenderType" = "Transparent"
        "Queue" = "Transparent"
    }
    
	
    Pass
    {
        ColorMask 0 //Object doesnt blend itself (unwanted overlapping effects) 
        
        HLSLPROGRAM
        
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        uniform float _interferenceAmplitude;
        uniform float _interferenceFreq;
        
        struct vertexInput
        {
            float4 vertexPos : POSITION;
        };

        struct vertexOutput
        {
            float4 pos : SV_POSITION;
        };

        vertexOutput vert (vertexInput input)
        {
            vertexOutput output;
            
            float4 posAfterInterference = input.vertexPos + _interferenceAmplitude * float4(sin(input.vertexPos.y * _interferenceFreq * UNITY_TWO_PI) * .1,0,0,0);
            output.pos = UnityObjectToClipPos(posAfterInterference);
            return output;
        }

        float4 frag (vertexOutput input) : COLOR
        {
            float4 output;            
            return output;
        }
        
        ENDHLSL
    }
    
    Pass
    {
        
        Tags 
        { 
            "LightMode" = "ForwardBase"
            "ForceNoShadowCasting" = "True" 
        }
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        
        HLSLPROGRAM

        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        uniform float4 _LightColor0;
        uniform float4 _mainColor;
        uniform float4 _Speckolor;
        uniform float _Shiny;
        uniform sampler2D _riffleTexture;
        uniform float4 _riffleTexture_ST;
        uniform float _maxAlpha;
        uniform float _emissionIntensity;
        uniform float _interferenceAmplitude;
        uniform float _interferenceFreq;
        
        struct vertexInput
        {
            float4 vertexPos : POSITION;
            float3 normal : NORMAL;
        };

        struct vertexOutput
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
            float4 col : COLOR;
        };

        vertexOutput vert (vertexInput input)
        {
            vertexOutput output;

            float3 normalDir = input.normal;
            float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
            float3 viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, input.vertexPos));

            float attenuation;
        
            if (0.0 == _WorldSpaceLightPos0.w) //is directlional?
            {
                attenuation = 1;
                lightDir = normalize(_WorldSpaceLightPos0.xyz);
            }
            else //point or spot?
            {
                float3 vtl = _WorldSpaceLightPos0.xyz -
                    mul(unity_ObjectToWorld, input.vertexPos);
         
                float dist = length(vtl);
                attenuation = 1 / dist; //linear attenuation
                lightDir = normalize(vtl);
            }
            float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _mainColor.rgb;
         
            float3 diffRefl = attenuation * _LightColor0.rgb * _mainColor.rgb
                * max(0.0, dot(normalDir, lightDir));
     
            float3 specRefl;
         
            if (dot(normalDir, lightDir) < 0) //wrong side?
            {
                specRefl.xyz = 0; //no Spec
            }
            else
            {
                specRefl = attenuation * _LightColor0.rgb
                    * _Speckolor.rgb *
                    pow(max(0, dot(reflect(-lightDir, normalDir), viewDir)), _Shiny);
            }
     
            output.col = float4(ambient + diffRefl + specRefl, 1.0);
            float4 posAfterInterference = input.vertexPos + _interferenceAmplitude * float4(sin(input.vertexPos.y * _interferenceFreq * UNITY_TWO_PI) * .1,0,0,0);
            output.pos = UnityObjectToClipPos(posAfterInterference);
            output.uv = input.vertexPos.xy;
            return output;
        }

        float4 frag (vertexOutput input) : COLOR
        {
            float4 output;
            output.xyz = input.col * _emissionIntensity;
            output.a = min(_mainColor.w + tex2D(_riffleTexture, input.uv * _riffleTexture_ST.xy + _riffleTexture_ST.zw).x, _maxAlpha);
            
            return output;
        }
        
        ENDHLSL
    }
    

    //fresnel and big riffles
    Pass
    {
        Blend SrcAlpha OneMinusSrcAlpha
        
        HLSLPROGRAM
        
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        uniform sampler2D _riffleTextureBig;
        uniform float4 _riffleTextureBig_ST;
        uniform float _fresnelAngle;
        uniform float _fresnelIntensity;
        uniform float _interferenceAmplitude;
        uniform float _interferenceFreq;
        
        struct vertexInput
        {
            float4 vertexPos : POSITION;
            float3 normal : NORMAL;
        };

        struct vertexOutput
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD5;
            float3 normal : TEXCOORD3;
            float3 viewDir : TEXCOORD4;
        };

        vertexOutput vert (vertexInput input)
        {
            vertexOutput output;

            float4 posAfterInterference = input.vertexPos + _interferenceAmplitude * float4(sin(input.vertexPos.y * _interferenceFreq * UNITY_TWO_PI) * .1,0,0,0);
            output.pos = UnityObjectToClipPos(posAfterInterference);
            output.normal = normalize(mul(float4(input.normal,0), unity_WorldToObject).xyz);
            output.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, input.vertexPos).xyz);
            output.uv = input.vertexPos.xy;
            
            return output;
        }

        fixed4 frag (vertexOutput input) : COLOR
        {
            fixed newOpacity =
                clamp((1 - abs(dot(input.viewDir, input.normal) + _fresnelAngle)) * _fresnelIntensity
                    + tex2D(_riffleTextureBig, input.uv * _riffleTextureBig_ST.xy + _riffleTextureBig_ST.zw).x, 0, 1);
            fixed4 output = fixed4(1,1,1,newOpacity);
            return output;
        }

        ENDHLSL
    }

    
}
Fallback "Unlit/Color"
}
