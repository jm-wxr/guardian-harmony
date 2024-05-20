import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';

class PermissionManager {
  // 检查是否授权
  checkPermissions(permissions: Permissions[]) {
    // 程序访问控制管理
    const atManager = abilityAccessCtrl.createAtManager()
    // 获取 bundle (应用包)信息
    const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    // 应用唯一标识
    const tokenID = bundleInfo.appInfo.accessTokenId
    // 检测权限
    const grantStatus = permissions.map(item => atManager.checkAccessTokenSync(tokenID, item))
    // 返回授权结果
    return grantStatus.every(value => value === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
  }

  // 动态申请授权（首次弹窗申请）
  async requestPermissions(permissions: Permissions[]) {
    // 程序访问控制管理
    const atManager = abilityAccessCtrl.createAtManager()
    // 动态的向用户申请权限
    const result = await atManager.requestPermissionsFromUser(getContext(), permissions)
    // 请求权限的结果
    const isAuth = result.authResults.every(value => value === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
    // 返回授权状态
    return isAuth ? Promise.resolve(true) : Promise.reject(false)
  }

  // 打开系统设置的权限管理页（处理授权结果）
  openPermissionSettingsPage() {
    // 获取上下文
    const context = getContext() as common.UIAbilityContext
    // 获取包信息
    const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    // 打开系统设置页
    context.startAbility({
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: {
        // 按照包名打开对应设置页
        pushParams: bundleInfo.name
      }
    })
  }
}

// 导出 Manager
export const permissionManager = new PermissionManager()