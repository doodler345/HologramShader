using System.Collections;
using System.Collections.Generic;
using System.Data.Common;
using System.Threading;
using UnityEngine;

public class HologramScript : MonoBehaviour
{
    [SerializeField] SkinnedMeshRenderer[] renderers;

    [Header("Interference")]
    [SerializeField] float interferenceAmpMin = 0.1f;
    [SerializeField] float interferenceAmpMax = 0.6f;
    [SerializeField] float interferenceFreqMin = 2f;
    [SerializeField] float interferenceFreqMax = 26f;
    [SerializeField] float interferenceWaittimeMin = 4f;
    [SerializeField] float interferenceWaittimeMax = 8f;
    [SerializeField] float interferenceDurationMin = 0.01f;
    [SerializeField] float interferenceDurationMax = 0.2f;
    [Header("Riffles")]
    [SerializeField] float riffleTextureScrollSpeed = 0.5f;
    [SerializeField] float riffleTextureBigScrollSpeed = 0.5f;
    private float interferenceWaittime;
    private float interferenceDuration;
    private Vector2 riffleTextureOffset;
    private Vector2 riffleTextureBigOffset;
    private float interferenceTimer = 0;
    private bool isInterferingSignal = false;

    private void Awake()
    {
        riffleTextureOffset = renderers[0].material.GetTextureOffset("_riffleTexture");
        riffleTextureOffset = renderers[0].material.GetTextureOffset("_riffleTextureBig");

        interferenceWaittime = interferenceAmpMin;
        interferenceDuration = interferenceDurationMin;
    }

    private void Update()
    {
        interferenceTimer += Time.deltaTime;
        if (interferenceTimer > interferenceWaittime)
        {
            if (!isInterferingSignal)
            {
                float intensity = Random.Range(interferenceAmpMin, interferenceAmpMax);
                float freq = Random.Range(interferenceFreqMin, interferenceFreqMax);
                foreach(var renderer in renderers)
                {
                    renderer.material.SetFloat("_interferenceAmplitude", intensity);
                    renderer.material.SetFloat("_interferenceFreq", freq);
                }
                isInterferingSignal = true;
            }

            foreach (var renderer in renderers)
            {
                renderer.material.GetTextureOffset("_riffleTexture");
            }

            if (interferenceTimer > interferenceWaittime + interferenceDuration)
            {
                foreach (var renderer in renderers)
                {
                    renderer.material.SetFloat("_interferenceAmplitude", 0);
                }
                interferenceTimer = 0;
                isInterferingSignal = false;

                interferenceWaittime = Random.Range(interferenceWaittimeMin, interferenceWaittimeMax);
                interferenceDuration = Random.Range(interferenceDurationMin, interferenceDurationMax);
            }
        }


        riffleTextureOffset.y += riffleTextureScrollSpeed * Time.deltaTime;
        riffleTextureBigOffset.y += riffleTextureBigScrollSpeed * Time.deltaTime;
        foreach (var renderer in renderers)
        {
            renderer.material.SetTextureOffset("_riffleTexture", riffleTextureOffset);
            renderer.material.SetTextureOffset("_riffleTextureBig", riffleTextureBigOffset);
        }
    }
}
