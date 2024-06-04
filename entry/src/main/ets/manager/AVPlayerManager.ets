import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';

class AVPlayerManager {
  private avPlayer: media.AVPlayer | null = null // AVPlayer实例对象
  private loop: boolean = false // 是否循环
  private rawFdPath: string = '' // 原始文件地址

  /**
   * 注册 avPlayer 回调函数
   * @param avPlayer AVPlayer实例对象
   */
  setAVPlayerCallback(avPlayer: media.AVPlayer) {
    avPlayer.on('error', (err: BusinessError) => {
      AlertDialog.show({ message: `操作 avPlayer 失败，错误码：${err.code}，错误消息：${err.message}` })
      avPlayer.reset() // 调用reset重置资源，触发idle状态
    })
    avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      switch (state) {
        case 'initialized': // 设置播放源后触发该状态上报
          avPlayer.prepare()
          break
        case 'prepared': // prepare调用成功后触发
          avPlayer.play()
          break
        case 'completed':
          if (this.loop) {
            avPlayer.play()
          } else {
            avPlayer.stop()
          }
          break
        case 'stopped':
          avPlayer.reset()
          break
        default:
          break
      }
    })
  }

  /**
   * 获取 avPlayer 实例对象
   * @returns 实例对象
   */
  async getAVPlayerInstance() {
    if (this.avPlayer) {
      return this.avPlayer // 如果实例存在，直接返回
    }
    const avPlayer = await media.createAVPlayer() // 创建avPlayer实例
    this.setAVPlayerCallback(avPlayer) // 创建状态机变化回调函数
    this.avPlayer = avPlayer
    return this.avPlayer // 返回实例
  }

  /**
   * 通过原始文件路径播放
   * @param rawFdPath 原始文件路径
   */
  async playByRawSrc(rawFdPath: string) {
    const avPlayer = await this.getAVPlayerInstance()
    // 释放资源，使其保持idle状态
    await avPlayer.reset()
    const context = getContext()
    // 加载 rawfile 文件夹下的文件
    const fileDescriptor = await context.resourceManager.getRawFd(rawFdPath)
    avPlayer.fdSrc = fileDescriptor // 设置播放路径
    avPlayer.play() // 播放
  }

  /**
   * 停止播放
   */
  async stop() {
    const avPlayer = await this.getAVPlayerInstance()
    avPlayer.stop()
  }

  /**
   * 设置是否循环
   * @param isLoop 是否循环
   */
  setLoop(isLoop: boolean) {
    this.loop = isLoop
  }
}

export const avPlayerManager = new AVPlayerManager()