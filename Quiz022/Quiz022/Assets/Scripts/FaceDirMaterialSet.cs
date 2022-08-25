using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FaceDirMaterialSet : MonoBehaviour
{
    private Material _material;
    // Start is called before the first frame update
    void Start()
    {
        _material = gameObject.GetComponent<SkinnedMeshRenderer>().materials[0];
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
