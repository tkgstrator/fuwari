---
title: Vueのライフサイクルタイミングを理解する
published: 2023-02-20
description: Vue.jsのコンポーネントのライフサイクルへの理解を深めます
category: Tech
tags: [Vue]
---

## Vue.js のライフサイクル

### メソッド一覧

|   メソッド    |           タイミング           |
| :-----------: | :----------------------------: |
|     setup     |              最速              |
| beforeCreate  |      インスタンス初期化時      |
|    created    |     インスタンス利用可能時     |
|  beforeMount  |   コンポーネントマウント直前   |
|    mounted    |   コンポーネントマウント直後   |
| beforeUpdate  |          DOM 更新直前          |
|    updated    |         DOM 更新完了時         |
| beforeUnmount | コンポーネントアンマウント直前 |
|   unmounted   | コンポーネントアンマウント直後 |
| errorCaptured |      エラーキャプチャー時      |
|   activated   |           DOM 挿入後           |
|  deactivated  |           DOM 削除後           |

個人的によく使うのは`computed`, `mounted`, `setup`なのですが、その中でも`setup`が最速らしいです。

> Composition API の setup() フックは、beforeCreate() を含めた Options API のどんなフックよりも先に呼び出されることに注意してください。

と書いてあるのでとにかく速いのだと思います。
