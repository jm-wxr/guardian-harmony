import { FaultLogger } from '@kit.PerformanceAnalysisKit'

@Entry
@Component
struct FaultLogTestPage {
  async getLogs() {
    const list = await FaultLogger.query(FaultLogger.FaultType.JS_CRASH)
    AlertDialog.show({ message: JSON.stringify(list, null, 2) })
  }

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 10 }) {
          Button('抛出错误')
            .onClick(() => {
              throw new Error('my error')
            })
          Button('获取故障日志')
            .onClick(() => {
              this.getLogs()
            })
        }
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
    }
    .title('故障日志测试')
    .titleMode(NavigationTitleMode.Mini)
  }
}