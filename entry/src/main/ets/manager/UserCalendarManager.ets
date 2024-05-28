import { Permissions } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { calendarManager } from '@kit.CalendarKit'
import { permissionManager } from '.'

class UserCalendarManager {
  // 日历权限
  private permissions: Permissions[] = ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR']

  // 申请权限
  async requestPermissions() {
    try {
      await permissionManager.requestPermissions(this.permissions)
    } catch {
      // 未开启时弹窗提示
      const res = await promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '日历清理功能需要获取权限，请在系统设置中打开日历开关',
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

  // 获取默认日历
  async getDefaultCalendar() {
    const calendarMgr = calendarManager.getCalendarManager(getContext())
    return calendarMgr.getCalendar()
  }
}

export const userCalendarManager = new UserCalendarManager()