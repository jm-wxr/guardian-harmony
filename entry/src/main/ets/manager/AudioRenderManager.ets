import { promptAction } from '@kit.ArkUI'
import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit'

class AudioRenderManager {
  private audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率
    channels: audio.AudioChannel.CHANNEL_2, // 通道
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
  }
  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_MUSIC, // 播放类型，MUSIC 表示用喇叭播放
    rendererFlags: 0 // 0代表普通音频渲染器，1代表低时延音频渲染器。
  }
  private audioRenderer: audio.AudioRenderer | null = null

  // 获取音频渲染器
  async getAudioRenderer() {
    if (this.audioRenderer) {
      return this.audioRenderer
    }
    try {
      this.audioRenderer = await audio.createAudioRenderer({
        streamInfo: this.audioStreamInfo,
        rendererInfo: this.audioRendererInfo
      })
      console.info('AudioRenderer 创建成功')
    } catch (err) {
      console.error(`AudioRenderer 创建失败，错误码为${err.code}，错误消息为${err.message}`)
    }
    return this.audioRenderer
  }

  // 播放录音
  async startRenderer(filePath: string) {
    // 1. 获取音频渲染器（播放器）
    const audioRenderer = await this.getAudioRenderer()
    // 偏移值
    let bufferSize: number = 0
    // 根据路径打开文件
    const file = fileIo.openSync(filePath)
    // 2. 调用on('writeData')方法，订阅监听音频数据写入回调
    audioRenderer?.on('writeData', (buffer) => {
      fileIo.readSync(file.fd, buffer, { offset: bufferSize, length: buffer.byteLength })
      bufferSize += buffer.byteLength
      // 获取文件信息，如果读取时已经超出文件大小，自动停止
      const stat = fileIo.statSync(file.fd)
      if (bufferSize >= stat.size) {
        // 停止渲染器（播放器）
        this.stopRenderer()
      }
    })
    // 3. 启动音频渲染器（播放器）
    audioRenderer?.start()
  }

  // 停止播放录音
  async stopRenderer() {
    // 获取音频渲染器（播放器）
    const audioRenderer = await this.getAudioRenderer()
    await audioRenderer?.stop() // 停止
    audioRenderer?.release() // 释放资源
    this.audioRenderer = null // 清理变量
  }
}

export const audioRenderManager = new AudioRenderManager()