// 页面参数
import { common } from '@kit.AbilityKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { promptAction, router } from '@kit.ArkUI'
import { systemShare } from '@kit.ShareKit'
import { privacyNoteDB, PrivacyNoteDBInfo } from '../../../manager'

interface RouterParams {
  id?: number
}

@Entry
@Component
struct NoteDetailPage {
  // 标题
  @State title: string = ''
  // 内容
  @State content: string = ''
  // 页面参数
  @State routerParams: RouterParams = {}
  @State list: PrivacyNoteDBInfo[] = []

  async aboutToAppear() {
    const params = router.getParams() as RouterParams
    // 如果有id（修改笔记）
    if (params?.id) {
      this.routerParams = params
      // 获取笔记详情
      await this.getData()
    }
  }

  // 新增(修改)笔记
  async onSubmit() {
    const item: PrivacyNoteDBInfo = {
      id: null,
      title: this.title,
      content: this.content,
      date_added: Date.now()
    }
    try {
      if (this.routerParams.id) {
        // 有id(修改笔记)
        item.id = this.routerParams.id
        await privacyNoteDB.update(item)
      } else {
        // 没有id(新增笔记)
        await privacyNoteDB.insert(item)
      }
      promptAction.showToast({ message: `笔记${this.routerParams.id ? '修改' : '添加'}成功` })
      router.back()
    } catch (err) {
      AlertDialog.show({ message: err })
    }
  }

  // 返回页面按钮按下
  onBackPress(): boolean | void {
    // 如果有标题
    if (this.title.trim().length > 0) {
      promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '您输入的内容没有保存，是否放弃',
        buttons: [
          { text: '放弃', color: '#999' },
          { text: '继续编辑', color: $r('sys.color.ohos_id_color_primary') }
        ]
      }).then(res => {
        if (res.index === 0) {
          router.back()
        }
      })
      return true
    } else {
      return false
    }
  }

  // 获取笔记详情
  async getData() {
    const list = await privacyNoteDB.query(this.routerParams.id)
    const note = list[0]
    if (note) {
      this.title = note.title
      this.content = note.content
    }
  }

  // 删除笔记
  async deleteData() {
    if (this.routerParams.id) {
      const res = await promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '确定删除该笔记吗？',
        buttons: [
          { text: '取消', color: $r('sys.color.ohos_id_color_primary') },
          { text: '确定', color: '#f00' }
        ]
      })
      if (res.index === 1) {
        await privacyNoteDB.delete(this.routerParams.id)
        promptAction.showToast({ message: '删除成功' })
        router.back()
      }
    }
  }

  // 分享笔记
  shareData() {
    try {
      const data = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
        title: this.title,
        content: this.content
      })
      const controller = new systemShare.ShareController(data)
      controller.show(getContext() as common.UIAbilityContext, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE
      })
    } catch (err) {
      promptAction.showToast({ message: '模拟器暂不支持分享' })
    }
  }

  @Builder
  NavigationMenus() {
    Row() {
      Text('保存')
        .fontSize(16)
        .fontColor(this.title.trim() !== '' ? $r('app.color.font') : $r('app.color.font_sub'))
        .enabled(this.title.trim() !== '')
        .onClick(async () => {
          // TODO：保存/新增
          await this.onSubmit()
        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column({ space: 10 }) {
          Text('标题')
            .fontSize(14)
            .fontColor($r('app.color.font2'))
            .width('100%')
          TextInput({ placeholder: '请输入笔记标题', text: this.title })
            .backgroundColor($r('app.color.white'))
            .border({ width: 1, color: $r('app.color.border'), radius: 6 })
            .padding({ left: 10 })
            .onChange((text) => {
              this.title = text
            })
            .onSubmit(async () => {
              // TODO：提交表单(保存/新增)
              await this.onSubmit()
            })
          Text('内容')
            .fontSize(14)
            .fontColor($r('app.color.font2'))
            .width('100%')
          TextArea({ placeholder: '请输入笔记内容', text: this.content })
            .backgroundColor($r('app.color.white'))
            .border({ width: 1, color: $r('app.color.border'), radius: 6 })
            .layoutWeight(1)
            .padding(10)
            .onChange((text) => {
              this.content = text
            })
        }
        .padding({ bottom: 160 })

        if (this.routerParams.id) {
          // 底部按钮
          Row({ space: 10 }) {
            Button('删除')
              .type(ButtonType.Normal)
              .backgroundColor('#FF5E5D')
              .borderRadius(10)
              .layoutWeight(1)
              .onClick(() => {
                // TODO：删除
                this.deleteData()
              })
            Button('分享')
              .type(ButtonType.Normal)
              .backgroundColor($r('app.color.brand'))
              .borderRadius(10)
              .layoutWeight(1)
              .onClick(() => {
                // TODO：分享
                this.shareData()
              })
          }
          .padding({ bottom: 80 })
        }
      }
      .padding({ left: 15, right: 15, top: 20 })
    }
    .title('笔记')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .menus(this.NavigationMenus())
  }
}