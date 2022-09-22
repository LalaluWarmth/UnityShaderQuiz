using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

[ExecuteInEditMode]
public class DepthTextureGenerator : MonoBehaviour
{
    public Shader depthTextureShader; //用来生成mipmap的shader

    public static RenderTexture depthTexture; //带mipmap的深度图

    private static int _depthTextureSize = 0;
    private const RenderTextureFormat _depthTextureFormat = RenderTextureFormat.RHalf; //深度取值范围0-1，单通道即可
    public static Material depthMaterial;
    public static int depthTextureShaderID;

    public RawImage monitorImage;

    public static int depthTextureSize
    {
        get
        {
            if (_depthTextureSize == 0)
            {
                _depthTextureSize = Mathf.NextPowerOfTwo(Mathf.Max(Screen.width, Screen.height));
            }

            return _depthTextureSize;
        }
    }


    void InitDepthTexture()
    {
        if (depthTexture != null) return;
        depthTexture = new RenderTexture(depthTextureSize, depthTextureSize, 0, _depthTextureFormat);
        depthTexture.autoGenerateMips = false;
        depthTexture.useMipMap = true;
        depthTexture.filterMode = FilterMode.Point;
        depthTexture.Create();
        monitorImage.texture = depthTexture;
    }

    void Start()
    {
        depthMaterial = new Material(depthTextureShader);
        depthTextureShaderID = Shader.PropertyToID("_CameraDepthTexture");
        InitDepthTexture();
    }
}