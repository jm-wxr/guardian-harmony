import { Permissions } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit'
import { permissionManager } from '.'

interface AudioInfo {
  filePath: string
  date_added: number
  duration: number
}

class AudioCaptureManager {
  // 权限
  private permissions: Permissions[] = ["ohos.permission.MICROPHONE"]
  // 音频流配置
  private audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率
    channels: audio.AudioChannel.CHANNEL_2, // 通道
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式
  }
  // 音频采集器配置
  private audioCaptureInfo: audio.AudioCapturerInfo = {
    source: audio.SourceType.SOURCE_TYPE_MIC, // 音源类型
    capturerFlags: 0 // 0代表普通音频采集器，1代表低时延音频采集器。
  }
  // 音频采集器实例
  private audioCapturer: audio.AudioCapturer | null = null
  // 录音文件路径
  private filePath: string = ''
  // 录音创建时间
  private date_added: number = 0

  // 申请权限
  async requestPermissions() {
    try {
      await permissionManager.requestPermissions(this.permissions)
    } catch (err) {
      const res = await promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '录音功能需要获取权限，请在系统设置中打开麦克风开关',
        buttons: [
          { text: '取消', color: '#999' },
          { text: '去开启', color: $r('sys.color.ohos_id_color_primary') }
        ]
      })
      if (res.index === 1) {
        permissionManager.openPermissionSettingsPage()
      }
    }
  }

  // 获取音频采集器实例
  async getAudioCapturer() {
    // 如果已经有实例，直接返回
    if (this.audioCapturer) {
      return this.audioCapturer
    }
    // 没有就创建
    try {
      this.audioCapturer = await audio.createAudioCapturer({
        streamInfo: this.audioStreamInfo,
        capturerInfo: this.audioCaptureInfo
      })
      console.info('AudioCapturer 创建成功')
    } catch (err) {
      console.error(`AudioCapturer 创建失败，错误码为${err.code}，错误消息为${err.message}`)
    }
    return this.audioCapturer
  }

  /**
   * 开始录音
   * @param filePath 录音文件保存的文件路径
   */
  async startRecorder(filePath: string) {
    // 打开文件，如果不存在自动创建
    const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
    // 创建音频采集实例
    const audioCapturer = await this.getAudioCapturer()
    // 偏移值
    let bufferSize: number = 0
    // 订阅监听音频数据读入回调
    audioCapturer?.on('readData', (buffer) => {
      // 写入文件
      fileIo.writeSync(file.fd, buffer, { offset: bufferSize, length: buffer.byteLength })
      bufferSize += buffer.byteLength
    })
    // 开始录音采集
    audioCapturer?.start()
    // 保存文件路径
    this.filePath = filePath
    // 保存录音创建时间
    this.date_added = Date.now()
  }

  /**
   * 停止录音
   * @returns 录音的保存路径、创建时间、持续时间
   */
  async stopRecorder(): Promise<AudioInfo> {
    const audioCapturer = await this.getAudioCapturer()
    await audioCapturer?.stop()
    audioCapturer?.release()
    this.audioCapturer = null
    return {
      filePath: this.filePath,
      date_added: this.date_added,
      duration: Date.now() - this.date_added
    }
  }
}

export const audioCaptureManager = new AudioCaptureManager()