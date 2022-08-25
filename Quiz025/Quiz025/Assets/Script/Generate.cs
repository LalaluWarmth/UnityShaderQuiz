using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Generate : MonoBehaviour
{
    public GameObject prefab;

    void Start()
    {
        for (int i = 0; i < 1000; i++)
        {
            GameObject obj = Instantiate(prefab);
            obj.transform.SetParent(this.transform);
            obj.transform.position = new Vector3(Random.Range(-90f, 90f), Random.Range(-40f, 40f), Random.Range(-50f, 50f));
        }
    }
}