using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassUtil
{
    //获取法线
    public static Vector3 GetFaceNormal(Vector3 v1, Vector3 v2, Vector3 v3)
    {
        var vx = v2 - v1;
        var vy = v3 - v1;
        return Vector3.Cross(vx, vy);
    }

    //三角形内部取平均分布的随机点
    public static Vector3 RandomPointInsideTriangle(Vector3 v1, Vector3 v2, Vector3 v3)
    {
        var x = Random.Range(0, 1f);
        var y = Random.Range(0, 1f);
        //因为是基于v1点的偏移，所以偏移值如果随机到了右上，反转到左下
        if (y > 1 - x)
        {
            var temp = y;
            y = 1 - x;
            x = 1 - temp;
        }

        var vx = v2 - v1;
        var vy = v3 - v1;
        //基于v1点的偏移
        return v1 + x * vx + y * vy;
    }

    private static Mesh _grassMesh;

    //生成草的Quad Mesh
    public static Mesh CreateGrassMesh()
    {
        var grassMesh = new Mesh {name = "Grass Quad"};
        float width = 1f;
        float height = 1f;
        float halfWidth = width / 2;
        grassMesh.SetVertices(new List<Vector3>
        {
            new Vector3(-halfWidth, 0, 0.0f),
            new Vector3(-halfWidth, height, 0.0f),
            new Vector3(halfWidth, 0, 0.0f),
            new Vector3(halfWidth, height, 0.0f),
        });
        grassMesh.SetUVs(0, new List<Vector2>
        {
            new Vector2(0, 0),
            new Vector2(0, 1),
            new Vector2(1, 0),
            new Vector2(1, 1),
        });

        grassMesh.SetIndices(new[] {0, 1, 2, 2, 1, 3,},
            MeshTopology.Triangles, 0, false);
        grassMesh.RecalculateNormals();
        grassMesh.UploadMeshData(true);
        return grassMesh;
    }

    //单株草的Mesh
    public static Mesh unitMesh
    {
        get
        {
            if (_grassMesh != null)
            {
                return _grassMesh;
            }

            _grassMesh = CreateGrassMesh();
            return _grassMesh;
        }
    }
}