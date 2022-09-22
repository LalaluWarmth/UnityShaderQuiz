using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CubeTransformer : MonoBehaviour
{
    public float maxX = 10;
    public float minX = 0;
    public float speed = 1f;

    private int flag = 1;

    // Start is called before the first frame update
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 newScale = transform.localScale;
        if (newScale.x > maxX) flag = -1;
        if (newScale.x < minX) flag = 1;
        newScale.x = newScale.x + flag * speed * Time.deltaTime;
        transform.localScale = newScale;
    }
}