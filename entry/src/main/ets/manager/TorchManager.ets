import { camera } from '@kit.CameraKit';

// 手电筒模式(闪光灯)
class TorchManager {
  private cameraManager: camera.CameraManager | null = null

  async getCameraManagerInstance() {
    // 如果已存在直接返回
    if (this.cameraManager) {
      return this.cameraManager
    }
    // 初始化 CameraManager
    const cameraManager = camera.getCameraManager(getContext())
    // 检查是否支持
    if (cameraManager.isTorchSupported() === false) {
      return Promise.reject('当前设备不支持闪光灯')
    }
    // 保存并返回
    this.cameraManager = cameraManager
    return this.cameraManager
  }

  // 开启闪光灯(手电筒模式)
  async openTorch() {
    const cameraManager = await this.getCameraManagerInstance()
    cameraManager.setTorchMode(camera.TorchMode.ON)
  }

  // 关闭闪光灯(手电筒模式)
  async closeTorch() {
    const cameraManager = await this.getCameraManagerInstance()
    cameraManager.setTorchMode(camera.TorchMode.OFF)
  }

  // 切换闪光灯(手电筒模式)
  async toggleTorch() {
    const cameraManager = await this.getCameraManagerInstance()
    if (cameraManager.getTorchMode() === camera.TorchMode.OFF) {
      this.openTorch()
    } else {
      this.closeTorch()
    }
  }
}

export const torchManager = new TorchManager()