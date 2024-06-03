import { Permissions } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { contact } from '@kit.ContactsKit'
import { permissionManager } from '.'
import { isEmulator } from '../common/dev'

class ContactManager {
  private permissions: Permissions[] = ['ohos.permission.READ_CONTACTS', 'ohos.permission.WRITE_CONTACTS']

  // 申请授权
  async requestPermissions() {
    try {
      await permissionManager.requestPermissions(this.permissions)
    } catch (err) {
      const res = await promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '通讯录功能需要获取权限，请在系统设置中打开通讯录开关',
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

  // 获取通讯录联系人
  async getContacts(): Promise<contact.Contact[]> {
    // 模拟器返回假数据
    if (isEmulator()) {
      return [
        {
          name: { fullName: '孙悟空', },
          phoneNumbers: [{ phoneNumber: '10086' }],
          key: '1',
          id: 1
        },
        {
          name: { fullName: '唐僧', },
          phoneNumbers: [{ phoneNumber: '10010' }],
          key: '2',
          id: 2
        }
      ]
    }
    return contact.queryContacts(getContext())
  }

  // 获取通讯录群组
  async getGroups() {
    return contact.queryGroups(getContext())
  }
}

export const contactManager = new ContactManager()