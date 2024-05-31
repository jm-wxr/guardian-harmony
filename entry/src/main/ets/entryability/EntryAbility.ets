import { Log } from '@abner/log';
import { AbilityConstant, errorManager, UIAbility, Want } from '@kit.AbilityKit';
import { promptAction, router, window } from '@kit.ArkUI';
import { FaultLogger, hilog } from '@kit.PerformanceAnalysisKit';
import { LoginInfoResponse } from '../api';
import { LOGIN_INFO, PRIVACY_SETTINGS, PrivacySettings } from '../common/constants';
import { request } from '../common/utils';

Log.init({
  tag: 'HarmonyOSLog', // 打印的标签
  domain: 0x0000, // 业务领域
  close: false, // 是否关闭打印
  isHilog: true, // 打印类型
  showLogLocation: true, // 是否展示点击的位置
  logSize: 800 // 日志每次输出大小
})

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    // 注册错误观测器。注册后可以捕获到应用产生的js crash，应用崩溃时进程不会退出。
    errorManager.on('error', {
      // 将在js运行时引发用户未捕获的异常时调用。
      async onUnhandledException() {
        const faultLogInfoList = await FaultLogger.query(FaultLogger.FaultType.JS_CRASH)
        // 获取第一条错误日志
        const faultLogInfo = faultLogInfoList[0]
        // 上报错误日志
        await request<object | null, FaultLogger.FaultLogInfo>({
          url: '/log/fault/report/single',
          method: 'POST',
          data: faultLogInfo
        })
        promptAction.showToast({
          message: '程序内部错误，故障日志已自动上报'
        })
      }
    })
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('/pages/Index'.slice(1), (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading thte content.');
      // 初始化持久化存储
      PersistentStorage.persistProp('isHidePrivacy', false)
      PersistentStorage.persistProp<PrivacySettings>(PRIVACY_SETTINGS, {})
      PersistentStorage.persistProp<LoginInfoResponse>(LOGIN_INFO, {})
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // 切后台时，获取当前路由信息
    const routerState = router.getState()
    if (routerState.path.includes('/pages/Privacy'.slice(1))) {
      router.back({
        url: 'pages/Index'
      })
    }
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
