using UnityEngine;

public class InteractSphere : MonoBehaviour
{
    public Material material;

    private void OnCollisionEnter(Collision other)
    {
        material.SetVector("_InteractPoint", other.contacts[0].point);
        material.SetFloat("_Toggle", 1);//使用toggle控制是否输入顶点有效


    }
    private void OnCollisionExit(Collision other)
    {
        material.SetFloat("_Toggle", 0);
    }
}
