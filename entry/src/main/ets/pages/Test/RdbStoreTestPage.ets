import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';

// 隐私笔记
interface PrivacyNoteDBInfo extends ValuesBucket {
  id: number | null
  title: string
  content: string
  date_added: number
}

@Entry
@Component
struct RdbStoreTestPage {
  private tableName = 'PRIVACY_NOTE'
  private sqlCreate = `
  CREATE TABLE IF NOT EXISTS ${this.tableName} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    date_added INTEGER NOT NULL
  )`

  // 获取数据库
  async getStoreInstance() {
    try {
      const store = await relationalStore.getRdbStore(getContext(), {
        name: this.tableName + '.db', // 数据库文件名
        securityLevel: relationalStore.SecurityLevel.S1 // 数据库安全级别
      })
      return store
    } catch (err) {
      promptAction.showToast({ message: `获取失败，err：${err || ''}` })
      return Promise.reject(err)
    }
  }

  // 创建数据库
  async createStore() {
    try {
      const store = await relationalStore.getRdbStore(getContext(), {
        name: this.tableName + '.db', // 数据库文件名
        securityLevel: relationalStore.SecurityLevel.S1 // 数据库安全级别
      })
      await store.executeSql(this.sqlCreate)
      return store
    } catch (err) {
      promptAction.showToast({ message: `创建失败，err：${err || ''}` })
      return Promise.reject(err)
    }
  }

  // 删除数据库
  async deleteStore() {
    try {
      await relationalStore.deleteRdbStore(getContext(), this.tableName + '.db')
    } catch {
      promptAction.showToast({ message: '删除失败' })
    }
  }

  // 新增数据
  async insertData(item: PrivacyNoteDBInfo) {
    const store = await this.getStoreInstance()
    const rowId = await store.insert(this.tableName, item)
    if (rowId > 0) {
      return Promise.resolve(rowId)
    } else {
      return Promise.reject('insert error')
    }
  }

  // 查询数据总数
  async queryCount() {
    const store = await this.getStoreInstance()
    // 谓词
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    // 查询
    const resultSet = await store?.query(predicates)
    return resultSet.rowCount > 0 ? resultSet.rowCount : 0
  }

  // 根据id查询数据，不传id查询所有
  async query(id?: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    // 根据id进行降序排序
    predicates.orderByDesc('id')
    // 如果传入了id
    if (id) {
      predicates.equalTo('id', id)
    }
    const resultSet = await store.query(predicates)
    const list: PrivacyNoteDBInfo[] = []
    // 遍历结果集
    while (resultSet.goToNextRow()) {
      // 将数据追加到数组
      list.push({
        id: resultSet.getLong(0),
        title: resultSet.getString(1),
        content: resultSet.getString(2),
        date_added: resultSet.getLong(3)
      })
    }
    // 释放结果集的内存空间
    resultSet.close()
    return list
  }

  // 根据id删除数据
  async delete(id: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('id', id)
    // 返回受影响的行数
    const affectedRows = await store.delete(predicates)
    return affectedRows ? Promise.resolve(affectedRows) : Promise.reject('delete error')
  }

  // 更新数据
  async update(item: PrivacyNoteDBInfo) {
    if (!item.id) {
      return Promise.reject('id error')
    }
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('id', item.id)
    const affectedRows = await store.update(item, predicates)
    return affectedRows ? Promise.resolve(affectedRows) : Promise.reject('update error')
  }

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 10 }) {
          Button('创建数据库文件')
            .onClick(async () => {
              await this.createStore()
              promptAction.showToast({ message: '创建成功' })
            })
          Button('删除数据库文件')
            .onClick(async () => {
              await this.deleteStore()
              promptAction.showToast({ message: '删除成功' })
            })
          Button('新增数据')
            .onClick(async () => {
              const data: PrivacyNoteDBInfo = {
                id: null,
                title: '关键的问题',
                content: '111',
                date_added: Date.now()
              }
              await this.insertData(data)
              promptAction.showToast({ message: '新增数据成功' })
            })
          Button('查询数据库总数')
            .onClick(async () => {
              const count = await this.queryCount()
              AlertDialog.show({ message: count.toString() })
            })
          Button('获取所有数据')
            .onClick(async () => {
              const list = await this.query()
              AlertDialog.show({ message: JSON.stringify(list, null, 2) })
            })
          Button('获取id = 2的数据')
            .onClick(async () => {
              const list = await this.query(2)
              AlertDialog.show({ message: JSON.stringify(list, null, 2) })
            })
          Button('删除id = 3的数据')
            .onClick(async () => {
              const affectedRows = await this.delete(3)
              promptAction.showToast({ message: '受影响的行数：' + affectedRows })
            })
          Button('更新id = 2的数据')
            .onClick(async () => {
              const item: PrivacyNoteDBInfo = {
                id: 2,
                title: '更新后的标题',
                content: '更新后的内容',
                date_added: Date.now()
              }
              const affectedRows = await this.update(item)
              promptAction.showToast({ message: '受影响的行数：' + affectedRows })
            })
        }
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
    }
    .title('关系型数据库测试')
    .titleMode(NavigationTitleMode.Mini)
  }
}