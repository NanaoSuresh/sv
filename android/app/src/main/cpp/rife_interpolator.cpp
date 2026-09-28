#include "rife_interpolator.h"

#include <android/log.h>
#include <algorithm>
#include <cmath>

// ncnn headers
#include "net.h"
#include "gpu.h"
#include "mat.h"

#define TAG "RifePlugin"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

RifeInterpolator::RifeInterpolator() = default;

RifeInterpolator::~RifeInterpolator() {
    destroy();
}

bool RifeInterpolator::init(const std::string& modelDir, int gpuId, bool useVulkan) {
    if (m_initialized) destroy();

    m_gpuId = gpuId;
    m_useVulkan = useVulkan;

    // Check Vulkan support
    if (m_useVulkan) {
        int gpuCount = ncnn::get_gpu_count();
        if (gpuCount <= 0) {
            LOGI("No Vulkan GPU found, falling back to CPU");
            m_useVulkan = false;
        } else if (m_gpuId >= gpuCount) {
            m_gpuId = 0;
        }
    }

    m_net = new ncnn::Net();

    if (m_useVulkan) {
        m_net->opt.use_vulkan_compute = true;
        LOGI("Using Vulkan GPU %d for RIFE inference", m_gpuId);
    } else {
        m_net->opt.use_vulkan_compute = false;
        LOGI("Using CPU for RIFE inference");
    }

    // Use fp16 for speed on mobile
    m_net->opt.use_fp16_packed = true;
    m_net->opt.use_fp16_storage = true;
    m_net->opt.use_fp16_arithmetic = true;

    // Load RIFE v4 model
    std::string paramPath = modelDir + "/flownet.param";
    std::string binPath = modelDir + "/flownet.bin";

    int ret = m_net->load_param(paramPath.c_str());
    if (ret != 0) {
        LOGE("Failed to load model param from %s (ret=%d)", paramPath.c_str(), ret);
        delete m_net;
        m_net = nullptr;
        return false;
    }

    ret = m_net->load_model(binPath.c_str());
    if (ret != 0) {
        LOGE("Failed to load model bin from %s (ret=%d)", binPath.c_str(), ret);
        delete m_net;
        m_net = nullptr;
        return false;
    }

    m_initialized = true;
    LOGI("RIFE model loaded successfully from %s", modelDir.c_str());
    return true;
}

bool RifeInterpolator::process(const unsigned char* pixels0, const unsigned char* pixels1,
                                int w, int h, float timestep, unsigned char* output) {
    if (!m_initialized || !m_net) {
        LOGE("RIFE not initialized");
        return false;
    }

    // Pad to multiple of 32 for the model
    int paddedW = (w + 31) / 32 * 32;
    int paddedH = (h + 31) / 32 * 32;

    // Convert RGBA pixels to ncnn::Mat (RGB, float, normalized 0-1)
    ncnn::Mat in0 = ncnn::Mat::from_pixels(pixels0, ncnn::Mat::PIXEL_RGBA2RGB, w, h);
    ncnn::Mat in1 = ncnn::Mat::from_pixels(pixels1, ncnn::Mat::PIXEL_RGBA2RGB, w, h);

    // Normalize to 0-1 range
    const float norm[3] = {1.0f / 255.0f, 1.0f / 255.0f, 1.0f / 255.0f};
    const float mean[3] = {0.0f, 0.0f, 0.0f};
    in0.substract_mean_normalize(mean, norm);
    in1.substract_mean_normalize(mean, norm);

    // Pad if needed
    ncnn::Mat in0_padded;
    ncnn::Mat in1_padded;

    if (paddedW != w || paddedH != h) {
        ncnn::copy_make_border(in0, in0_padded, 0, paddedH - h, 0, paddedW - w,
                               ncnn::BORDER_REPLICATE, 0.0f);
        ncnn::copy_make_border(in1, in1_padded, 0, paddedH - h, 0, paddedW - w,
                               ncnn::BORDER_REPLICATE, 0.0f);
    } else {
        in0_padded = in0;
        in1_padded = in1;
    }

    // Timestep mat
    ncnn::Mat timestep_mat(1, 1, 1);
    timestep_mat[0] = timestep;

    // Run inference
    ncnn::Extractor ex = m_net->create_extractor();

    if (m_useVulkan) {
        ex.set_vulkan_compute(true);
    }

    ex.input("x", in0_padded);
    ex.input("x_1", in1_padded);
    ex.input("timestep", timestep_mat);

    ncnn::Mat out;
    int ret = ex.extract("output", out);
    if (ret != 0) {
        LOGE("RIFE inference failed (ret=%d)", ret);
        return false;
    }

    // Crop back to original size if padded
    ncnn::Mat out_cropped;
    if (paddedW != w || paddedH != h) {
        ncnn::copy_cut_border(out, out_cropped, 0, paddedH - h, 0, paddedW - w);
    } else {
        out_cropped = out;
    }

    // Denormalize (0-1 → 0-255) and convert to RGBA
    const float denorm[3] = {255.0f, 255.0f, 255.0f};
    const float demean[3] = {0.0f, 0.0f, 0.0f};
    out_cropped.substract_mean_normalize(demean, denorm);

    out_cropped.to_pixels(output, ncnn::Mat::PIXEL_RGB2RGBA);

    return true;
}

void RifeInterpolator::destroy() {
    if (m_net) {
        delete m_net;
        m_net = nullptr;
    }
    m_initialized = false;
    LOGI("RIFE model destroyed");
}
