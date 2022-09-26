using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

[ExecuteInEditMode]
public class GrassTerrain : MonoBehaviour
{
    [Header("GrassCount")]
    //每个三角面需要种植的草的数量
    public int grassCntPerTriangle = 80;

    //该物体上最多生成的草的数量
    public static int maxGrassCount = 2000000;

    //草的数量，传参给DrawMeshInstancedProcedural
    public int grassCnt;
    public int updatedGrassCnt;

    [Header("GrassInfo")]
    //每株草的大小，会传递给材质属性
    public Vector2 grassQuadSize = new Vector2(0.4f, 0.6f);

    public Material material;

    [Header("Lod")] [Range(0, 1)] public float lod1 = 0.3f;
    [Range(0, 1)] public float lod1GrassCount = 0.5f;
    [Range(0, 1)] public float lod2 = 0.7f;
    [Range(0, 1)] public float lod2GrassCount = 0.25f;


    //每株草的生成信息，最终会生成GrassInfos传递给材质
    public struct GrassInfo
    {
        //控制单株草在地面上的种植偏移和旋转
        public Matrix4x4 localToTerrain;

        //id
        public int id;
    }


    //ComputeBuffer，会传递给材质的StructuredBuffer，设置GrassInfo
    public ComputeBuffer grassBuffer;

    //随机种子，用于生成随机的生成信息
    private int _seed;

    //_________________________视锥剔除_________________________
    [Header("ComputeShader")] public ComputeShader compute;
    public ComputeBuffer cullResult;
    [HideInInspector] public int kernel;
    [HideInInspector] public Camera mainCamera;
    [HideInInspector] public int vpMatrixId;
    [HideInInspector] public int hizTextureId;
    [HideInInspector] public int mTerrainMatrixId;
    public ComputeBuffer argResult;
    uint[] args = new uint[5] {0, 0, 0, 0, 0};


    //任何挂载此脚本的物体，都会在其上渲染草地
    private static List<GrassTerrain> _actives = new List<GrassTerrain>();

    public static List<GrassTerrain> actives
    {
        get { return _actives; }
    }

    void OnEnable()
    {
        _actives.Add(this);
    }

    void OnDisable()
    {
        _actives.Remove(this);
        if (grassBuffer != null)
        {
            grassBuffer.Dispose();
            grassBuffer = null;
        }

        if (argResult != null)
        {
            argResult.Dispose();
            argResult = null;
        }

        if (cullResult != null)
        {
            cullResult.Dispose();
            cullResult = null;
        }
    }

    //初始化随机种子
    private void Awake()
    {
        _seed = System.Guid.NewGuid().GetHashCode();
    }


    private ComputeBuffer GenGrassBuffer()
    {
        if (grassBuffer != null)
        {
            return grassBuffer;
        }

        var meshFilter = GetComponent<MeshFilter>();
        var terrainMesh = meshFilter.sharedMesh;
        var grassIndex = 0;
        List<GrassInfo> grassInfos = new List<GrassInfo>();

        Random.InitState(_seed);

        //Terrain的顶点数据
        var indices = terrainMesh.triangles;
        //Terrain的顶点绘制顺序，存放顶点索引，每三个索引代表一个三角面
        var vertices = terrainMesh.vertices;


        for (var j = 0; j < indices.Length / 3; j++)
        {
            //当前三角面的顶点索引
            var index1 = indices[j * 3];
            var index2 = indices[j * 3 + 1];
            var index3 = indices[j * 3 + 2];
            //当前三角面的三个顶点
            var v1 = vertices[index1];
            var v2 = vertices[index2];
            var v3 = vertices[index3];

            //面的法线向量
            var normal = GrassUtil.GetFaceNormal(v1, v2, v3);

            //计算Vector.up到faceNormal的旋转
            var upToNormal = Quaternion.FromToRotation(Vector3.up, normal);

            for (var i = 0; i < grassCntPerTriangle; i++)
            {
                var positionInTerrain = GrassUtil.RandomPointInsideTriangle(v1, v2, v3);
                float rot = Random.Range(0, 180f);

                //生成位置旋转缩放矩阵
                var localToTerrain = Matrix4x4.TRS(positionInTerrain, upToNormal * Quaternion.Euler(0, rot, 0),
                    Vector3.one);

                var positionInWorld = positionInTerrain + transform.position;
                var dis = Vector3.Distance(positionInWorld, Camera.main.transform.position);

                var grassInfo = new GrassInfo()
                {
                    localToTerrain = localToTerrain,
                    id = i
                };
                grassInfos.Add(grassInfo);
                grassIndex++;
                if (grassIndex > maxGrassCount) break;
            }

            if (grassIndex > maxGrassCount) break;
        }

        grassCnt = grassIndex;
        grassBuffer = new ComputeBuffer(grassCnt, 64 + 4);
        grassBuffer.SetData(grassInfos);
        return grassBuffer;
    }

    //通过MaterialPropertyBlock来给材质球设置参数:
    private MaterialPropertyBlock _materialBlock;

    public MaterialPropertyBlock materialPropertyBlock
    {
        get
        {
            if (_materialBlock == null)
            {
                _materialBlock = new MaterialPropertyBlock();
            }

            return _materialBlock;
        }
    }

    private class ShaderProperties
    {
        public static readonly int TerrainLocalToWorld = Shader.PropertyToID("_TerrainLocalToWorld");
        public static readonly int GrassInfos = Shader.PropertyToID("_GrassInfos");
        public static readonly int GrassQuadSize = Shader.PropertyToID("_GrassQuadSize");
    }

    public void UpdateMaterialProperties()
    {
        materialPropertyBlock.SetMatrix(ShaderProperties.TerrainLocalToWorld, transform.localToWorldMatrix);
        materialPropertyBlock.SetBuffer(ShaderProperties.GrassInfos, cullResult);
        materialPropertyBlock.SetVector(ShaderProperties.GrassQuadSize, grassQuadSize);
    }

    void Start()
    {
        grassBuffer = GenGrassBuffer();
        kernel = compute.FindKernel("ViewportCulling");
        mainCamera = Camera.main;
        cullResult = new ComputeBuffer(grassCnt, sizeof(float) * 16 + sizeof(int) * 1, ComputeBufferType.Append);
        argResult = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);

        compute.SetBool("isOpenGL",
            Camera.main.projectionMatrix.Equals(GL.GetGPUProjectionMatrix(Camera.main.projectionMatrix, false)));

        compute.SetInt("grassCount", maxGrassCount);
        Debug.Log("DepthTextureGenerator.depthTextureSize " + DepthTextureGenerator.depthTextureSize);
        compute.SetInt("depthTextureSize", DepthTextureGenerator.depthTextureSize);
        vpMatrixId = Shader.PropertyToID("vpMatrix");
        hizTextureId = Shader.PropertyToID("hizTexture");
        mTerrainMatrixId = Shader.PropertyToID("mTerrainMatrix");
    }

    void Update()
    {
    }
}