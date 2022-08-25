using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

[ExecuteInEditMode]
public class GrassTerrain : MonoBehaviour
{
    //每个三角面需要种植的草的数量
    public int grassCntPerTriangle = 100;

    //该物体上最多生成的草的数量
    public int maxGrassCount = 100000000;

    //每株草的生成信息，最终会生成GrassInfos传递给材质
    public struct GrassInfo
    {
        //控制单株草在地面上的种植偏移和旋转
        public Matrix4x4 localToTerrain;

        //用来控制草贴图在atlas中的采样(如果需要的话)
        public Vector4 texParams;
    }

    //每株草的大小，会传递给材质属性
    public Vector2 grassQuadSize = new Vector2(0.4f, 0.6f);

    public Material material;

    //草的数量，传参给DrawMeshInstancedProcedural
    private int _grassCnt;
    [HideInInspector] public int updatedGrassCnt;


    //ComputeBuffer，会传递给材质的StructuredBuffer，设置GrassInfo
    public ComputeBuffer grassBuffer;

    //随机种子，用于生成随机的生成信息
    private int _seed;

    //_________________________视锥剔除_________________________
    public ComputeShader compute;
    private ComputeBuffer _cullResult;
    private int _kernel;
    private Camera _mainCamera;
    private int _vpMatrixId;
    private int _mTerrainMatrixId;
    private ComputeBuffer _argResult;
    uint[] args = new uint[5] {0, 0, 0, 0, 0};


    //任何挂载此脚本的物体，都会在其上渲染草地
    private static HashSet<GrassTerrain> _actives = new HashSet<GrassTerrain>();

    public static HashSet<GrassTerrain> actives
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

        if (_argResult != null)
        {
            _argResult.Dispose();
            _argResult = null;
        }

        if (_cullResult != null)
        {
            _cullResult.Dispose();
            _cullResult = null;
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
                Vector2 texScale = Vector2.one;
                Vector2 texOffset = Vector2.zero;
                Vector4 texParams = new Vector4(texScale.x, texScale.y, texOffset.x, texOffset.y);

                var positionInTerrain = GrassUtil.RandomPointInsideTriangle(v1, v2, v3);
                float rot = Random.Range(0, 180f);

                //生成位置旋转缩放矩阵
                var localToTerrain = Matrix4x4.TRS(positionInTerrain, upToNormal * Quaternion.Euler(0, rot, 0),
                    Vector3.one);

                var grassInfo = new GrassInfo()
                {
                    localToTerrain = localToTerrain,
                    texParams = texParams
                };
                grassInfos.Add(grassInfo);
                grassIndex++;
                if (grassIndex > maxGrassCount) break;
            }

            if (grassIndex > maxGrassCount) break;
        }

        _grassCnt = grassIndex;
        grassBuffer = new ComputeBuffer(_grassCnt, 64 + 16);
        grassBuffer.SetData(grassInfos);

        Debug.Log("艹的数量：" + _grassCnt);
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
        materialPropertyBlock.SetBuffer(ShaderProperties.GrassInfos, _cullResult);
        materialPropertyBlock.SetVector(ShaderProperties.GrassQuadSize, grassQuadSize);
    }

    void Start()
    {
        grassBuffer = GenGrassBuffer();
        _kernel = compute.FindKernel("ViewportCulling");
        _mainCamera = Camera.main;
        _cullResult = new ComputeBuffer(_grassCnt, sizeof(float) * (16 + 4), ComputeBufferType.Append);
        _argResult = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);

        compute.SetBool("isOpenGL",
            Camera.main.projectionMatrix.Equals(GL.GetGPUProjectionMatrix(Camera.main.projectionMatrix, false)));

        compute.SetInt("grassCount", maxGrassCount);
        _vpMatrixId = Shader.PropertyToID("vpMatrix");
        _mTerrainMatrixId = Shader.PropertyToID("mTerrainMatrix");
    }

    private void Update()
    {
        compute.SetBuffer(_kernel, "grassInfoBuffer", grassBuffer);
        _cullResult.SetCounterValue(0);
        compute.SetBuffer(_kernel, "cullResult", _cullResult);
        compute.SetMatrix(_vpMatrixId,
            GL.GetGPUProjectionMatrix(_mainCamera.projectionMatrix, false) * _mainCamera.worldToCameraMatrix);
        compute.SetMatrix(_mTerrainMatrixId, transform.localToWorldMatrix);
        compute.Dispatch(_kernel, 1 + (_grassCnt / 640), 1, 1);
        ComputeBuffer.CopyCount(_cullResult, _argResult, 0);
        int[] counter = new int[5] {0, 0, 0, 0, 0};
        _argResult.GetData(counter);
        updatedGrassCnt = counter[0];
        // Debug.Log("grassCnt count: " + updatedGrassCnt);
    }
}