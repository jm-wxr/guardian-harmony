import { router } from '@kit.ArkUI'

@Entry
@Component
struct CountdownPage {
  @State count: number = 0
  private intervalID: number = -1

  aboutToAppear() {
    this.startCounter()
  }

  aboutToDisappear() {
    this.stopCounter()
  }

  // 开启倒计时
  startCounter() {
    // 初始化倒计时的值
    this.count = 5
    // 开启定时器
    this.intervalID = setInterval(() => {
      // 自减
      this.count--
      // 倒计时结束
      if (this.count <= 0) {
        // 停止定时器
        this.stopCounter()
        // 跳转页面
        router.replaceUrl({ url: 'pages/Guard/Alarm/GuardAlarmPage' })
      }
    }, 1000)
  }

  // 结束倒计时
  stopCounter() {
    clearInterval(this.intervalID)
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Row() {
            Text(this.count.toString())
              .fontSize(100)
              .fontWeight(500)
              .fontColor($r('app.color.danger'))
          }
          .width(150)
          .aspectRatio(1)
          .justifyContent(FlexAlign.Center)
          .border({ width: 5, radius: 150 / 2, color: '#ffc4c5' })
          .margin({ top: -300 })

          Text('5秒倒计时结束后，虚拟警报器开启，闪光灯闪烁，并以最大音量鸣笛')
            .fontSize(14)
            .lineHeight(20)
            .padding({ left: 25, right: 25 })
            .textAlign(TextAlign.Center)
            .margin({ top: 30 })
        }
        .justifyContent(FlexAlign.Center)
        .height('100%')

        Column({ space: 20 }) {
          Button('立即开启')
            .backgroundColor($r('app.color.danger'))
            .fontColor($r('app.color.white'))
            .type(ButtonType.Normal)
            .borderRadius(10)
            .width('100%')
            .onClick(() => {
              router.replaceUrl({ url: 'pages/Guard/Alarm/GuardAlarmPage' })
            })

          Button('退出')
            .backgroundColor('#17FF5E5D')
            .fontColor($r('app.color.danger'))
            .width('100%')
            .type(ButtonType.Normal)
            .borderRadius(10)
            .onClick(() => {
              router.back()
            })
        }
        .padding({ left: 20, right: 20, bottom: 30 })
      }
      .width('100%')
      .height('100%')
    }
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .linearGradient({
      direction: 180,
      colors: [['#ffd8d6', 0], ['#ffffff', 1]]
    })
  }
}