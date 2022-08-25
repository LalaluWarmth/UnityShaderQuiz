using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthTextureGenerator : MonoBehaviour
{
    public Shader depthTextureShader; //用来生成mipmap的shader

    public RenderTexture depthTexture; //带mipmap的深度图

    private int _depthTextureSize = 0;
    private const RenderTextureFormat _depthTextureFormat = RenderTextureFormat.RHalf;//深度取值范围0-1，单通道即可
    private Material _depthMaterial;
    private int _depthTextureShaderID;

    public int depthTextureSize
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
    }

    void Start()
    {
        _depthMaterial = new Material(depthTextureShader);
        Camera.main.depthTextureMode |= DepthTextureMode.Depth;
        _depthTextureShaderID = Shader.PropertyToID("_CameraDepthTexture");
        InitDepthTexture();
    }

    
}