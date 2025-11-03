#pragma once
#include <inttypes.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#ifdef __cplusplus
extern "C" {
#endif
extern float ssim_plane(uint8_t *pix1, intptr_t stride1,
                        uint8_t *pix2, intptr_t stride2,
                        int width, int height, void *buf, int *cnt );

#ifdef __cplusplus
}
#endif
