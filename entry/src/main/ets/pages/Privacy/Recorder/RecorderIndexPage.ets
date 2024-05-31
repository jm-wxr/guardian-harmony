import { promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import dayjs from 'dayjs'
import duration from 'dayjs/plugin/duration'
import { EmptyTipsComp } from '../../../common/components'
import { PRIVACY_RECORDER_FOLDER } from '../../../common/constants'
import { isEmulator } from '../../../common/dev'
import { CustomInputDialog } from '../../../common/dialog'
import { privacyRecorderDB, PrivacyRecorderDBInfo } from '../../../database/PrivacyDB'
import { audioCaptureManager, audioRenderManager } from '../../../manager'

// 用于把毫秒格式化成 mm:ss 的相对时间插件
dayjs.extend(duration)

@Entry
@Component
struct RecorderIndexPage {
  @State list: PrivacyRecorderDBInfo[] = [] // 录音文件列表
  @State tempInputText: string = '' // 绑定弹窗的输入框内容
  @State onConfirmEnable: boolean = true
  @State activeItem: PrivacyRecorderDBInfo | null = null // 播放/重命名的录音
  @State isRecording: boolean = false // 是否正在录音
  @State isPlaying: boolean = false // 是否正在播放
  @State recordingTime: number = 0 // 录音计时，单位：s
  @State playingTime: number = 0 // 当前播放时间，单位：ms
  private filePath: string = '' // 模拟器临时使用的录音文件路径变量
  // 自定义弹窗层
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomInputDialog({
      title: '重命名音频',
      message: '支持下划线、数宇、英文字母与中文',
      inputText: this.tempInputText,
      onConfirm: async () => {
        // TODO：重命名录音
        this.renameRecord()
      },
    }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center,
  })
  private playingTimerId: number = -1
  private recordingTimerId: number = -1

  async aboutToAppear() {
    // 开启录音权限
    await audioCaptureManager.requestPermissions()
    // 初始化文件夹
    this.initFolder()
    // 获取录音列表
    this.getList()
  }

  async getList() {
    this.list = await privacyRecorderDB.query()
  }

  // 初始化隐私录音的文件夹
  initFolder() {
    const context = getContext()
    // 获取沙箱目录
    const filesDir = context.filesDir
    // 列出沙箱目录下的所有文件(文件夹)
    const list = fileIo.listFileSync(filesDir)
    // 如果没有隐私目录，就新建一个
    if (!list.includes(PRIVACY_RECORDER_FOLDER)) {
      fileIo.mkdirSync(filesDir + '/' + PRIVACY_RECORDER_FOLDER)
    }
  }

  // 开始录音
  async startRecorder() {
    this.isRecording = true
    // 开启计时效果
    this.recordingTime = 0 // 初始化秒数
    clearInterval(this.recordingTimerId)
    this.recordingTimerId = setInterval(() => {
      this.recordingTime++
    }, 1000)
    const context = getContext()
    const filePath = context.filesDir + '/' + PRIVACY_RECORDER_FOLDER + '/' + Date.now() + '.wav'
    this.filePath = filePath
    await audioCaptureManager.startRecorder(filePath)
  }

  // 结束录音
  async stopRecorder() {
    this.isRecording = false
    // 结束计时效果
    clearInterval(this.recordingTimerId)
    if (!isEmulator()) {
      // 只有真机可以调用
      const audioInfo = await audioCaptureManager.stopRecorder()
      await privacyRecorderDB.insert({
        id: null,
        filePath: audioInfo.filePath,
        title: '录音文件' + dayjs(audioInfo.date_added).format('YYYY-MM-DD HH:mm:ss'),
        date_added: audioInfo.date_added,
        duration: audioInfo.duration
      })
    } else {
      await privacyRecorderDB.insert({
        id: null,
        filePath: this.filePath,
        title: '模拟器测试文件 ' + dayjs()
          .format('YYYY-MM-DD HH:mm:ss'),
        date_added: Date.now(),
        duration: this.recordingTime * 1000 // 毫秒，进度条播放时更丝滑
      })
    }
    await this.getList()
  }

  // 播放录音
  playRecorder(item: PrivacyRecorderDBInfo) {
    this.activeItem = item
    if (!this.isPlaying) {
      this.isPlaying = true // 开始播放动画
      this.playingTime = 0 // 初始化播放时间的值
      const interval = 20 // 更新间隔，单位：ms
      clearInterval(this.playingTimerId)
      this.playingTimerId = setInterval(() => {
        this.playingTime += interval
        if (this.playingTime > item.duration) {
          this.stopPlayRecorder()
        }
      }, interval)
      audioRenderManager.startRenderer(item.filePath)
    } else {
      this.stopPlayRecorder()
      this.playRecorder(item)
    }
  }

  // 停止播放录音
  stopPlayRecorder() {
    this.isPlaying = false
    clearInterval(this.playingTimerId)
    audioRenderManager.stopRenderer()
  }

  // 删除录音
  async deleteRecord(item: PrivacyRecorderDBInfo) {
    if (item.id) {
      try {
        // 停止播放录音
        this.stopPlayRecorder()
        // 删除数据库中的数据
        await privacyRecorderDB.delete(item.id)
        // 更新列表
        await this.getList()
        // 删除沙箱文件
        fileIo.unlinkSync(item.filePath)
      } catch (err) {
        console.error('myLog:', JSON.stringify(err, null, 2))
      }
    }
  }

  // 打开重命名弹窗
  async openRenameDialog() {
    if (this.activeItem) {
      this.tempInputText = this.activeItem.title
      this.dialogController.open()
    }
  }

  // 重命名录音
  async renameRecord() {
    if (this.activeItem) {
      if (!this.tempInputText.trim()) {
        return promptAction.showToast({ message: '音频名字不能为空' })
      }
      this.activeItem.title = this.tempInputText
      await privacyRecorderDB.update(this.activeItem)
      this.getList()
    }
  }

  @Builder
  NavigationMenus() {
    Row() {
      Text('编辑')
        .fontSize(16)
        .fontColor($r('app.color.font'))
        .onClick(() => {

        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  @Builder
  ListItemSwipeActionEnd(item: PrivacyRecorderDBInfo) {
    Row() {
      Button("重命名")
        .type(ButtonType.Normal)
        .height('100%')
        .aspectRatio(1)
        .backgroundColor('#CECFCF')
        .onClick(() => {
          // TODO：打开录音重命名弹窗
          this.openRenameDialog()
        })
      Button("删除")
        .type(ButtonType.Normal)
        .height('100%')
        .aspectRatio(1)
        .backgroundColor('#FF5E5D')
        .onClick(() => {
          // TODO：删除录音
          this.deleteRecord(item)
        })
    }
    .height('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.list.length) {
            List() {
              ListItemGroup() {
                ForEach(this.list, (item: PrivacyRecorderDBInfo) => {
                  ListItem() {
                    Row({ space: 20 }) {
                      Column({ space: 10 }) {
                        Text(item.title)
                          .fontSize(16)
                          .fontColor($r('app.color.font2'))
                        // 录音进度条
                        if (this.activeItem?.id === item.id && this.isPlaying) {
                          Row({ space: 5 }) {
                            Text(dayjs(this.playingTime)
                              .format('mm:ss'))
                              .fontSize(12)
                              .fontColor($r('app.color.font_sub'))
                            Progress({
                              value: this.playingTime,
                              total: item.duration,
                            })
                          }
                          .padding({ right: 20 })
                        } else {
                          Text(dayjs(item.date_added)
                            .format('YYYY年MM月DD日 HH:mm:ss'))
                            .fontSize(12)
                            .fontColor($r('app.color.font_sub'))
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Column() {
                        Image(
                          this.activeItem?.id === item.id && this.isPlaying ?
                          $r('sys.media.ohos_ic_public_pause') :
                          $r("app.media.ic_public_play")
                        )
                          .width(22)
                          .aspectRatio(1)
                          .fillColor('#A6B6C4')
                        Text(dayjs.duration(item.duration)
                          .format('mm:ss'))
                          .fontSize(12)
                          .fontColor('#A6B6C4')
                          .lineHeight(25)
                      }
                      .justifyContent(FlexAlign.Center)
                      .height('100%')
                      .onClick(() => {
                        // TODO：播放音频
                        this.playRecorder(item)
                      })
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .padding({ left: 15, right: 15 })
                  }
                  .height(72)
                  .transition({ type: TransitionType.Delete, opacity: 0 })
                  .swipeAction({
                    end: {
                      builder: this.ListItemSwipeActionEnd(item),
                      onStateChange: (state) => {
                        if (state === SwipeActionState.EXPANDED) {
                          // 保存当前滑动的数据
                          this.activeItem = item
                        }
                      }
                    },
                    edgeEffect: SwipeEdgeEffect.None,
                  })
                })
              }
              .padding({ bottom: 126 })
              .divider({
                strokeWidth: 1,
                color: $r('app.color.border'),
                startMargin: 15,
                endMargin: 15
              })
            }
            // 每行之间的分界线
            .width('100%')
            .height('100%')
          } else {
            EmptyTipsComp({ title: '您还没有任何隐私录音\n点击下面的按钮开始创建' })
          }
        }
        .height('100%')

        // 录音按钮
        Column() {
          Image($r('app.media.ic_circle_recorder'))
            .width(56)
            .aspectRatio(1)
            .onClick(() => {
              // TODO：开始录音
              this.startRecorder()
            })
        }
        .width('100%')
        .height(126)
        .justifyContent(FlexAlign.Center)
        .padding({ left: 15, right: 15 })

        // 停止录音
        Column({ space: 15 }) {
          Row({ space: 12 }) {
            Row() {
              ForEach(Array.from({ length: 12 }), () => {
                Column()
                  .width(5)
                  .height(16)
                  .backgroundColor('#80ffffff')
                  .borderRadius(5 / 2)
              })
            }
            .width(110)
            .justifyContent(FlexAlign.SpaceBetween)

            // 图标
            Image($r('app.media.ic_recorder_fill'))
              .height('100%')

            Row() {
              ForEach(Array.from({ length: 12 }), () => {
                Column()
                  .width(5)
                  .height(16)
                  .backgroundColor('#80ffffff')
                  .borderRadius(5 / 2)
              })
            }
            .width(110)
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(58)
          .margin({ top: 40 })

          Text(
            dayjs.duration(this.recordingTime, 'seconds')
              .format(this.recordingTime > 60 * 60 ? 'HH:mm:ss' : 'mm:ss')
          )
            .fontSize(18)
            .lineHeight(25)
            .fontWeight(700)
            .fontColor($r('app.color.white'))

          Row() {
            Button('停止录音')
              .type(ButtonType.Normal)
              .width('100%')
              .backgroundColor($r('app.color.brand'))
              .border({ width: 1, color: $r('app.color.white') })
              .borderRadius(10)
              .onClick(() => {
                // TODO：停止录音
                this.stopRecorder()
              })
          }
          .padding({ left: 15, right: 15 })
        }
        .width('101%')
        .height(222)
        .backgroundImage('/common/images/RecorderAddPage_bg_bottom.png')
        .backgroundImageSize(ImageSize.Cover)
        .visibility(this.isRecording ? Visibility.Visible : Visibility.None)
      }
      .height('100%')
    }
    .title('录音')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .menus(this.NavigationMenus)
    .linearGradient({
      angle: 180,
      colors: this.isRecording ? [[$r('app.color.white'), 0.95], [$r('app.color.brand'), 0.95]] :
        [[$r('app.color.white'), 0], [$r('app.color.white'), 1]]
    })
  }
}