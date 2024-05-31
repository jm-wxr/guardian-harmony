import { relationalStore, ValuesBucket } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'

// 隐私笔记
export interface PrivacyNoteDBInfo extends ValuesBucket {
  id: number | null
  title: string
  content: string
  date_added: number
}

const noteSqlCreate = `
  CREATE TABLE IF NOT EXISTS PRIVACY_NOTE (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    date_added INTEGER NOT NULL
  )`
const pushNoteData = (list: PrivacyNoteDBInfo[], resultSet: relationalStore.ResultSet) => {
  list.push({
    id: resultSet.getLong(0),
    title: resultSet.getString(1),
    content: resultSet.getString(2),
    date_added: resultSet.getLong(3)
  })
}

// 隐私录音的字段
export interface PrivacyRecorderDBInfo extends ValuesBucket {
  id: number | null // 新增时 id 为 null ，自动生成自增 id
  filePath: string
  title: string
  date_added: number
  duration: number
}

const recorderSqlCreate =
  `CREATE TABLE IF NOT EXISTS PRIVACY_RECORDER (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filePath TEXT,
    title TEXT,
    date_added INTEGER,
    duration INTEGER
  )`
const pushRecorderData = (list: PrivacyRecorderDBInfo[], resultSet: relationalStore.ResultSet) => {
  list.push({
    id: resultSet.getLong(resultSet.getColumnIndex('id')),
    filePath: resultSet.getString(resultSet.getColumnIndex('filePath')),
    title: resultSet.getString(resultSet.getColumnIndex('title')),
    date_added: resultSet.getLong(resultSet.getColumnIndex('date_added')),
    duration: resultSet.getLong(resultSet.getColumnIndex('duration')),
  })
}

class PrivacyDB <T extends ValuesBucket> {
  private store: relationalStore.RdbStore | null = null // 数据库实例
  private tableName: string // 表名
  private sqlCreate: string // sql 创建语句
  private pushData: (list: T[], resultSet: relationalStore.ResultSet) => void

  // 构造函数
  constructor(tableName: string, sqlCreate: string,
    pushData: (list: T[], resultSet: relationalStore.ResultSet) => void) {
    this.tableName = tableName
    this.sqlCreate = sqlCreate
    this.pushData = pushData
  }

  // 获取(创建)数据库
  async getStoreInstance() {
    try {
      if (this.store) {
        return this.store
      }
      const store = await relationalStore.getRdbStore(getContext(), {
        name: this.tableName + '.db', // 数据库文件名
        securityLevel: relationalStore.SecurityLevel.S1 // 数据库安全级别
      })
      await store.executeSql(this.sqlCreate)
      this.store = store
      return this.store
    } catch (err) {
      promptAction.showToast({ message: `获取数据库失败，err：${err || ''}` })
      return Promise.reject(err)
    }
  }

  // 删除数据库
  async deleteStore() {
    try {
      await relationalStore.deleteRdbStore(getContext(), this.tableName + '.db')
      this.store = null
    } catch {
      promptAction.showToast({ message: '删除数据库失败' })
    }
  }

  // 新增数据
  async insert(item: T) {
    const store = await this.getStoreInstance()
    const rowId = await store.insert(this.tableName, item)
    return rowId > 0 ? Promise.resolve(rowId) : Promise.reject('insert error')
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
    const list: T[] = []
    // 遍历结果集
    while (resultSet.goToNextRow()) {
      // 将数据追加到数组
      this.pushData(list, resultSet)
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
  async update(item: T) {
    if (!item.id) {
      return Promise.reject('id error')
    }
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('id', item.id)
    const affectedRows = await store.update(item, predicates)
    return affectedRows ? Promise.resolve(affectedRows) : Promise.reject('update error')
  }
}


export const privacyNoteDB = new PrivacyDB<PrivacyNoteDBInfo>('PRIVACY_NOTE', noteSqlCreate, pushNoteData)

export const privacyRecorderDB =
  new PrivacyDB<PrivacyRecorderDBInfo>('PRIVACY_RECORDER', recorderSqlCreate, pushRecorderData)