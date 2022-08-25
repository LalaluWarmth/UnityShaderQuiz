using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PrefabScript : MonoBehaviour
{
    private MeshRenderer meshRenderer;

    void Start()
    {
        meshRenderer = GetComponent<MeshRenderer>();
        MaterialPropertyBlock prop = new MaterialPropertyBlock();
        Color color = new Color(Random.Range(0f, 1f), Random.Range(0f, 1f), Random.Range(0f, 1f));
        prop.SetColor("_Color2", color);
        meshRenderer.SetPropertyBlock(prop);
    }
}