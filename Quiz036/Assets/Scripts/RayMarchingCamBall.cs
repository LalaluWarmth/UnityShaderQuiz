using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RayMarchingCamBall : SceneViewFilter
{
    [SerializeField] private Shader _shader;

    private Material _raymarchMat;

    public Material _raymarchMaterial
    {
        get
        {
            if (!_raymarchMat && _shader)
            {
                _raymarchMat = new Material(_shader);
                _raymarchMat.hideFlags = HideFlags.HideAndDontSave;
            }

            return _raymarchMat;
        }
    }

    private Camera _cam;

    public Camera _camera
    {
        get
        {
            if (!_cam)
            {
                _cam = GetComponent<Camera>();
            }

            return _cam;
        }
    }

    [Header("Setup")] public float _maxDistance;
    [Range(1, 300)] public int _MaxIterations;
    [Range(0.1f, 0.001f)] public float _Accuracy;
    [Header("Color")] public Color _GroundColor;
    public Color _sphereColor;
    public Color _LightCol;
    [Header("Sphere")] public Transform[] _sphereRigi;
    public float _sphereSmooth;
    [Header("Direction Light")] public Transform _directionLight;
    public float _LightIntensity;
    Vector4[] Rigis;

    private void Start()
    {
        Rigis = new Vector4[_sphereRigi.Length];
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (!_raymarchMaterial)
        {
            Graphics.Blit(src, dest);
            return;
        }

        for (int i = 0; i < _sphereRigi.Length; i++)
        {
            Rigis[i] = new Vector4(_sphereRigi[i].position.x, _sphereRigi[i].position.y,
                _sphereRigi[i].position.z, _sphereRigi[i].localScale.x);
        }

        _raymarchMaterial.SetMatrix("_CamFrustum", CamFrustum(_camera));
        _raymarchMaterial.SetMatrix("_CamToWorld", _camera.cameraToWorldMatrix);

        _raymarchMaterial.SetFloat("_maxDistance", _maxDistance);
        _raymarchMaterial.SetFloat("_Accuracy", _Accuracy);
        _raymarchMaterial.SetFloat("_MaxIterations", _MaxIterations);
        //color
        _raymarchMaterial.SetColor("_GroundColor", _GroundColor);
        _raymarchMaterial.SetColor("_sphereColor", _sphereColor);
        _raymarchMaterial.SetColor("_LightCol", _LightCol);
        //Sphere
        _raymarchMat.SetInt("_sphereRigiNum", Rigis.Length);
        _raymarchMaterial.SetVectorArray("_sphereRigi", Rigis);
        _raymarchMaterial.SetFloat("_sphereSmooth", _sphereSmooth);
        //light
        _raymarchMaterial.SetVector("_LightDir", _directionLight ? _directionLight.forward : Vector3.down);
        _raymarchMaterial.SetFloat("_LightIntensity", _LightIntensity);


        RenderTexture.active = dest;
        _raymarchMaterial.SetTexture("_MainTex", src);
        GL.PushMatrix();
        GL.LoadOrtho();
        _raymarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);

        //BL
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f); //3.0f == 第三 row
        //BR
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        //TR
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        //TL
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }

    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan(cam.fieldOfView * 0.5f * Mathf.Deg2Rad);
        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;

        Vector3 TL = (-Vector3.forward - goRight + goUp);
        Vector3 TR = (-Vector3.forward + goRight + goUp);
        Vector3 BR = (-Vector3.forward + goRight - goUp);
        Vector3 BL = (-Vector3.forward - goRight - goUp);

        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BR);
        frustum.SetRow(3, BL);
        return frustum;
    }
}