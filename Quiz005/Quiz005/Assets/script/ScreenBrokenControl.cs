using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ScreenBrokenControl : MonoBehaviour
{
    public Material material;
    [Range(0,1)]public float brokenScale;

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        material.SetTexture("_MainTex",src);
        material.SetFloat("_BrokenScale",brokenScale);
        Graphics.Blit(src,dest,material,-1);
    }
}
