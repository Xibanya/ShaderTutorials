#ifndef XIBANYA_SPITE_LIBRARY_INCLUDED
#define XIBANYA_SPITE_LIBRARY_INCLUDED

#define UnpackScaleNormal UnpackNormalScale
#define tex2D(idx, uv) SAMPLE_TEXTURE2D(idx, sampler##idx, uv)
#define v2f Varyings

#endif