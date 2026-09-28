#pragma once

#include <string>
#include <vector>

// Forward declarations — ncnn headers included only in .cpp
namespace ncnn {
class Net;
class VkAllocator;
class VkCompute;
class Option;
}

class RifeInterpolator {
public:
    RifeInterpolator();
    ~RifeInterpolator();

    /// Initialize the RIFE model.
    /// @param modelDir Directory containing flownet.param and flownet.bin
    /// @param gpuId GPU device index (-1 for CPU)
    /// @param useVulkan Whether to use Vulkan GPU acceleration
    /// @return true on success
    bool init(const std::string& modelDir, int gpuId = 0, bool useVulkan = true);

    /// Interpolate between two frames.
    /// @param pixels0 RGBA pixel data for frame 0 (w * h * 4 bytes)
    /// @param pixels1 RGBA pixel data for frame 1 (w * h * 4 bytes)
    /// @param w Frame width
    /// @param h Frame height
    /// @param timestep Interpolation position (0.0 = frame0, 1.0 = frame1, 0.5 = midpoint)
    /// @param output Pre-allocated RGBA output buffer (w * h * 4 bytes)
    /// @return true on success
    bool process(const unsigned char* pixels0, const unsigned char* pixels1,
                 int w, int h, float timestep, unsigned char* output);

    /// Release resources.
    void destroy();

    bool isInitialized() const { return m_initialized; }

private:
    ncnn::Net* m_net = nullptr;
    bool m_initialized = false;
    bool m_useVulkan = false;
    int m_gpuId = 0;
};
