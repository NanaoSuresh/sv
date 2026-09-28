#include <jni.h>
#include <android/bitmap.h>
#include <android/log.h>
#include <string>

#include "rife_interpolator.h"

#define TAG "RifeJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_vplayer_vplayer_RifePlugin_nativeInit(
    JNIEnv* env, jobject /* this */,
    jstring modelPath, jint gpuId, jboolean useVulkan) {

    const char* path = env->GetStringUTFChars(modelPath, nullptr);
    std::string modelDir(path);
    env->ReleaseStringUTFChars(modelPath, path);

    auto* interp = new RifeInterpolator();
    bool ok = interp->init(modelDir, (int)gpuId, (bool)useVulkan);

    if (!ok) {
        LOGE("Failed to initialize RIFE");
        delete interp;
        return 0;
    }

    LOGI("RIFE initialized, handle=%p", interp);
    return reinterpret_cast<jlong>(interp);
}

JNIEXPORT jboolean JNICALL
Java_com_vplayer_vplayer_RifePlugin_nativeProcess(
    JNIEnv* env, jobject /* this */,
    jlong handle,
    jobject inputBitmap0, jobject inputBitmap1,
    jfloat timestep,
    jobject outputBitmap) {

    auto* interp = reinterpret_cast<RifeInterpolator*>(handle);
    if (!interp || !interp->isInitialized()) {
        LOGE("RIFE not initialized");
        return JNI_FALSE;
    }

    // Lock bitmaps
    AndroidBitmapInfo info0, info1, infoOut;
    void *pixels0 = nullptr, *pixels1 = nullptr, *pixelsOut = nullptr;

    if (AndroidBitmap_getInfo(env, inputBitmap0, &info0) != 0 ||
        AndroidBitmap_getInfo(env, inputBitmap1, &info1) != 0 ||
        AndroidBitmap_getInfo(env, outputBitmap, &infoOut) != 0) {
        LOGE("Failed to get bitmap info");
        return JNI_FALSE;
    }

    if (info0.format != ANDROID_BITMAP_FORMAT_RGBA_8888 ||
        info1.format != ANDROID_BITMAP_FORMAT_RGBA_8888 ||
        infoOut.format != ANDROID_BITMAP_FORMAT_RGBA_8888) {
        LOGE("Bitmap format must be RGBA_8888");
        return JNI_FALSE;
    }

    if (info0.width != info1.width || info0.height != info1.height) {
        LOGE("Input bitmaps must have same dimensions");
        return JNI_FALSE;
    }

    if (AndroidBitmap_lockPixels(env, inputBitmap0, &pixels0) != 0 ||
        AndroidBitmap_lockPixels(env, inputBitmap1, &pixels1) != 0 ||
        AndroidBitmap_lockPixels(env, outputBitmap, &pixelsOut) != 0) {
        LOGE("Failed to lock bitmap pixels");
        return JNI_FALSE;
    }

    bool ok = interp->process(
        (const unsigned char*)pixels0,
        (const unsigned char*)pixels1,
        (int)info0.width, (int)info0.height,
        (float)timestep,
        (unsigned char*)pixelsOut
    );

    AndroidBitmap_unlockPixels(env, inputBitmap0);
    AndroidBitmap_unlockPixels(env, inputBitmap1);
    AndroidBitmap_unlockPixels(env, outputBitmap);

    return ok ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL
Java_com_vplayer_vplayer_RifePlugin_nativeDestroy(
    JNIEnv* /* env */, jobject /* this */, jlong handle) {

    auto* interp = reinterpret_cast<RifeInterpolator*>(handle);
    if (interp) {
        interp->destroy();
        delete interp;
        LOGI("RIFE handle destroyed");
    }
}

} // extern "C"
