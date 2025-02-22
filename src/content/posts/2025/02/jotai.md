---
title: Jotaiなんもわからん
published: 2025-02-22
description: Reactにおける状態管理がわかりません
category: Programming
tags: [Vite, React, Jotai]
---

## 背景

State管理ライブラリであるJotaiを使っているのですが、なんもわからんので将来わかることを見越してメモしておきます。

### `Async`

#### `atom`

これはユーザーのデータなどを固定値のURLを呼び出してデータを取ってくるときに使えます。

```ts
const userAtom = atom((get) => {
  const response = await fetch(new URL(...).href)
  return await response.json()
})
```

これは`fetch`中には`Suspense`の`fallback`のコンポーネントが呼び出されるのでユーザーに「現在通信中である」ということを簡単に通知できます。

よって、`Suspense`を利用する必要があります。

```tsx
const View: React.FC = () => {
  const user: View = useAtomValue(userAtom) return (
    <p>{user.name}</p>
  )
}
```

で、気になるのはもしユーザー情報を更新したい場合にはどうするかということですが単純な非同期atomには`set`がないのでこれは実現できません。

要するに、一回値が入るとキャッシュが利用されてしまうので二度と更新できません。

#### `loadable`

非同期atomの使い方の一つで`Suspense`や`Error Boundary`を使いたくないときに使います。

基本的には`Suspense`や`Error Boundary`を使うと思うのでこちらは解説しません。

#### `atomWithObservable`

`rxjs`と組み合わせる感じです。

```ts
const counterAtom = atomWithObservable(
  () => interval(1000).pipe(map((value) => value * 2))
);
```

ちょっと調べてみた感じ`value`は0から順番に数値が返ってくるみたいですね。

```tsx
const View: React.FC = () => {
  const [counter] = useAtom(counterAtom);
  return (
    <>
      <ModalDialog>
        <DialogTitle>Asnyc</DialogTitle>
        <DialogContent>
          <button type="button">{counter}</button>
        </DialogContent>
      </ModalDialog>
    </>
  );
};
```

なのでこう書くと0, 2, 4, 8という感じで一秒ごとにデータが更新されます。

#### `unwrap`

非同期atomの使い方の一つで`Suspense`や`Error Boundary`を使いたくないときに使います。

基本的には`Suspense`や`Error Boundary`を使うと思うのでこちらは解説しません。

#### `atomWithRefresh`

```ts
const userAtom = atomWithRefresh((get) => {
  const response = await fetch(new URL(...).href)
  return await response.json()
})
```

これは非同期atomに対してリフレッシュ機能を提供します。

```tsx
const View: React.FC = () => {
  const [user, refresh] = useAtom(userAtom)
  return (
    <button onClick={() => refresh()}>{user.name}</button>
  )
}
```

この場合だとボタンを押したときに`userAtom`の再評価が行われ、便利なわけですね。

公式ドキュメントだと`onClick={refresh}`だけで更新がかかるような書き方がされていますが、Vite+Reactの環境では動きませんでした。

### `Lazy`

遅延評価をするatomです。

似たような仕組みがSwiftにもあるので多分同じ感じだと思います。

#### `atomWithLazy`

ですがググっても全然出てこない上に公式ドキュメントも良くわからないのでスキップします。

### `Reset`

#### `atomWithReset`

初期値を再代入するためのatomです。

`RESET`という特別な値を入れることで初期化できます。

これもドキュメントが良くわからないのでまだ使えていません。

#### `atomWithDefault`

再代入かつ初期化できるatomです。

```ts
const count1Atom = atom(1);
const count2Atom = atomWithDefault((get) => get(count1Atom) * 2);
```

例えばこう書いたとすると初期値はそれぞれ1と2になります。

ただ、`count2Atom`の初期値が`count1Atom`の二倍にしたいのであれば、

```ts
const count1Atom = atom(1);
const count2Atom = atom((get) => get(count1Atom) * 2);
```

こう書いても同じ結果が得られます。ただし、これはReadOnlyなatomなので再代入ができません。

```tsx
const View: React.FC = () => {
  const [count1, setCount1] = useAtom(count1Atom);
  const [count2, setCount2] = useAtom(count2Atom);

  return (
    <div>
      count1: {count1}, count2: {count2}
    </div>
    <button type='button' onClick={() => setCount1((c) => c + 1)}>
      increment count1
    </button>
    <button type='button' onClick={() => setCount2((c) => c + 1)}>
      increment count2
    </button>
    <button type='button' onClick={() => setCount2(RESET)}>
      Reset with RESET const
    </button>
  )
}
```

こう書くと`count2`を変更しない間は初期値が利用されるので`count1`を増加させるとその二倍の値が`count2`として設定されます。

そこから`count2`だけを増加させると`count1`を増やしてもこれら二つは同期されなくなりますが、リセットを実行すると`count2`は`count1`の値の二倍(初期値)に戻ります。

```ts
const [count2, setCount2] = useAtom(count2Atom);
const resetCount2 = useResetAtom(count2Atom);
```

という風に定義すれば`resetCount2()`と`setCount2(RESET)`は同じ効果を持ちます。

### `Storage`

値をLocalStorageなどに保存して永続化することができます。

主に設定項目などを保存しておくと良いと思います。

LocalStorageは暗号化されていないのでクレデンシャルなどの情報は保存してはいけません。

```ts
const darkModeAtom = atomWithStorage("theme", false);
```

キー名を指定して値を保存します。このとき、デフォルトだと`JSON.stringify()`が利用されるのでJSONに変換できない値は保存できません。保存したい場合には自分で保存用のメソッドを定義する必要があります。

また、何も指定しない場合にはLocalStorageから読み込む前に第一引数(この場合はfalse)で初期化されます。

```tsx
const View: React.FC = () => {
  const [darkMode, setDarkMode] = useAtom(darkModeAtom);
  return (
    <button type="button" onClick={() => setDarkMode(!darkMode)}>
      {darkMode ? "Dark Mode" : "Light Mode"}
    </button>
  )
}
```

よってこのようにコンポーネントを定義した場合、どのような値で保存されていたとしても最初に`Light Mode`と表示されてしまいます。

これが意図した挙動と違うのであれば、

```ts
const darkModeAtom = atomWithStorage("theme", false, undefined, {
  getOnInit: true,
});
```

このように第三引数のオプションに`getOnInit`で`true`を指定すれば値が保存されていれば初期値の代わりにLocalStorageから読み込んだ値で初期化します。

こっちの方が挙動として自然だと思うので、こっちを使ったほうがいいと思います。

### `Family`

#### `atomFamily`

`atomFamily`は引数を受け取ってatomを返すメソッドを提供します。

```ts
type User = {
  name: string
  age: number
}
const usersAtomFamily = atomFamily(
  ({ name, age}: User) => atom({ name: name, age: age}),
  (a,b) => a.name === b.name
)
```

これは無名のatomを生成し、Jotaiの内部状態として保存します。よって、外部からatomの管理をしなくていいというのが便利です。

```ts
const usersAtom = atom<User[]>([])
```

じゃあこれと変わらないんじゃないかと思うかもしれませんが、`atomFamily`の場合はそれぞれ個別のatomを保存しているため要素の一つの値が変化したときにその値に関するコンポーネントだけ再レンダリングが走ります。

それに対して要素の配列自体をatomに入れた場合はどれか一つの値が変わると全ての要素に関するコンポーネントが再レンダリングされるため、例えば要素が100あるatomが変化したとき前者では変化したatomの分だけしかコンポーネントが変化しませんが、後者の場合は全てのコンポーネントが再描画されるため動作が重くなるなどの懸念が発生します。

よって、配列の一部が変化する可能性がある変数をatomとして管理する場合には`atomFamily`を利用したほうが効率が良いことがあります。

唯一困る点としては`atomFamily`は保存している内部状態全ての値を一度に取得するプロパティがありません。

よって、もし全件をループしてコンポーネントとして表示したい場合には保存しているatomのユニークなキーを別のatomとして保存しておく必要があります。

### `Callback`

```ts
const countAtom = atom<number>(0)
```

まずは適当に数値をカウントするためのatomを作成します。

```tsx
const Counter: React.FC = () => {
  const [count, setCount] = useAtom(countAtom)
  return (
    <>
      <div>ATOM: {count}</div>
      <button type="button" onClick={() => setCount((c) => c + 1)}>
        +1
      </button>
    </>
  )
}

const View: React.FC = () => {
  const [count, setCount] = useState(0)
    const readCount = useAtomCallback(
    useCallback((get) => {
      const current: number = get(countAtom);
      console.log("CURRENT:", current);
      setCount(current);
      return current;
    }, []),
  );

  // readCountが初期化された段階で呼ばれる
  useEffect(() => {
    const timer = setInterval(async () => {
      console.log(readCount());
    }, 1000);
    return () => {
      clearInterval(timer);
    };
  }, [readCount]);

  return (
    <div>CALLBACK: {count}</div>
    <Counter />
  )
}
```

こう書くとボタンを押せばcountAtomの状態が変わってどんどん値が変わるのは当たり前なのですが、このとき`useAtomCallback`はどういう挙動をするのかが気になります。

で、どうなっているかというと一秒に一回`readCount`が呼び出されてその時にcountAtomの値を取得してその値をcountに代入します。

よって、ボタンを連打していても一秒に一回、countAtomの値とcountの値が同期されるというわけです。

この機能自体は通常のatomを使って、

```tsx
const Monitor: React.FC = () => {
  const [count, setCount] = useState(0);
  const _count = useAtomValue(countAtom);

  useEffect(() => {
    setCount(_count);
  }, [_count]);

  return <div>CALLBACK: {count}</div>;
};
```

こう書けば同期的に実行できるのにわざわざuseAtomCallbackを使うのはLocalStorageやAPI通信などの非同期通信を伴う場合、即座に変更させることができないからですね。

## まとめ

まだまだ途中までしかかけていませんが、これからいろいろJotaiについて調べていこうと思います。
