import { promptAction, router } from '@kit.ArkUI'
import { vibrator } from '@kit.SensorServiceKit'
import { PRIVACY_SETTINGS, PrivacySettings } from '../../../common/constants'
import { encryptMD5 } from '../../../common/utils'

interface RouterParams {
  isForgetPassword?: boolean
}

@Entry
@Component
struct AuthPatternLockSettingsPage {
  // 获取隐私空间设置
  @StorageLink(PRIVACY_SETTINGS) privacySettings: PrivacySettings = {}
  // 第一次输入的密码
  @State firstPassword: number[] = []
  // 错误提示语
  @State errorMessage: string = ''
  // 路由参数
  @State routerParams: RouterParams = {}
  // 控制器
  private patternLockController: PatternLockController = new PatternLockController()

  onPageShow(): void {
    this.firstPassword = []
  }

  // 设置错误提示
  setErrorMessage(message: string) {
    this.errorMessage = message
    this.patternLockController.setChallengeResult(PatternLockChallengeResult.WRONG)
  }

  // 清除错误提示
  clearErrorMessage() {
    this.errorMessage = ''
    this.patternLockController.setChallengeResult(PatternLockChallengeResult.CORRECT)
  }

  // 手势密码输入完成
  onPatternComplete(input: number[]) {
    // 校验长度，如果小于4，提示重新输入
    if (input.length < 4) {
      this.setErrorMessage('手势密码长度不能小于4位，请重新输入')
    } else {
      // 长度符合规范
      this.clearErrorMessage()
      if (this.firstPassword.length === 0) {
        // 首次输入
        this.firstPassword = input
      } else {
        // 非首次输入，判断两次密码是否相同
        if (this.firstPassword.toString() === input.toString()) {
          // 如果相同，跳转页面
          if (!this.privacySettings.patternPassword) {
            // 如果时设置手势密码，去设置密保问题
            promptAction.showToast({ message: '设置成功' })
            router.pushUrl({
              url: 'pages/Privacy/Auth/AuthProtectPage',
              params: { patternPassword: this.firstPassword }
            })
          } else {
            // 如果是修改密码，不设置密保问题
            promptAction.showToast({ message: '修改成功' })
            this.privacySettings.patternPassword = encryptMD5(input.toString())
            router.replaceUrl({ url: 'pages/Privacy/PrivacyIndexPage' })
          }
        } else {
          // 如果不同，重置第一次输入，并提示
          this.firstPassword = []
          this.setErrorMessage('两次手势密码不一致，请重新输入')
        }
      }
    }
  }

  build() {
    Navigation() {
      Column({ space: 20 }) {
        Column({ space: 10 }) {
          // 请输入密码
          Text(this.firstPassword.length === 0 ? '设置手势密码' : '再次确认手势密码')
            .fontSize(16)
            .fontColor($r('app.color.font'))
          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor($r('app.color.danger'))
          } else {
            Text(this.firstPassword.length === 0 ? '请绘制手势密码，至少链接4个点' : '请再次输入确认手势密码')
              .fontSize(12)
              .fontColor($r('app.color.font_sub'))
          }
        }

        PatternLock(this.patternLockController)
          .sideLength(320)// 宽高
          .circleRadius(12)// 圆点半径
          .pathStrokeWidth(10)// 线宽度
          .autoReset(true)// 再次输入时重置
          .regularColor('#d9d9d9')// 未选中圆点色
          .activeColor('#800a59f7')// 经过圆点色
          .selectedColor(this.errorMessage ? '#ffff5e5d' : '#ff0a59f7')// 选中圆点色
          .pathColor(this.errorMessage ? '#ccff5e5d' : '#cc0a59f7')// 线颜色
          .onDotConnect(() => {
            // 按下首点时清除错误消息
            this.clearErrorMessage()
            vibrator.startVibration(
              { type: 'preset', count: 1, effectId: 'haptic.clock.timer' },
              { id: 1, usage: 'touch' }
            )
          })
          .onPatternComplete((input: number[]) => {
            // TODO：密码输入结束时触发该回调
            this.onPatternComplete(input)
          })
      }
      .padding({ top: 140 })
    }
    .title('隐私空间')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}